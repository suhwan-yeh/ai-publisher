/*
 * [1] 역할
 *     사무실 화면(/office)과 회의실 화면(/meeting)이 2~3초마다 호출하는 JSON API 컨트롤러다.
 *     직원별 상태, tmux 화면 글자, 직원끼리 주고받은 메시지, 직원 명부를 응답한다.
 *
 * [2] 받는 것 → 내보내는 것 (실제로 실행해서 얻은 값)
 *     요청   GET /api/office?after=0
 *     응답   200
 *            {"source":"기록","teamName":"session-2d8e941e","book":{…},
 *             "agents":[{"name":"team-lead","korean":"쭌","role":"편집장","team":"lead","status":"IDLE","statusLabel":"대기",
 *                        "activity":null,"spinner":null,"task":null,"screen":[],"lastActive":"2026-11-09T21:02:42.256Z","sent":0}, … 6명],
 *             "messages":[…],"leadWaitingPermission":false,"now":"2026-11-09T21:46:34.182509578Z"}
 *     요청   GET /api/office/status
 *     응답   200  {"tmuxAvailable":false,"leadWaitingPermission":false,"working":[]}
 *     요청   GET /api/staff
 *     응답   200  [{"name":"team-lead","korean":"쭌","role":"편집장","team":"lead","color":"#f08a5d"},
 *                  {"name":"minjun","korean":"민준","role":"기획","team":"book","color":"#5b8cff"}, …]
 *
 * [3] 앞뒤 파일
 *     static/js/office.js, meeting.js, people.js, chatpanel.js  →  (이 파일)  →  service/OfficeService.java
 *
 * [4] 메서드 목록
 *     메서드     HTTP 방식과 주소                 하는 일                                  호출하는 화면 코드     흐름 번호
 *     office()   GET /api/office?after=0         사무실 전체 상태                          office.js (2초마다)    흐름 E
 *     status()   GET /api/office/status          쭌이 허용을 기다리는지 여부                chatpanel.js (6초마다)
 *     staff()    GET /api/staff                  직원 명부                                 people.js (화면을 열 때 한 번)
 *     screen()   GET /api/office/screen/jihun    한 사람의 tmux 화면 전체                   office.js (책상을 눌렀을 때)
 *     meeting()  GET /api/meeting?after=0        회의실 메시지 (bookId 가 있으면 그 책 전체)  meeting.js (3초마다)
 *
 * [5] 먼저 알 용어
 *     @RestController, @GetMapping, @RequestParam(defaultValue, required), @PathVariable
 *
 * [6] 읽는 순서
 *     office() → status() → staff() → screen() → meeting()
 *
 * [7] 다 읽고 확인
 *     - 이 클래스에는 @RequestMapping 이 없다. 각 메서드의 전체 주소는 어디에 적혀 있는가?
 *     - meeting() 의 bookId 는 Long, after 는 long 이다. 주소에 bookId 가 없을 때 각각 어떤 값이 되는가?
 */
package com.greendesk.publisher.api;

import com.greendesk.publisher.dto.MeetingResponse;
import com.greendesk.publisher.dto.OfficeResponse;
import com.greendesk.publisher.dto.OfficeStatusResponse;
import com.greendesk.publisher.dto.ScreenResponse;
import com.greendesk.publisher.dto.StaffResponse;
import org.springframework.web.bind.annotation.PathVariable;
import com.greendesk.publisher.service.OfficeService;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

/**
 * 사무실·회의실 REST API (JSON). 사무실 화면이 2초, 회의실이 3초마다 fetch 로 부른다.
 *
 *   GET /api/office?after={id}           200  책상별 상태·tmux 화면 + 새 직원 메시지
 *   GET /api/office/status               200  쭌이 허용을 기다리는지 (대화방 알림용)
 *   GET /api/office/screen/{name}        200  한 사람의 tmux 화면 전체 (확대 보기) / 404
 *   GET /api/staff                       200  직원 명부 (staff.yml)
 *   GET /api/meeting?after={id}          200  지금 팀의 회의 (실시간)
 *   GET /api/meeting?bookId={id}         200  그 책의 회의 전체 (다시 보기) / 404
 */
// return 값을 JSON 으로 응답하는 컨트롤러. 이 클래스에는 @RequestMapping 이 없으므로 각 메서드에 전체 주소를 적는다.
@RestController
public class OfficeApiController {

    // 사무실·회의실 데이터를 만드는 서비스 객체. 자료형: OfficeService
    private final OfficeService officeService;

    // 생성자 주입: 스프링이 OfficeService 객체를 만들어 이 생성자에 넘겨 준다.
    public OfficeApiController(OfficeService officeService) {
        this.officeService = officeService;
    }

    // ────────────────────────────────────────────────────────────────────────────
    // [흐름 E] 사무실 화면이 2초마다 호출
    // ────────────────────────────────────────────────────────────────────────────
    // [흐름 E-②] office.js 의 poll() 이 보낸 GET /api/office?after=… 요청이 이 메서드로 온다.
    // ▶ 받는 값: after = 화면이 마지막으로 받은 직원 메시지 번호    예) after = 0 (처음), after = 41 (그 뒤)
    // ▶ 돌려주는 값: OfficeResponse → JSON
    @GetMapping("/api/office")
    public OfficeResponse office(@RequestParam(defaultValue = "0") long after) {
        // [흐름 E-③] OfficeService.office(after) 를 실행하고, 그 결과를 그대로 return 한다.
        // [흐름 E-⑦] return 한 OfficeResponse 객체가 JSON 으로 바뀌어 응답된다. → office.js 의 [흐름 E-⑧]
        return officeService.office(after);
    }

    // ▶ 받는 값: 없음     ▶ 돌려주는 값: OfficeStatusResponse → JSON     실제 응답: {"tmuxAvailable":false,"leadWaitingPermission":false,"working":[]}
    // chatpanel.js 가 6초마다 호출해, 쭌이 허용 질문에 멈춰 있으면 화면에 알림을 표시한다.
    @GetMapping("/api/office/status")
    public OfficeStatusResponse status() {
        return officeService.status();
    }

    // ▶ 받는 값: 없음     ▶ 돌려주는 값: List<StaffResponse> → JSON 배열
    // people.js 가 화면을 열 때 한 번 호출해 직원의 이름·역할·색을 받아 간다.
    // java.util.List 는 import 문 없이 패키지 이름까지 적은 표기다. List 와 같다.
    @GetMapping("/api/staff")
    public java.util.List<StaffResponse> staff() {
        return officeService.staff();
    }

    // ▶ 받는 값: 주소의 직원 영문 이름   예) GET /api/office/screen/jihun → name = "jihun"
    // ▶ 돌려주는 값: ScreenResponse → JSON.  그 직원의 tmux 칸이 없으면 NotFoundException → 404
    @GetMapping("/api/office/screen/{name}")
    public ScreenResponse screen(@PathVariable String name) {
        return officeService.screen(name);
    }

    // ▶ 받는 값: bookId (없어도 됨), after     ▶ 돌려주는 값: MeetingResponse → JSON
    //    예) GET /api/meeting?after=41      → bookId = null, after = 41   (지금 팀의 새 메시지)
    //    예) GET /api/meeting?bookId=2      → bookId = 2,    after = 0    (2번 책의 회의 전체: 다시 보기)
    @GetMapping("/api/meeting")
    // @RequestParam(required = false) Long bookId
    //   뜻     : 주소에 bookId 가 없어도 오류로 처리하지 않는다. 없으면 bookId = null.
    //   Long 과 long 의 차이: Long 은 null 을 담을 수 있고, long 은 담을 수 없다. 그래서 "없음"을 나타내야 하는 bookId 는 Long 이다.
    //   required = false 가 없으면: 주소에 bookId 가 없을 때 400 이 응답된다.
    public MeetingResponse meeting(@RequestParam(required = false) Long bookId,
                                   @RequestParam(defaultValue = "0") long after) {
        return officeService.meeting(bookId, after);
    }
}
