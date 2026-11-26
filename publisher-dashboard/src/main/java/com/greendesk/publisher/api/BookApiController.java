/*
 * [1] 역할
 *     책 목록과 책 한 권의 요약(제목, 진행 단계, 4가지 점검 결과)을 JSON 으로 응답하는 컨트롤러다.
 *     회의실 화면(meeting.js)이 "다시 볼 책" 목록을 채울 때 GET /api/books 를 호출한다.
 *
 * [2] 받는 것 → 내보내는 것 (실제로 실행해서 얻은 값)
 *     요청   GET /api/books
 *     응답   200
 *            [{"id":2,"folder":"20261109-dinosaur","title":"20261109-dinosaur","genre":"동화","stage":"기획 완료","stageIndex":1,
 *              "chapters":0,"chars":0,"members":4,"expectedMembers":4,"peerTalk":4,"reports":6,
 *              "filesMade":false,"filesDelivered":false,"checksPassed":3}, …]
 *     요청   GET /api/books/9999   (없는 번호)
 *     응답   404  {"status":404,"code":"NOT_FOUND","message":"책을 찾을 수 없어요.",…}
 *
 * [3] 앞뒤 파일
 *     static/js/meeting.js  →  (이 파일)  →  service/DashboardService.java
 *     응답 몸통의 모양: dto/BookSummaryResponse.java
 *
 * [4] 메서드 목록
 *     메서드   HTTP 방식과 주소       하는 일              성공 응답
 *     list()   GET /api/books        모든 책의 요약 목록    200
 *     one()    GET /api/books/2      2번 책의 요약          200 (없으면 404)
 *
 * [5] 먼저 알 용어
 *     @RestController, @RequestMapping, @GetMapping, @PathVariable, List, stream·map·toList
 *
 * [6] 읽는 순서
 *     list() → one()
 *
 * [7] 다 읽고 확인
 *     - list() 의 return 값은 자바의 List 다. 응답 몸통에서는 어떤 기호로 시작하는가? ( [ 로 시작하는 JSON 배열 )
 *     - GET /api/books/abc 를 보내면 one() 의 본문이 실행되는가?
 */
package com.greendesk.publisher.api;

import com.greendesk.publisher.dto.BookSummaryResponse;
import com.greendesk.publisher.service.DashboardService;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

/**
 * 책 REST API (JSON).
 *
 *   GET /api/books       200  모든 책의 요약과 4가지 점검 (최신 책이 먼저)
 *   GET /api/books/{id}  200  책 하나 / 404
 */
// return 값을 JSON 으로 응답하는 컨트롤러. (뜻·없으면: ChatApiController.java 의 같은 어노테이션 설명 참고)
@RestController
// 이 클래스의 모든 메서드 주소 앞에 /api/books 가 붙는다.
@RequestMapping("/api/books")
public class BookApiController {

    // 책 조회 작업을 실행할 서비스 객체. 자료형: DashboardService
    private final DashboardService dashboardService;

    // 생성자 주입: 스프링이 DashboardService 객체를 만들어 이 생성자에 넘겨 준다.
    public BookApiController(DashboardService dashboardService) {
        this.dashboardService = dashboardService;
    }

    // ▶ 받는 값: 없음        ▶ 돌려주는 값: List<BookSummaryResponse> → JSON 배열
    // GET /api/books 요청을 이 메서드가 처리한다.
    @GetMapping
    public List<BookSummaryResponse> list() {
        // (1) dashboardService.allBooks()            모든 책과 그 책의 점검 결과를 가져온다.   자료형: List<BookView>   예) 책 2권
        //     이때 실행되는 SQL: select b1_0.id,b1_0.chapter_count,…,b1_0.title,b1_0.updated_at from book b1_0 order by b1_0.created_at
        // (2) .stream()                              원소를 하나씩 처리할 준비를 한다.
        // (3) .map(BookSummaryResponse::from)        BookView 마다 BookSummaryResponse.from(원소) 를 실행해 응답용 객체로 바꾼다.
        // (4) .toList()                              목록으로 모은다.                          자료형: List<BookSummaryResponse>
        // (5) return                                 JSON 배열로 응답한다. 상태코드 200.       예) [{"id":2,…},{"id":1,…}]
        return dashboardService.allBooks().stream().map(BookSummaryResponse::from).toList();
    }

    // ▶ 받는 값: 주소의 책 번호   예) GET /api/books/2 → id = 2      ▶ 돌려주는 값: BookSummaryResponse → JSON 객체
    @GetMapping("/{id}")
    public BookSummaryResponse one(@PathVariable Long id) {
        // (1) dashboardService.bookOrThrow(id)       id 번 책을 찾는다. 없으면 NotFoundException 이 발생한다 → ApiExceptionHandler.notFound() → 404 [흐름 D-③]
        // (2) BookSummaryResponse.from(...)          응답용 객체로 바꾼다.
        // (3) return                                 JSON 으로 응답한다.                       예) {"id":2,"title":"20261109-dinosaur","stage":"기획 완료",…}
        return BookSummaryResponse.from(dashboardService.bookOrThrow(id));
    }
}
