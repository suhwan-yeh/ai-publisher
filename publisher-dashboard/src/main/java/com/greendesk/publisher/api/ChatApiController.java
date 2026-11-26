/*
 * [1] 역할
 *     사장님과 쭌이 주고받는 대화 메시지를 JSON 으로 받고 JSON 으로 응답하는 컨트롤러다.
 *     HTML 화면은 만들지 않는다. 화면의 자바스크립트(chatpanel.js)가 fetch 로 이 컨트롤러를 호출한다.
 *
 * [2] 받는 것 → 내보내는 것 (실제로 실행해서 얻은 값)
 *     요청   POST /api/chat
 *            Content-Type: application/json
 *            {"text":"좋아요, 이대로 진행해 주세요."}
 *     응답   HTTP/1.1 201
 *            Location: /api/chat/103
 *            Content-Type: application/json
 *            {"id":103,"fromBoss":true,"text":"좋아요, 이대로 진행해 주세요.","at":"2026-11-09T21:46:33.776008Z","channel":"web","files":[]}
 *
 * [3] 앞뒤 파일
 *     static/js/chatpanel.js  →  (이 파일)  →  service/ChatService.java
 *     요청 몸통의 모양: dto/SendMessageRequest.java      응답 몸통의 모양: dto/ChatMessageResponse.java, dto/ChatPollResponse.java
 *     오류가 났을 때 응답을 만드는 곳: api/ApiExceptionHandler.java
 *
 * [4] 메서드 목록
 *     메서드   HTTP 방식과 주소            하는 일                         성공 응답   흐름 번호
 *     send()   POST /api/chat             메시지 한 건을 보내고 저장한다    201         흐름 B
 *     poll()   GET  /api/chat?after=103   103번보다 새 메시지를 준다        200         흐름 B′
 *     one()    GET  /api/chat/103         103번 메시지 한 건을 준다         200
 *
 * [5] 먼저 알 용어 (자세한 설명: docs/용어-풀이.md)
 *     @RestController, @RequestMapping, @GetMapping, @PostMapping,
 *     @RequestParam, @PathVariable, @RequestBody, @Valid, ResponseEntity, 생성자 주입
 *
 * [6] 읽는 순서
 *     send() → poll() → one()
 *
 * [7] 다 읽고 확인
 *     - {"text":"   "} 처럼 공백만 보내면 send() 의 본문은 실행되는가? 응답 상태코드는 몇 번인가?
 *     - send() 는 201 을, poll() 은 200 을 응답한다. 두 메서드의 return 줄은 무엇이 다른가?
 */
package com.greendesk.publisher.api;

import com.greendesk.publisher.dto.ChatMessageResponse;
import com.greendesk.publisher.dto.ChatPollResponse;
import com.greendesk.publisher.dto.SendMessageRequest;
import com.greendesk.publisher.service.ChatService;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.net.URI;

/**
 * 사장님 ↔ 쭌 대화 REST API (JSON).
 * 대화방 화면(chat.html)이 fetch 로 부른다.
 *
 *   GET  /api/chat?after={id}  200  새 메시지 + 쭌 연결 상태
 *   GET  /api/chat/{id}        200  메시지 하나 / 404
 *   POST /api/chat             201  보낸 메시지 / 400 빈 글·너무 김 / 503 쭌이 출근 전
 */
// @RestController
//   뜻     : 이 클래스의 메서드가 return 한 객체를 JSON 글자로 바꿔서 응답 몸통에 넣는다.
//   받는 것: 메서드의 return 값 (자바 객체)
//   결과   : 응답 몸통 = JSON, 응답 헤더 Content-Type = application/json
//   비교   : @Controller 는 return 한 글자(예: "chat")를 템플릿 파일 이름으로 해석해 HTML 을 만든다.
//   없으면 : 스프링이 이 클래스를 컨트롤러로 등록하지 않는다. /api/chat 요청은 404 가 된다.
@RestController
// @RequestMapping("/api/chat")
//   뜻     : 이 클래스 안의 모든 메서드 주소 앞에 /api/chat 을 붙인다.
//   결과   : 아래 @GetMapping("/{id}") 의 실제 주소는 /api/chat/{id} 가 된다.
@RequestMapping("/api/chat")
public class ChatApiController {

    // 필드 chatService
    //   자료형 : ChatService (service/ChatService.java 에 있는 클래스)
    //   용도   : 메시지 보내기·조회 작업을 이 객체의 메서드로 실행한다. 컨트롤러는 작업 내용을 직접 구현하지 않는다.
    //   final  : 생성자에서 한 번 값을 넣으면 그 뒤로 다른 객체로 바꿀 수 없다.
    private final ChatService chatService;

    // 생성자 주입
    //   뜻     : 스프링이 프로그램을 시작할 때 ChatService 객체를 먼저 만들고, 이 생성자를 호출하면서 그 객체를 넘겨 준다.
    //   결과   : 이 클래스 안에서 new ChatService(...) 를 쓰지 않아도 chatService 를 사용할 수 있다.
    public ChatApiController(ChatService chatService) {
        // 매개변수로 받은 ChatService 객체를 이 클래스의 필드에 저장한다.
        this.chatService = chatService;
    }

    // ────────────────────────────────────────────────────────────────────────────
    // [흐름 B′] 3초마다 새 메시지 가져오기
    // ────────────────────────────────────────────────────────────────────────────
    // ▶ 이 메서드가 받는 값      : 주소의 after 값      예) GET /api/chat?after=102  →  after = 102
    // ▶ 이 메서드가 돌려주는 값  : ChatPollResponse 객체 → JSON 으로 바뀌어 응답된다
    //    실제 응답 몸통: {"online":true,"messages":[{"id":103,"fromBoss":true,"text":"좋아요, 이대로 진행해 주세요.",...}]}
    //
    // [흐름 B′-②] chatpanel.js 의 poll() 이 보낸 GET 요청이 이 메서드로 온다.
    //
    // @GetMapping
    //   뜻     : HTTP 방식이 GET 인 요청을 이 메서드가 처리한다. 괄호 안에 주소가 없으므로 클래스의 /api/chat 그대로다.
    @GetMapping
    // @RequestParam(defaultValue = "0") long after
    //   뜻     : 주소의 물음표 뒤에 있는 after=102 에서 102 를 꺼내 long 형 변수 after 에 넣는다.
    //   받는 것: 주소의 글자 "102"
    //   결과   : after = 102 (글자를 숫자로 바꾼 값)
    //   defaultValue = "0" : 주소에 after 가 없으면 after = 0
    //   숫자가 아니면(예: after=abc) : 변환에 실패한다 → ApiExceptionHandler 가 400 으로 응답한다 [흐름 D]
    public ChatPollResponse poll(@RequestParam(defaultValue = "0") long after) {
        // [흐름 B′-③④] 아래 return 문은 두 줄에 걸쳐 있고 다음 순서로 실행된다.
        //   (1) chatService.isLeadOnline()          쭌과 연결돼 있는지 확인한다.              예) true
        //   (2) chatService.messagesAfter(after)    after 번보다 번호가 큰 메시지를 DB 에서 가져온다.
        //                                           자료형: List<ChatMessage>                 예) [ChatMessage(id=103)]
        //   (3) .stream()                           목록의 원소를 하나씩 차례로 처리할 준비를 한다.
        //   (4) .map(ChatMessageResponse::from)     원소마다 ChatMessageResponse.from(원소) 를 실행해 응답용 객체로 바꾼다.
        //                                           ChatMessageResponse::from 은 "ChatMessageResponse 클래스의 from 메서드"를 가리키는 표기다.
        //   (5) .toList()                           바꾼 결과를 다시 목록으로 모은다.        자료형: List<ChatMessageResponse>
        //   (6) new ChatPollResponse((1)의 값, (5)의 값)   두 값을 담은 객체를 만든다.
        //   (7) return                              @RestController 이므로 이 객체가 JSON 글자로 바뀌어 응답된다. 상태코드는 200.
        //       → 응답은 chatpanel.js 의 [흐름 B′-⑤] 로 간다.
        return new ChatPollResponse(chatService.isLeadOnline(),
                chatService.messagesAfter(after).stream().map(ChatMessageResponse::from).toList());
    }

    // ────────────────────────────────────────────────────────────────────────────
    // 메시지 한 건 조회
    // ────────────────────────────────────────────────────────────────────────────
    // ▶ 받는 값: 주소 안의 번호    예) GET /api/chat/103 → id = 103
    // ▶ 돌려주는 값: ChatMessageResponse 객체 → JSON
    //
    // @GetMapping("/{id}")
    //   뜻     : GET /api/chat/103 처럼 /api/chat/ 뒤에 값이 하나 더 붙은 주소를 처리한다. {id} 자리의 값에 id 라는 이름을 붙인다.
    @GetMapping("/{id}")
    // @PathVariable Long id
    //   뜻     : 주소의 {id} 자리에 있던 글자를 Long 형 변수 id 에 넣는다.
    //   결과   : GET /api/chat/103 → id = 103
    //   @RequestParam 과의 차이: @RequestParam 은 ?after=103 처럼 물음표 뒤의 값, @PathVariable 은 주소 경로 안의 값을 꺼낸다.
    public ChatMessageResponse one(@PathVariable Long id) {
        // (1) chatService.message(id)          DB 에서 id 번 메시지를 찾는다.   자료형: ChatMessage
        //     없는 번호이면 NotFoundException 이 발생한다.
        //     실제 응답(GET /api/chat/999999): 404  {"status":404,"code":"NOT_FOUND","message":"메시지를 찾을 수 없어요.",...}   [흐름 D]
        // (2) ChatMessageResponse.from(...)    응답용 객체로 바꾼다.
        // (3) return                           JSON 으로 응답한다. 상태코드 200.
        return ChatMessageResponse.from(chatService.message(id));
    }

    // ────────────────────────────────────────────────────────────────────────────
    // [흐름 B] 사장님이 "보내기"를 눌렀을 때
    // ────────────────────────────────────────────────────────────────────────────
    // ▶ 이 메서드가 받는 값      : 요청 몸통의 JSON        {"text":"좋아요, 이대로 진행해 주세요."}
    // ▶ 이 메서드가 돌려주는 값  : 상태코드 201 + Location 헤더 + JSON 몸통
    // ▶ 실행 중 일어나는 SQL    : insert into chat_message (at,attachment_paths,attachments,channel,direction,team_name,text,unique_key,id) values (?,?,?,?,?,?,?,?,default)
    //
    // [흐름 B-②] chatpanel.js 의 send() 가 fetch 로 보낸 POST 요청이 이 메서드로 온다.
    //
    // @PostMapping
    //   뜻     : HTTP 방식이 POST 인 요청을 이 메서드가 처리한다. POST 는 서버에 새 데이터를 만들 때 쓰는 방식이다.
    //   없으면 : POST /api/chat 요청을 처리할 메서드가 없어서 405 (Method Not Allowed) 가 응답된다.
    @PostMapping
    // 매개변수 앞의 두 어노테이션은 오른쪽(@RequestBody)이 먼저, 왼쪽(@Valid)이 나중에 적용된다.
    //
    // @RequestBody SendMessageRequest request
    //   뜻     : 요청 몸통의 JSON 글자를 SendMessageRequest 객체로 바꾼다.
    //   받는 것: {"text":"좋아요, 이대로 진행해 주세요."}
    //   결과   : request.text() = "좋아요, 이대로 진행해 주세요."
    //   없으면 : 스프링이 요청 몸통을 읽지 않는다. request.text() 는 null 이 된다.
    //
    // @Valid
    //   뜻     : 만들어진 request 객체가 SendMessageRequest 에 적힌 규칙(@NotBlank, @Size)을 지키는지 검사한다.
    //   통과   : 이 메서드의 본문이 실행된다.
    //   실패   : 이 메서드의 본문은 실행되지 않는다. ApiExceptionHandler 가 400 으로 응답한다. [흐름 D-①]
    //            실제 응답({"text":"   "} 를 보냈을 때): 400  {"status":400,"code":"VALIDATION","message":"보낼 말을 적어 주세요.",...}
    //   없으면 : 검사를 하지 않는다. 공백만 있는 글이 ChatService 까지 전달된다.
    //
    // 반환형 ResponseEntity<ChatMessageResponse>
    //   뜻     : 상태코드, 헤더, 몸통을 코드에서 직접 지정하는 응답 객체다. 몸통의 자료형은 ChatMessageResponse 다.
    //   이유   : 객체만 return 하면 상태코드가 항상 200 이다. 201 과 Location 헤더를 넣으려고 ResponseEntity 를 쓴다.
    public ResponseEntity<ChatMessageResponse> send(@Valid @RequestBody SendMessageRequest request) {
        // [흐름 B-③] 아래 한 줄은 안쪽 괄호부터 다음 순서로 실행된다.
        //   (1) request.text()                  요청에서 글자를 꺼낸다.            예) "좋아요, 이대로 진행해 주세요."
        //   (2) chatService.send((1)의 값)       ChatService.send() 를 실행한다. 쭌에게 전달하고 DB 에 저장한다.  → [흐름 B-③④]
        //                                        자료형: ChatMessage (저장이 끝난 엔티티)   예) ChatMessage(id=103, text="좋아요, …")
        //                                        쭌과 연결이 안 돼 있으면 여기서 ChannelUnavailableException 이 발생한다.
        //                                        실제 응답: 503  {"status":503,"code":"LEAD_OFFLINE","message":"쭌이 출근 전이에요. …"}   [흐름 D-②]
        // [흐름 B-⑤]
        //   (3) ChatMessageResponse.from((2)의 값)   엔티티를 응답용 객체로 바꾼다.     예) sent.id() = 103, sent.fromBoss() = true
        //   (4) sent = (3)의 값                  변수 sent 에 저장한다.             자료형: ChatMessageResponse
        ChatMessageResponse sent = ChatMessageResponse.from(chatService.send(request.text()));
        // [흐름 B-⑥] 아래 한 줄은 다음 순서로 실행된다.
        //   (1) "/api/chat/" + sent.id()        글자를 이어 붙인다.                예) "/api/chat/103"
        //   (2) URI.create((1)의 값)             글자를 주소 객체(URI)로 바꾼다.
        //   (3) ResponseEntity.created((2)의 값) 상태코드 201 과 헤더 Location: /api/chat/103 을 가진 응답을 만들기 시작한다.
        //   (4) .body(sent)                      응답 몸통에 sent 를 넣는다. 응답할 때 JSON 글자로 바뀐다.
        //   (5) return                           응답을 내보낸다.
        // 실제 응답:
        //   HTTP/1.1 201
        //   Location: /api/chat/103
        //   Content-Type: application/json
        //   {"id":103,"fromBoss":true,"text":"좋아요, 이대로 진행해 주세요.","at":"2026-11-09T21:46:33.776008Z","channel":"web","files":[]}
        // → 이 응답을 chatpanel.js 의 send() 가 받는다. [흐름 B-⑦]
        return ResponseEntity.created(URI.create("/api/chat/" + sent.id())).body(sent);
    }
}
