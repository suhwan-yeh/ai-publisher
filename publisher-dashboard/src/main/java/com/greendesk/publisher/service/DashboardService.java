/*
 * [1] 역할
 *     책 목록, 책 한 권의 상세 정보, 직원 목록, 파일 내려받기 정보를 만드는 서비스 클래스다.
 *     책마다 "그 책을 만드는 동안 오간 메시지"를 골라 BookView 로 묶는다. 4가지 점검 계산은 BookView 가 한다.
 *
 * [2] 받는 것 → 내보내는 것 (실제로 실행해서 얻은 값)
 *     allBooks()
 *       → SQL  select b1_0.id,b1_0.chapter_count,…,b1_0.updated_at from book b1_0 order by b1_0.created_at
 *       → SQL  select tm1_0.id,… from team_member tm1_0 order by tm1_0.last_active desc
 *       → SQL  select … from chat_message cm1_0 where cm1_0.at between ? and ? order by cm1_0.at
 *       → 돌려주는 값 List<BookView> (최신 책이 먼저)        예) [BookView(20261109-dinosaur), BookView(20261109-commutepoems), …]
 *     bookOrThrow(9999)  → NotFoundException("책을 찾을 수 없어요.") → API 면 404
 *
 * [3] 앞뒤 파일
 *     controller/DashboardController.java, api/BookApiController.java, service/OfficeService.java  →  (이 파일)
 *     (이 파일)  →  repository/BookRepository, TeamMessageRepository, ChatMessageRepository, TeamMemberRepository, BookSessionRepository
 *     만들어 돌려주는 값: service/BookView.java, service/ChapterPreview.java, service/DownloadFile.java
 *
 * [4] 메서드 목록
 *     메서드              하는 일                                                부르는 곳                         흐름 번호
 *     allBooks()          모든 책의 BookView 목록 (최신 책이 먼저)                 DashboardController.index         흐름 A-③
 *     book(id)            id 번 책의 BookView (없으면 Optional.empty)
 *     bookOrThrow(id)     id 번 책의 BookView (없으면 NotFoundException → 404)    BookApiController.one             흐름 D-③
 *     setupStatus()       책 폴더·대화 기록 폴더가 있는지 (첫 화면 안내용)          DashboardController.index
 *     chapters(v)         장별 원고 미리보기                                      DashboardController.book
 *     download(id, kind)  내려받을 파일 정보 (정해진 파일만)                       DashboardController.download
 *     activeMembers(d)    최근 d 시간 안에 활동한 직원
 *     allMembers()        모든 직원 (최근 활동 순)
 *     view(asc, i)        (내부용) i 번째 책의 BookView 를 만든다
 *
 * [5] 먼저 알 용어 (자세한 설명: docs/용어-풀이.md)
 *     @Service, @Transactional(readOnly = true), Optional, record, Duration·Instant, Set, stream·filter·anyMatch·toList
 *
 * [6] 읽는 순서
 *     allBooks() → view() → bookOrThrow() → download() → 나머지
 *
 * [7] 다 읽고 확인
 *     - allBooks() 에서 out.add(0, …) 를 out.add(…) 로 바꾸면 책 목록의 순서는 어떻게 되는가?
 *     - view() 는 팀(쭌의 세션)을 찾았을 때와 못 찾았을 때 메시지를 어떻게 다르게 고르는가?
 */
package com.greendesk.publisher.service;

import com.greendesk.publisher.config.PublisherProperties;
import com.greendesk.publisher.domain.*;
import com.greendesk.publisher.repository.BookRepository;
import com.greendesk.publisher.repository.BookSessionRepository;
import com.greendesk.publisher.repository.ChatMessageRepository;
import com.greendesk.publisher.repository.TeamMemberRepository;
import com.greendesk.publisher.repository.TeamMessageRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.nio.file.Files;
import java.nio.file.Path;
import java.time.Duration;
import java.time.Instant;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;
import java.util.Set;
import java.util.stream.Collectors;

/**
 * 책마다 '그 책을 만드는 동안' 오간 기록을 모은다.
 * 책 폴더가 생긴 시각(조금 앞 여유 포함)부터 다음 책이 시작되기 전까지를 그 책의 기간으로 본다.
 */
// 스프링이 객체를 하나 만들어 필요한 곳에 넣어 주는 서비스 클래스.
@Service
// @Transactional(readOnly = true)  (클래스에 붙이면 모든 public 메서드에 적용된다)
//   뜻     : DB 를 읽기만 하는 트랜잭션으로 실행한다. 저장·수정 SQL 을 실행하지 않는다는 표시다.
//   결과   : JPA 가 변경 감지 작업을 하지 않아 읽기가 조금 빨라진다.
@Transactional(readOnly = true)
public class DashboardService {

    /** 사장님 주문은 폴더가 생기기 조금 전에 오므로 앞쪽 여유 */
    // Duration = 시간의 길이를 나타내는 자료형.  Duration.ofMinutes(3) = 3분.
    // 사장님의 주문 메시지는 책 폴더가 만들어지기 몇 분 전에 오므로, 책의 기간을 폴더가 생긴 시각보다 3분 앞에서 시작한다.
    static final Duration LEAD_IN = Duration.ofMinutes(3);

    // 아래 여섯 필드는 생성자에서 스프링이 넣어 준다.
    //   books         book 표             teamMessages   team_message 표       chats     chat_message 표
    //   members       team_member 표      bookSessions   book_session 표 (어느 팀이 어느 책 폴더를 다뤘는지)
    //   props         application.yml 의 경로 설정
    private final BookRepository books;
    private final TeamMessageRepository teamMessages;
    private final ChatMessageRepository chats;
    private final TeamMemberRepository members;
    private final BookSessionRepository bookSessions;
    private final PublisherProperties props;

    public DashboardService(BookRepository books, TeamMessageRepository teamMessages,
                            ChatMessageRepository chats, TeamMemberRepository members,
                            BookSessionRepository bookSessions, PublisherProperties props) {
        this.bookSessions = bookSessions;
        this.props = props;
        this.books = books;
        this.teamMessages = teamMessages;
        this.chats = chats;
        this.members = members;
    }

    // ────────────────────────────────────────────────────────────────────────────
    // [흐름 A-③] 첫 화면 요청 — DashboardController.index() 가 호출한다
    // ────────────────────────────────────────────────────────────────────────────
    // ▶ 받는 값: 없음     ▶ 돌려주는 값: List<BookView>  (최신 책이 목록의 앞)
    public List<BookView> allBooks() {
        // 모든 책을 만든 시각 순서(오래된 것부터)로 가져온다. 실행되는 SQL:
        //   select b1_0.id,b1_0.chapter_count,b1_0.char_count,b1_0.created_at,b1_0.folder,… from book b1_0 order by b1_0.created_at
        // 변수 이름 asc = ascending(오름차순).   예) asc = [Book(commutepoems), Book(dinosaur)]
        List<Book> asc = books.findAllByOrderByCreatedAtAsc();
        // 결과를 담을 빈 목록.
        List<BookView> out = new ArrayList<>();
        // (1) view(asc, i)       i 번째 책의 BookView 를 만든다. (아래 view() 메서드)
        // (2) out.add(0, …)      목록의 맨 앞(0번 자리)에 넣는다. 오래된 책부터 차례로 맨 앞에 넣으므로, 끝나면 최신 책이 맨 앞이 된다.
        //     예) i=0: out=[commutepoems]   i=1: out=[dinosaur, commutepoems]
        for (int i = 0; i < asc.size(); i++) out.add(0, view(asc, i));
        return out;
    }

    // ▶ 받는 값: 책 번호 id     ▶ 돌려주는 값: Optional<BookView>  (찾으면 값이 있고, 없으면 비어 있다)
    public Optional<BookView> book(Long id) {
        List<Book> asc = books.findAllByOrderByCreatedAtAsc();
        // 책 목록을 처음부터 보며 번호가 id 와 같은 책을 찾으면 그 책의 BookView 를 담아 바로 return 한다.
        // .equals(id) : Long 객체끼리는 == 대신 equals 로 값을 비교한다.
        for (int i = 0; i < asc.size(); i++) if (asc.get(i).getId().equals(id)) return Optional.of(view(asc, i));
        // 끝까지 못 찾으면 빈 Optional 을 돌려준다.
        return Optional.empty();
    }

    public BookView bookOrThrow(Long id) {
        // book(id) 결과가 비어 있으면 NotFoundException 을 발생시킨다.
        //   API 요청이면 ApiExceptionHandler → 404 {"status":404,"code":"NOT_FOUND","message":"책을 찾을 수 없어요.",…}   [흐름 D-③]
        //   화면 요청이면 NotFoundException 의 @ResponseStatus → 404 오류 화면
        return book(id).orElseThrow(() -> new NotFoundException("책을 찾을 수 없어요."));
    }

    /** 책 폴더·대화 기록 폴더가 있는지 (첫 화면 안내용) */
    // 클래스 안에 선언한 record. 첫 화면에 "아직 읽을 기록이 없어요" 안내를 보여 줄지 정할 때 쓴다.
    //   예) SetupStatus(root="/root/my-publisher", transcripts="/root/.claude/projects/-root-my-publisher", booksFound=true, transcriptsFound=true)
    public record SetupStatus(String root, String transcripts, boolean booksFound, boolean transcriptsFound) {
    }

    public SetupStatus setupStatus() {
        return new SetupStatus(props.rootPath().toString(), props.transcriptsPath().toString(),
                // Files.isDirectory(경로) = 그 경로에 폴더가 있으면 true.
                Files.isDirectory(props.booksPath()), Files.isDirectory(props.transcriptsPath()));
    }

    /** 장별 원고·교정 미리보기 */
    public List<ChapterPreview> chapters(BookView v) {
        // (1) props.booksPath()             책 폴더들의 위치          예) /root/my-publisher/books
        // (2) .resolve(v.book().getFolder()) 그 아래 이 책의 폴더      예) /root/my-publisher/books/20261109-dogwalk
        // (3) ChapterPreview.read(…)        manuscript/*.md 파일을 읽어 장별 미리보기 목록을 만든다
        return ChapterPreview.read(props.booksPath().resolve(v.book().getFolder()));
    }

    /** 완성 파일 내려받기 — 정해진 파일(PDF·EPUB·HTML·표지)만 내보내고 다른 경로는 막음 */
    // ────────────────────────────────────────────────────────────────────────────
    // 파일 내려받기 — DashboardController.download() 가 호출한다 (GET /download/1/pdf)
    // ────────────────────────────────────────────────────────────────────────────
    // ▶ 받는 값: id = 1, kind = "pdf"
    // ▶ 돌려주는 값: DownloadFile(path=/root/my-publisher/books/20261109-dogwalk/dist/book.pdf, fileName="꼬리 살랑, 첫 산책.pdf", mediaType="application/pdf", inline=false)
    // 보안: 정해진 네 종류(PDF·EPUB·HTML·표지)만 내준다. 주소에 아무 경로나 넣어 다른 파일을 받아 가지 못하게 한다.
    public DownloadFile download(Long id, String kind) {
        Book b = bookOrThrow(id).book();
        BookFile.Kind k;
        try {
            // (1) kind.toUpperCase(…)              대문자로 바꾼다.          예) "pdf" → "PDF"
            // (2) BookFile.Kind.valueOf("PDF")     같은 이름의 enum 값을 찾는다.  → BookFile.Kind.PDF
            //     없는 이름이면(예: "secret") IllegalArgumentException 이 발생한다 → 아래 catch 로 간다
            k = BookFile.Kind.valueOf(kind.toUpperCase(java.util.Locale.ROOT));
        } catch (IllegalArgumentException e) {
            // 정해진 종류가 아니면 404. (try { … } catch (예외 e) { … } = try 안에서 그 예외가 발생하면 catch 안을 실행한다)
            throw new NotFoundException("그런 파일 종류는 없어요.");
        }
        Path base = props.booksPath().resolve(b.getFolder()).normalize();
        // 종류별로 정해진 상대 경로를 책 폴더에 붙인다.
        //   예) base = /root/my-publisher/books/20261109-dogwalk, k = PDF → f = /root/my-publisher/books/20261109-dogwalk/dist/book.pdf
        Path f = base.resolve(k.getRelativePath()).normalize();
        // 파일이 책 폴더 밖이거나, 아직 만들어지지 않았으면 404.
        if (!f.startsWith(base) || !Files.isRegularFile(f)) throw new NotFoundException("파일이 아직 없어요.");
        // 브라우저가 저장할 파일 이름을 만든다.
        //   (1) b.displayTitle()                       책 제목                          예) "꼬리 살랑, 첫 산책"
        //   (2) .replaceAll("[\\/:*?\"<>|]", "_")      파일 이름에 쓸 수 없는 글자를 _ 로 바꾼다
        //   (3) f.getFileName().toString()             실제 파일 이름                    예) "book.pdf"
        //   (4) .replaceFirst(".*\\.", "")              마지막 점까지 지우고 확장자만 남긴다   예) "pdf"
        //   (5) (2) + "." + (4)                        예) "꼬리 살랑, 첫 산책.pdf"
        String name = b.displayTitle().replaceAll("[\\\\/:*?\"<>|]", "_") + "." + f.getFileName().toString().replaceFirst(".*\\.", "");
        // 표지(SVG)와 HTML 은 브라우저 창에서 바로 열고(true), PDF·EPUB 은 파일로 저장한다(false).
        boolean inline = k == BookFile.Kind.COVER || k == BookFile.Kind.HTML;
        return new DownloadFile(f, name, k.getMediaType(), inline);
    }

    public List<TeamMember> activeMembers(Duration within) {
        // Instant.now().minus(within) = 지금으로부터 within 만큼 전의 시각.   예) within = 2분 → 2분 전
        // 그 시각 이후에 활동한 직원을 이름 순으로 가져온다. 실행되는 SQL:
        //   select tm1_0.id,… from team_member tm1_0 where tm1_0.last_active>? order by tm1_0.name
        return members.findByLastActiveAfterOrderByNameAsc(Instant.now().minus(within));
    }

    public List<TeamMember> allMembers() {
        return members.findAllByOrderByLastActiveDesc();
    }

    // ────────────────────────────────────────────────────────────────────────────
    // (내부용) i 번째 책에 속하는 직원·메시지를 골라 BookView 를 만든다
    // ────────────────────────────────────────────────────────────────────────────
    // private : 이 클래스 안에서만 호출할 수 있다.
    // 고르는 방법 1 (우선): 대화 기록에서 "이 책 폴더를 다룬 팀(쭌의 Claude 세션)"을 찾아, 그 팀의 메시지만 고른다.
    // 고르는 방법 2 (팀을 못 찾았을 때): 책 폴더가 생긴 시각부터 다음 책이 시작되기 전까지의 메시지를 고른다.
    private BookView view(List<Book> asc, int i) {
        Book b = asc.get(i);
        // 이 책의 기간 시작 = 책 폴더가 생긴 시각 - 3분.  만든 시각을 모르면 Instant.EPOCH(1970-01-01).
        Instant from = b.getCreatedAt() == null ? Instant.EPOCH : b.getCreatedAt().minus(LEAD_IN);
        // 이 책의 기간 끝 = 다음 책의 시작 시각 - 3분.  다음 책이 없으면(가장 최근 책) 지금부터 3650일 뒤(사실상 끝 없음).
        Instant to = i + 1 < asc.size() && asc.get(i + 1).getCreatedAt() != null
                ? asc.get(i + 1).getCreatedAt().minus(LEAD_IN) : Instant.now().plus(Duration.ofDays(3650));
        // 이 책 폴더를 다룬 팀(쭌의 세션)을 대화 기록 속 파일 경로로 찾는다.
        // (1) bookSessions.findByFolder(폴더)   이 책 폴더를 다룬 기록들       자료형 List<BookSession>
        // (2) .map(x -> x.getTeamName())       각각에서 팀 이름만 꺼낸다       예) "session-2d8e941e"
        // (3) .collect(Collectors.toSet())     Set 으로 모은다. Set 은 같은 값을 한 번만 담는 모음이다.
        //     예) teams = {"session-2d8e941e"}
        Set<String> teams = bookSessions.findByFolder(b.getFolder()).stream().map(x -> x.getTeamName()).collect(Collectors.toSet());
        // 팀을 찾았으면 → 고르는 방법 1
        if (!teams.isEmpty()) {
            // 같은 팀이 다른 책도 만들었으면 시간으로 한 번 더 나누고, 이 책만 만들었으면 팀 기록 전체가 이 책의 기록
            // shared = 같은 팀이 다른 책도 만들었는가.
            //   (1) 이 책을 뺀 나머지 책들 중에서 (filter)
            //   (2) 그 책 폴더를 다룬 팀이 teams 안에 하나라도 있으면 (anyMatch) true
            // 같은 팀이 여러 책을 만들었으면 팀만으로는 나눌 수 없으므로 시간으로 한 번 더 나눈다.
            boolean shared = asc.stream().filter(o -> !o.getId().equals(b.getId()))
                    .anyMatch(o -> bookSessions.findByFolder(o.getFolder()).stream().anyMatch(x -> teams.contains(x.getTeamName())));
            Instant f2 = shared ? from : Instant.EPOCH;
            Instant t2 = shared ? to : Instant.now().plus(Duration.ofDays(3650));
            // 기간(f2~t2) 안의 직원 메시지 중 팀이 teams 에 속한 것만 고른다.
            //   SQL: select … from team_message tm1_0 where tm1_0.at between ? and ? order by tm1_0.at
            //   .filter(m -> teams.contains(m.getTeamName()))  : 팀 이름이 teams 에 들어 있는 메시지만 남긴다
            List<TeamMessage> tm = teamMessages.findByAtBetweenOrderByAtAsc(f2, t2).stream()
                    .filter(m -> teams.contains(m.getTeamName())).toList();
            List<ChatMessage> ch = chats.findByAtBetweenOrderByAtAsc(f2, t2).stream()
                    .filter(c -> teams.contains(c.getTeamName())).toList();
            List<TeamMember> mem = members.findAllByOrderByLastActiveDesc().stream()
                    .filter(m -> teams.contains(m.getTeamName())).toList();
            // 고른 직원(mem)·직원 메시지(tm)·대화(ch)를 책과 함께 묶어 돌려준다. 점검 계산은 BookView 가 한다.
            return new BookView(b, mem, tm, ch);
        }
        // 팀을 못 찾으면 시간으로만 나눔
        // 고르는 방법 2: 팀을 못 찾았으면 기간(from~to) 안의 메시지를 모두 이 책의 것으로 본다.
        List<TeamMessage> tm = teamMessages.findByAtBetweenOrderByAtAsc(from, to);
        List<ChatMessage> ch = chats.findByAtBetweenOrderByAtAsc(from, to);
        List<TeamMember> mem = members.findAllByOrderByLastActiveDesc().stream()
                .filter(m -> m.getLastActive() != null && !m.getLastActive().isBefore(from) && m.getFirstSeen().isBefore(to))
                .toList();
        return new BookView(b, mem, tm, ch);
    }
}
