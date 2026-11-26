/*
 * [1] 역할
 *     사무실(GET /office)과 회의실(GET /meeting) 화면의 틀을 돌려주는 컨트롤러다.
 *     책상·봉투·말풍선처럼 움직이는 내용은 이 클래스가 그리지 않는다. 화면이 열린 뒤 office.js, meeting.js 가 fetch 로
 *     /api/office, /api/meeting 을 2초마다 불러 그린다(흐름 E).
 *
 * [2] 받는 것 → 내보내는 것 (실제로 실행해서 얻은 값)
 *     요청   GET /office
 *     응답   200  Content-Type: text/html;charset=UTF-8   (office.html: 빈 사무실 틀 + 사장실 대화 패널의 처음 메시지)
 *     그 뒤  office.js 가 GET /api/office 를 보내 JSON 을 받는다 (흐름 E-②)
 *
 * [3] 앞뒤 파일
 *     브라우저  →  (이 파일)  →  templates/office.html, meeting.html
 *     office.html 안의 static/js/office.js  →  api/OfficeApiController.java
 *
 * [4] 메서드 목록
 *     메서드          주소              돌려주는 것          흐름 번호
 *     office()        GET /office       office.html         흐름 A-②, 흐름 E-①
 *     meeting()       GET /meeting      meeting.html        흐름 A-②
 *
 * [5] 먼저 알 용어 (자세한 설명: docs/용어-풀이.md)
 *     @Controller, @GetMapping, Model
 *
 * [6] 읽는 순서
 *     office() → meeting()
 *
 * [7] 다 읽고 확인
 *     - office.html 을 처음 받았을 때 책상 위의 팀원 이름은 HTML 에 들어 있는가? (아니다. office.js 가 /api/office 응답으로 그린다)
 *     - meeting() 은 왜 Model 매개변수가 없는가? (템플릿에 넘길 값이 없다)
 */
package com.greendesk.publisher.controller;

import com.greendesk.publisher.service.ChatService;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;

/**
 * 화면용 컨트롤러: 사무실·회의실.
 * 화면 틀(과 사장실 대화 패널의 처음 내용)만 그리고,
 * 움직이는 내용은 화면의 자바스크립트가 fetch 로 /api/office, /api/meeting 을 불러 채운다.
 *
 *   GET /office   office.html   AI 출판사 사무실 (책상·실제 tmux 화면·메시지 배달·사장실 대화)
 *   GET /meeting  meeting.html  팀 회의실 (원탁·말풍선·회의록·다시 보기)
 */
// @Controller : 화면 요청을 받는 컨트롤러. 돌려주는 글자 = 템플릿 이름.
@Controller
public class OfficePageController {

    private final ChatService chatService;

    public OfficePageController(ChatService chatService) {
        this.chatService = chatService;
    }

    // [흐름 A-②] [흐름 E-①] 사무실 화면 GET /office. 빈 틀을 보내고, 움직이는 내용은 office.js 가 채운다(흐름 E-②부터).
    @GetMapping("/office")
    public String office(Model model) {
        // 사무실 오른쪽의 사장실 대화 패널에도 대화방과 같은 chatpanel.js 가 붙는다. 처음 메시지 목록을 HTML 로 넣어 둔다.
        model.addAttribute("messages", chatService.messagesAfter(0));
        model.addAttribute("online", chatService.isLeadOnline());
        // templates/office.html 을 채워 응답한다. 이 HTML 이 office.js 를 불러온다.
        return "office";
    }

    // [흐름 A-②] 회의실 화면 GET /meeting
    @GetMapping("/meeting")
    public String meeting() {
        return "meeting";
    }
}
