/*
 * [1] 역할
 *     쭌과의 대화방 화면(GET /chat)과 첫 화면의 "새 책 주문하기" 폼(POST /order)을 받는 컨트롤러다.
 *     대화방의 처음 메시지 목록은 여기서 HTML 로 그리고, 그 뒤의 보내기·새 메시지는 chatpanel.js 가 fetch 로 api/ChatApiController 를 부른다(흐름 B, B′).
 *
 * [2] 받는 것 → 내보내는 것 (실제로 실행해서 얻은 값)
 *     흐름 C (폼 전송) 실제 요청과 응답
 *       요청   POST /order HTTP/1.1
 *              Content-Type: application/x-www-form-urlencoded
 *
 *              text=%EA%B3%A0%EC%96%91%EC%9D%B4…   (= "고양이 나오는 짧은 동화 써 줘" 를 주소용 글자로 바꾼 것)
 *       응답   HTTP/1.1 302
 *              Location: http://localhost:8080/chat
 *              Content-Length: 0
 *       그 뒤  브라우저가 GET /chat 을 보내 대화방 HTML 을 받는다.
 *       DB     insert into book_order (at,chat_key,text,id) values (?,?,?,default)
 *              insert into chat_message (at,attachment_paths,attachments,channel,direction,team_name,text,unique_key,id) values (…)
 *
 * [3] 앞뒤 파일
 *     templates/index.html 의 주문 폼  →  (이 파일) order()  →  service/ChatService.java 의 order()  →  redirect:/chat  →  (이 파일) chat()
 *     (이 파일) chat()  →  templates/chat.html  →  static/js/chatpanel.js
 *
 * [4] 메서드 목록
 *     메서드          주소                              돌려주는 것                                흐름 번호
 *     chat()          GET  /chat                        chat.html                                 흐름 A-②, C-④
 *     order()         POST /order                       성공 redirect:/chat, 실패 redirect:/       흐름 C-②, C-③
 *     file()          GET  /chat/{id}/file/{index}      쭌이 보낸 첨부 파일 바이트
 *
 * [5] 먼저 알 용어 (자세한 설명: docs/용어-풀이.md)
 *     @Controller, @GetMapping, @PostMapping, @RequestParam, RedirectAttributes(flash), redirect:, PRG(Post → Redirect → Get), multi-catch(A | B e)
 *
 * [6] 읽는 순서
 *     order() → chat() → file()
 *
 * [7] 다 읽고 확인
 *     - 쭌이 출근하지 않았을 때 주문하면 어느 화면으로 돌아가고, 적었던 글은 어떻게 다시 보이는가? (redirect:/ + flash 의 draft)
 *     - order() 가 "chat" 을 돌려주면(redirect 없이) 새로고침할 때 무슨 일이 생기는가? (같은 주문이 한 번 더 들어간다)
 */
package com.greendesk.publisher.controller;

import com.greendesk.publisher.client.ChannelUnavailableException;
import com.greendesk.publisher.service.ChatService;
import com.greendesk.publisher.service.DownloadFile;
import org.springframework.core.io.FileSystemResource;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.servlet.mvc.support.RedirectAttributes;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.Optional;

/**
 * 화면용 컨트롤러: 쭌과의 대화방
 *
 *   GET  /chat                     chat.html  대화방 (새 메시지는 화면이 fetch 로 /api/chat 을 부름)
 *   POST /order                    → redirect:/chat  첫 화면 "새 책 주문하기" 폼 (실패하면 redirect:/ + 안내)
 *   GET  /chat/{id}/file/{index}   쭌이 보낸 첨부 파일 내려받기
 */
// @Controller
//   뜻     : 화면(HTML) 요청을 받는 컨트롤러. 돌려주는 글자는 템플릿 이름이다.  "chat" → templates/chat.html
@Controller
public class ChatPageController {

    // chatService: 쭌에게 전달하고 DB 에 저장하는 일을 맡은 서비스. 생성자 주입으로 받는다.
    private final ChatService chatService;

    public ChatPageController(ChatService chatService) {
        this.chatService = chatService;
    }

    // [흐름 A-②] [흐름 C-④] 대화방 화면
    // 주소창에 /chat 을 치거나, order() 의 redirect 를 받은 브라우저가 GET /chat 을 보낸다.
    @GetMapping("/chat")
    // Model model
    //   뜻     : 컨트롤러가 템플릿(HTML)에 넘길 값을 담는 객체. 스프링이 만들어 매개변수로 넣어 준다.
    //   결과   : model.addAttribute("이름", 값) 으로 넣은 값을 템플릿에서 ${이름} 으로 꺼낸다.
    public String chat(Model model) {
        // (1) chatService.messagesAfter(0)  id 가 0 보다 큰 메시지 = 모든 메시지.  List<ChatMessageResponse>
        // (2) chat.html 의 th:each 가 메시지마다 말풍선을 그린다. 마지막 id 는 chatpanel.js 가 폴링(흐름 B′)할 때 after= 값으로 쓴다.
        model.addAttribute("messages", chatService.messagesAfter(0));
        // 쭌이 출근해 fakechat(127.0.0.1:8787)이 응답하면 true. 화면 위의 "쭌 연결됨/연결 안 됨" 표시에 쓴다.
        model.addAttribute("online", chatService.isLeadOnline());
        return "chat";
    }

    /** 폼 전송 → 처리 → 다른 화면으로 이동 (PRG 패턴) */
    // [흐름 C-②] 첫 화면 "새 책 주문하기" 폼이 보낸 요청
    // @PostMapping("/order") : POST 방식으로 /order 에 온 요청을 받는다. (index.html 의 <form method="post" th:action="@{/order}">)
    @PostMapping("/order")
    // @RequestParam String text
    //   뜻     : 폼 값(또는 주소의 ?text=…) 중 이름이 text 인 것을 꺼낸다.
    //   받는 것: 몸통 text=%EA%B3%A0…  (<textarea name="text"> 의 내용)
    //   결과   : text = "고양이 나오는 짧은 동화 써 줘"
    //   없으면(폼에 text 칸이 없으면): 400 Bad Request
    // RedirectAttributes ra
    //   뜻     : redirect 한 다음 화면에 한 번만 넘길 값(flash)을 담는다. 세션에 잠깐 두었다가 다음 요청에서 꺼내고 지운다.
    public String order(@RequestParam String text, RedirectAttributes ra) {
        try {
            // [흐름 C-③] 주문 처리: (1) 빈 글 검사 (2) 쭌에게 전달 (3) book_order, chat_message 두 표에 저장
            // 빈 글이면 IllegalArgumentException, 쭌이 없으면 ChannelUnavailableException 이 던져져 아래 catch 로 간다.
            chatService.order(text);
            // [흐름 C-④] PRG 패턴의 R(Redirect).
            // 실제 응답) HTTP/1.1 302   Location: http://localhost:8080/chat
            // 브라우저가 GET /chat 을 새로 보내므로, 새로고침해도 주문이 다시 전송되지 않는다.
            return "redirect:/chat";
        // 두 예외 중 어느 것이든 여기서 잡는다(multi-catch).
        // API 요청이었다면 ApiExceptionHandler 가 JSON 오류(400/503)를 돌려줬겠지만, 폼은 화면으로 돌아가야 하므로 여기서 직접 처리한다.
        } catch (IllegalArgumentException | ChannelUnavailableException e) {
            // 첫 화면에서 ${error} 로 보일 안내 문장.  예) "쭌이 출근 전이에요. 우분투 창에서 '출근'을 입력한 뒤 다시 보내 주세요."
            ra.addFlashAttribute("error", e.getMessage());
            // 사장님이 적었던 글. 첫 화면의 입력칸에 다시 채워 주어 처음부터 다시 쓰지 않게 한다.
            ra.addFlashAttribute("draft", text);
            // 실패하면 첫 화면으로 302. flash 값(error, draft)은 그 GET / 요청에서 한 번만 보인다.
            return "redirect:/";
        }
    }

    // 쭌이 보낸 첨부 파일 내려받기.  예) GET /chat/57/file/0 → 57번 메시지의 첫 번째 첨부 파일
    @GetMapping("/chat/{id}/file/{index}")
    public ResponseEntity<FileSystemResource> file(@PathVariable Long id, @PathVariable int index) throws IOException {
        // 메시지의 첨부 경로 목록에서 index 번째 경로. 메시지·파일이 없으면 404, 출판사 폴더 밖이면 400 (FileAccessDeniedException → ApiExceptionHandler 의 FILE_DENIED).
        Path f = chatService.attachment(id, index);
        // (1) Files.probeContentType(f)          확장자로 파일 종류를 알아낸다.  예) book.pdf → "application/pdf"
        // (2) Optional.ofNullable(…).orElse(…)   모르면 null 이 오므로 "application/octet-stream"(그냥 바이트)을 쓴다.
        String type = Optional.ofNullable(Files.probeContentType(f)).orElse(MediaType.APPLICATION_OCTET_STREAM_VALUE);
        // 마지막 false = 브라우저 안에서 열지 않고 내려받는다(attachment).
        return FileResponses.of(new DownloadFile(f, f.getFileName().toString(), type, false));
    }
}
