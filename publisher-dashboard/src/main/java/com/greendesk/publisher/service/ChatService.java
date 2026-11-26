/*
 * [1] 역할
 *     사장님과 쭌의 대화에 관한 업무 규칙을 실행하는 서비스 클래스다.
 *     컨트롤러가 이 클래스의 메서드를 호출하고, 이 클래스가 Repository(DB)와 FakechatClient(쭌에게 HTTP 전송)를 호출한다.
 *     화면용 컨트롤러(ChatPageController)와 JSON 컨트롤러(ChatApiController)가 같은 메서드를 함께 쓴다.
 *
 * [2] 받는 것 → 내보내는 것 (실제로 실행해서 얻은 값)
 *     send("좋아요, 이대로 진행해 주세요.")
 *       → FakechatClient 가 POST http://127.0.0.1:8787/upload 로 쭌에게 전달
 *       → SQL  insert into chat_message (at,attachment_paths,attachments,channel,direction,team_name,text,unique_key,id) values (?,?,?,?,?,?,?,?,default)
 *       → 돌려주는 값  ChatMessage(id=103, direction=FROM_BOSS, text="좋아요, 이대로 진행해 주세요.", channel="web")
 *     messagesAfter(102)
 *       → SQL  select … from chat_message cm1_0 order by cm1_0.at desc,cm1_0.id desc fetch first ? rows only
 *       → 돌려주는 값  [ChatMessage(id=103)]
 *
 * [3] 앞뒤 파일
 *     api/ChatApiController.java, controller/ChatPageController.java, controller/OfficePageController.java  →  (이 파일)
 *     (이 파일)  →  repository/ChatMessageRepository.java, repository/BookOrderRepository.java, client/FakechatClient.java, service/ScanService.java
 *
 * [4] 메서드 목록
 *     메서드              하는 일                                          부르는 곳                       흐름 번호
 *     send(text)          검사 → 쭌에게 전달 → DB 저장                      ChatApiController.send          흐름 B-③④
 *     order(text)         send + 주문 기록 저장                             ChatPageController.order        흐름 C-③
 *     messagesAfter(n)    대화 기록 파일을 읽어 DB 를 갱신한 뒤 n 번보다 새 메시지   ChatApiController.poll          흐름 B′-③
 *     message(id)         메시지 한 건 (없으면 404 예외)                     ChatApiController.one           흐름 D-③
 *     isLeadOnline()      쭌에게 연결되는지 확인                             ChatApiController.poll
 *     recentOrders()      최근 주문 20건
 *     attachment(id, i)   첨부 파일 경로 (출판사 폴더 밖이면 예외)             ChatPageController.file
 *
 * [5] 먼저 알 용어 (자세한 설명: docs/용어-풀이.md)
 *     @Service, @Transactional, 생성자 주입, 예외(throw), Optional.orElseThrow, List, 람다식
 *
 * [6] 읽는 순서
 *     send() → order() → messagesAfter() → message() → attachment()
 *
 * [7] 다 읽고 확인
 *     - send() 에서 fakechat.send() 가 예외를 발생시키면 chats.save() 는 실행되는가?
 *     - messagesAfter(0) 과 messagesAfter(102) 의 차이는 어느 줄에서 생기는가?
 */
package com.greendesk.publisher.service;

import com.greendesk.publisher.client.FakechatClient;
import com.greendesk.publisher.config.PublisherProperties;
import com.greendesk.publisher.domain.BookOrder;
import com.greendesk.publisher.domain.ChatMessage;
import com.greendesk.publisher.repository.BookOrderRepository;
import com.greendesk.publisher.repository.ChatMessageRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.time.Instant;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;

/**
 * 사장님 ↔ 쭌 대화의 업무 규칙.
 * - 보내기: 검사 → 쭌에게 전달(FakechatClient) → DB 저장
 * - 주문: 보내기 + 주문 기록(BookOrder)
 * - 대화 조회: 쭌의 답장은 대화 기록에 남으므로 먼저 기록을 읽고(ScanService) DB에서 꺼낸다
 * - 첨부 파일: 출판사 폴더 안의 파일만 내준다
 */
// @Service
//   뜻     : 이 클래스가 업무 규칙을 담당하는 객체라는 표시다. 스프링이 프로그램 시작 때 객체를 하나 만들어 두고,
//            생성자에 ChatService 를 받는 클래스(컨트롤러들)에게 그 객체를 넘겨 준다.
//   없으면 : 스프링이 객체를 만들지 않는다. 컨트롤러를 만들 수 없어 프로그램 시작이 실패한다.
@Service
public class ChatService {

    // static final 상수: 객체마다가 아니라 클래스에 하나만 있는 바뀌지 않는 값. 메시지의 최대 글자 수.
    public static final int MAX_LENGTH = 4000;
    /** 대화방을 보는 동안 기록을 다시 읽는 최소 간격 */
    // 2000 밀리초 = 2초. 대화 기록 파일을 다시 읽는 최소 간격이다.
    private static final long FRESHEN_MS = 2000;

    // 아래 다섯 필드는 이 서비스가 일할 때 쓰는 객체들이다. 모두 생성자에서 스프링이 넣어 준다.
    //   fakechat    : 쭌(Claude Code)에게 HTTP 로 메시지를 보낸다.            자료형 FakechatClient
    //   chats       : chat_message 표를 읽고 쓴다.                           자료형 ChatMessageRepository
    //   orders      : book_order 표를 읽고 쓴다.                             자료형 BookOrderRepository
    //   scans       : 대화 기록 파일과 책 폴더를 읽어 DB 에 반영한다.          자료형 ScanService
    //   props       : application.yml 의 publisher.* 설정 값.                자료형 PublisherProperties
    private final FakechatClient fakechat;
    private final ChatMessageRepository chats;
    private final BookOrderRepository orders;
    private final ScanService scans;
    private final PublisherProperties props;

    // 생성자 주입: 스프링이 다섯 객체를 만들어 이 생성자에 넘겨 준다. 우리 코드에서 new ChatService(...) 를 쓰는 곳은 없다.
    public ChatService(FakechatClient fakechat, ChatMessageRepository chats, BookOrderRepository orders,
                       ScanService scans, PublisherProperties props) {
        this.fakechat = fakechat;
        this.chats = chats;
        this.orders = orders;
        this.scans = scans;
        this.props = props;
    }

    // 쭌에게 연결되는지 확인한다. FakechatClient.isOnline() 이 GET http://127.0.0.1:8787/ 을 보내 200 이 오면 true.
    public boolean isLeadOnline() {
        return fakechat.isOnline();
    }

    /**
     * 사장님 말을 쭌에게 보내고 저장한다.
     * @throws IllegalArgumentException 빈 글이거나 너무 길 때
     * @throws com.greendesk.publisher.client.ChannelUnavailableException 쭌이 출근 전일 때
     */
    @Transactional
    // ────────────────────────────────────────────────────────────────────────────
    // [흐름 B-③] 메시지 보내기 — ChatApiController.send() 가 이 메서드를 호출한다
    // ────────────────────────────────────────────────────────────────────────────
    // ▶ 받는 값: text          예) "좋아요, 이대로 진행해 주세요."
    // ▶ 돌려주는 값: 저장된 ChatMessage 엔티티   예) ChatMessage(id=103, text="좋아요, 이대로 진행해 주세요.")
    // ▶ 예외: 빈 글·너무 긴 글 → IllegalArgumentException (400) / 쭌과 연결 안 됨 → ChannelUnavailableException (503)
    //
    // @Transactional (바로 위 줄)
    //   뜻     : 이 메서드 안의 DB 작업을 하나의 트랜잭션(한꺼번에 반영하거나 한꺼번에 취소하는 작업 단위)으로 실행한다.
    //   결과   : 메서드가 정상으로 끝나면 DB 변경이 확정(commit)되고, 예외로 끝나면 이 메서드에서 한 DB 변경이 취소(rollback)된다.
    //   주의   : DB 가 아닌 작업(쭌에게 보낸 HTTP 요청)은 취소되지 않는다.
    public ChatMessage send(String text) {
        // (1) text == null ? "" : text.strip()   조건 ? 참일 때 값 : 거짓일 때 값  (삼항 연산자)
        //     text 가 null 이면 "" 를, 아니면 앞뒤 공백을 지운 글자를 쓴다.
        //     예) text = "  좋아요 " → t = "좋아요"       text = "   " → t = ""       text = null → t = ""
        String t = text == null ? "" : text.strip();
        // t 가 빈 글자("")이면 예외를 발생시키고 이 메서드를 끝낸다. 아래 줄들은 실행되지 않는다.
        //   API 요청이면 @Valid 가 먼저 막으므로 보통 여기까지 오지 않는다. 화면 폼(흐름 C)으로 온 요청은 여기서 막힌다.
        //   없으면: 빈 메시지가 쭌에게 전달되고 DB 에 저장된다.
        if (t.isEmpty()) throw new IllegalArgumentException("보낼 말을 적어 주세요.");
        // 글자 수가 4000 을 넘으면 예외. 예외 문장 = "4000자 이내로 적어 주세요."
        if (t.length() > MAX_LENGTH) throw new IllegalArgumentException(MAX_LENGTH + "자 이내로 적어 주세요.");
        // 이 메시지의 고유 번호(글자)를 만든다.   예) id = "web-1762724793776-a1b2c3"
        // 이 번호로 나중에 쭌의 대화 기록에서 같은 메시지를 찾아 합친다(TranscriptScanner).
        String id = FakechatClient.newMessageId();
        // 쭌에게 메시지를 전달한다. 실제로 보내는 HTTP 요청:
        //   POST http://127.0.0.1:8787/upload
        //   Content-Type: multipart/form-data; boundary=…
        //   (form 값) id = web-1762724793776-a1b2c3,  text = 좋아요, 이대로 진행해 주세요.
        //   → 응답 204 이면 성공.
        // 연결되지 않으면 ChannelUnavailableException 이 발생한다 → 아래 save 는 실행되지 않는다 → ApiExceptionHandler.offline() → 503 [흐름 D-②]
        // 없으면: DB 에만 저장되고 쭌은 메시지를 받지 못한다.
        fakechat.send(id, t);
        // [흐름 B-④] 아래 두 줄은 다음 순서로 실행된다.
        //   (1) FakechatClient.chatKey(id)          DB 에 쓸 고유 키를 만든다.        예) "web:web-1762724793776-a1b2c3"
        //   (2) new ChatMessage(키, null, FROM_BOSS, t, null, Instant.now())
        //                                           엔티티 객체를 만든다. 아직 DB 에는 없고 id 는 null 이다.
        //                                           두 번째 null = 팀 이름(아직 모름), 다섯 번째 null = 첨부 파일 이름(없음)
        //   (3) .withChannel("web")                 channel 필드에 "web" 을 넣고 같은 객체를 돌려준다.
        //   (4) chats.save((3)의 객체)               DB 에 저장한다. 실행되는 SQL:
        //                                           insert into chat_message (at,attachment_paths,attachments,channel,direction,team_name,text,unique_key,id)
        //                                           values (?,?,?,?,?,?,?,?,default)
        //                                           DB 가 id 를 정해 주고, id 가 채워진 엔티티가 돌아온다.   예) id = 103
        //   (5) return                              그 엔티티를 ChatApiController 로 돌려준다. → [흐름 B-⑤]
        return chats.save(new ChatMessage(FakechatClient.chatKey(id), null, ChatMessage.Direction.FROM_BOSS, t, null, Instant.now())
                .withChannel("web"));
    }

    /** 새 책 주문: 보내고, 주문 기록을 남긴다 */
    @Transactional
    // ────────────────────────────────────────────────────────────────────────────
    // [흐름 C-③] 첫 화면의 "새 책 주문하기" 폼 — ChatPageController.order() 가 호출한다
    // ────────────────────────────────────────────────────────────────────────────
    // ▶ 받는 값: 주문 글   예) "고양이 나오는 짧은 동화 써 줘"
    // @Transactional 이 붙어 있으므로 send() 의 저장과 아래 주문 저장이 하나의 트랜잭션이다.
    public ChatMessage order(String text) {
        // 위의 send() 를 그대로 실행한다. 쭌에게 전달하고 chat_message 표에 저장한다.
        ChatMessage m = send(text);
        // 주문 기록을 book_order 표에 저장한다. 실행되는 SQL:
        //   insert into book_order (at,chat_key,text,id) values (?,?,?,default)
        orders.save(new BookOrder(m.getText(), m.getUniqueKey(), m.getAt()));
        return m;
    }

    /** id 가 after 보다 큰 최근 메시지(최대 200개, 오래된 순) */
    // ────────────────────────────────────────────────────────────────────────────
    // [흐름 B′-③] 새 메시지 조회 — ChatApiController.poll() 이 3초마다 호출한다
    // ────────────────────────────────────────────────────────────────────────────
    // ▶ 받는 값: after   예) 102       ▶ 돌려주는 값: List<ChatMessage>   예) [ChatMessage(id=103)]
    public List<ChatMessage> messagesAfter(long after) {
        // 쭌의 답장은 쭌이 reply 도구를 쓸 때 Claude 대화 기록 파일(~/.claude/projects/…/*.jsonl)에 먼저 기록된다.
        // 그래서 DB 에서 꺼내기 전에, 마지막으로 읽은 지 2초가 지났으면 기록 파일을 다시 읽어 DB 에 반영한다. [흐름 F]
        // 없으면: 10초마다 도는 ScanScheduler 가 읽을 때까지 쭌의 답장이 화면에 늦게 나타난다.
        scans.scanIfStale(FRESHEN_MS);
        // (1) chats.findTop200ByOrderByAtDescIdDesc()   최근 메시지 200개를 최신 것부터 가져온다. 실행되는 SQL:
        //     select cm1_0.id,cm1_0.at,…,cm1_0.unique_key from chat_message cm1_0 order by cm1_0.at desc,cm1_0.id desc fetch first ? rows only
        // (2) new ArrayList<>(…)                         바꿀 수 있는 목록으로 옮긴다. (아래에서 순서를 뒤집고 원소를 지우기 위해)
        List<ChatMessage> list = new ArrayList<>(chats.findTop200ByOrderByAtDescIdDesc());
        // 순서를 뒤집는다. 최신 것부터 → 오래된 것부터.  화면에는 위에서 아래로 시간 순서대로 그리기 때문이다.
        Collections.reverse(list);
        // after 가 0 보다 크면, 번호가 after 이하인 메시지를 목록에서 지운다. (화면에 이미 있는 메시지)
        //   m -> m.getId() <= after   : "메시지 m 을 받아, m 의 번호가 after 이하이면 true" 라는 람다식. true 인 원소가 지워진다.
        //   예) after = 102, 목록의 번호 = [101, 102, 103] → 남는 것 = [103]
        //   after = 0 이면(화면을 처음 열 때) 아무것도 지우지 않는다.
        if (after > 0) list.removeIf(m -> m.getId() <= after);
        return list;
    }

    public ChatMessage message(Long id) {
        // (1) chats.findById(id)      번호로 찾는다. 자료형 Optional<ChatMessage> (찾으면 값이 있고, 없으면 비어 있다)
        // (2) .orElseThrow(…)         값이 있으면 그 값을 돌려주고, 비어 있으면 괄호 안에서 만든 예외를 발생시킨다.
        //                             → ApiExceptionHandler.notFound() → 404 [흐름 D-③]
        return chats.findById(id).orElseThrow(() -> new NotFoundException("메시지를 찾을 수 없어요."));
    }

    public List<BookOrder> recentOrders() {
        return orders.findTop20ByOrderByAtDesc();
    }

    /** 쭌이 보낸 첨부 파일 — 출판사 폴더 안의 파일만 */
    // 쭌이 보낸 첨부 파일의 경로를 돌려준다. ChatPageController.file() 이 호출한다 (GET /chat/59/file/0).
    // ▶ 받는 값: messageId = 59, index = 0     ▶ 돌려주는 값: Path   예) /home/사용자/my-publisher/books/20261109-dogwalk/dist/book.pdf
    // 보안 검사: 출판사 폴더 밖의 파일은 내주지 않는다.
    public Path attachment(Long messageId, int index) {
        List<String> paths = message(messageId).attachmentPathList();
        // 번호가 목록 범위 밖이면 404. 예) 첨부가 1개인데 index = 1
        if (index < 0 || index >= paths.size()) throw new NotFoundException("첨부 파일이 없어요.");
        // 출판사 폴더의 절대 경로.  normalize() 는 경로 안의 "a/../" 같은 부분을 정리한다.   예) /home/사용자/my-publisher
        Path root = props.rootPath().toAbsolutePath().normalize();
        Path f = Path.of(paths.get(index)).toAbsolutePath().normalize();
        // 파일 경로가 출판사 폴더로 시작하지 않으면 예외 → 400.
        // 없으면: 기록에 /etc/passwd 같은 경로가 들어 있을 때 그 파일을 누구나 내려받을 수 있게 된다.
        if (!f.startsWith(root)) throw new FileAccessDeniedException("출판사 폴더 밖의 파일은 내려받을 수 없어요.");
        if (!Files.isRegularFile(f)) throw new NotFoundException("파일이 지워졌어요.");
        try {
            // toRealPath() 는 바로가기(심볼릭 링크)를 따라간 실제 경로다.
            // 출판사 폴더 안에 있는 링크가 폴더 밖의 파일을 가리키는 경우를 막는다.
            if (!f.toRealPath().startsWith(root.toRealPath())) throw new FileAccessDeniedException("출판사 폴더 밖의 파일이에요.");
        } catch (IOException e) {
            throw new NotFoundException("파일을 읽을 수 없어요.");
        }
        return f;
    }
}
