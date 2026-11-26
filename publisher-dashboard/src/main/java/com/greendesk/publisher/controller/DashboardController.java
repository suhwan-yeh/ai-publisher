/*
 * [1] 역할
 *     주소창·링크·폼으로 들어온 요청을 받아 HTML 화면을 돌려주는 컨트롤러다. (첫 화면, 책 상세, 직원 현황)
 *     메서드는 템플릿 이름(글자)을 돌려준다. 스프링이 templates/그이름.html 을 타임리프로 채워 HTML 로 응답한다.
 *     JSON 을 돌려주는 api/BookApiController 와 같은 정보를 쓰지만, 이 클래스는 화면을, 그 클래스는 데이터를 돌려준다.
 *
 * [2] 받는 것 → 내보내는 것 (실제로 실행해서 얻은 값)
 *     요청   GET / HTTP/1.1
 *            Host: localhost:8080
 *     응답   HTTP/1.1 200
 *            Content-Type: text/html;charset=UTF-8
 *
 *            <!doctype html>
 *            <html lang="ko">
 *            … (index.html 에 책 5권 목록이 채워진 HTML)
 *     이 요청 하나에 실행된 SQL 중 하나:
 *            select b1_0.id,…,b1_0.title,b1_0.updated_at from book b1_0 order by b1_0.created_at
 *
 * [3] 앞뒤 파일
 *     브라우저  →  (이 파일)  →  service/DashboardService.java  →  repository/*  →  DB
 *                (이 파일)  →  templates/index.html, book.html, team.html  →  HTML 응답
 *     파일 내려받기 응답 만들기: controller/FileResponses.java
 *
 * [4] 메서드 목록
 *     메서드          주소                          돌려주는 것                       흐름 번호
 *     index()         GET  /                        index.html (첫 화면)              흐름 A-②
 *     book()          GET  /books/{id}              book.html  (책 상세)              흐름 A-②, 없는 번호면 흐름 D-③
 *     team()          GET  /team                    team.html  (직원 현황)            흐름 A-②
 *     rescan()        POST /rescan                  redirect:/  → 302                흐름 C
 *     download()      GET  /download/{id}/{kind}    파일 바이트 (PDF·EPUB·HTML·표지)
 *
 * [5] 먼저 알 용어 (자세한 설명: docs/용어-풀이.md)
 *     @Controller, @GetMapping, @PostMapping, @PathVariable, Model, redirect:, ResponseEntity, 생성자 주입, var
 *
 * [6] 읽는 순서
 *     생성자 → index() → book() → team() → rescan() → download()
 *
 * [7] 다 읽고 확인
 *     - index() 가 "index" 대신 "home" 을 돌려주면 어떤 오류가 나는가? (templates/home.html 이 없어 500)
 *     - /books/999 를 열면 어느 클래스가 404 화면을 만드는가? (DashboardService.bookOrThrow 가 NotFoundException → ApiExceptionHandler)
 */
package com.greendesk.publisher.controller;

import com.greendesk.publisher.service.BookView;
import com.greendesk.publisher.service.DashboardService;
import com.greendesk.publisher.service.ScanService;
import org.springframework.core.io.FileSystemResource;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;

import java.time.Duration;

/**
 * 화면용 컨트롤러: 책 목록·책 상세·직원 현황 (Thymeleaf 뷰 이름을 돌려줌)
 *
 *   GET  /                      index.html  첫 화면 (주문 칸 + 책 목록)
 *   GET  /books/{id}            book.html   책 상세
 *   GET  /team                  team.html   직원 현황
 *   POST /rescan                → redirect:/  지금 다시 읽기
 *   GET  /download/{id}/{kind}  파일 내려받기 (pdf·epub·html·cover)
 */
// @Controller
//   뜻     : 이 클래스가 화면 요청을 받는 컨트롤러임을 스프링에 알린다.
//   결과   : 메서드가 돌려주는 글자를 "템플릿 이름"으로 본다.  "index" → templates/index.html 을 채워 HTML 로 응답한다.
//   없으면 : 스프링이 이 클래스를 모른다. GET / 이 404 가 된다.
//   비교   : @RestController 는 돌려주는 값을 JSON 으로 바꾼다 (api 패키지).
@Controller
public class DashboardController {

    // 화면에 보일 값을 모으는 서비스. 컨트롤러는 Repository 를 직접 부르지 않고 서비스를 부른다.
    private final DashboardService dashboardService;
    private final ScanService scanService;

    // 생성자 주입: 스프링이 DashboardService, ScanService 객체를 만들어 이 생성자에 넣는다. new 로 직접 만들지 않는다.
    public DashboardController(DashboardService dashboardService, ScanService scanService) {
        this.dashboardService = dashboardService;
        this.scanService = scanService;
    }

    // [흐름 A-②] 첫 화면
    // @GetMapping("/")
    //   뜻     : GET 방식으로 주소 "/" 에 온 요청을 이 메서드가 받는다.
    //   받는 것: 주소창에 http://localhost:8080/ 을 치거나 링크 <a href="/"> 를 누른 요청
    //   결과   : index() 가 실행된다.
    @GetMapping("/")
    // Model model
    //   뜻     : 컨트롤러가 템플릿(HTML)에 넘길 값을 담는 객체. 스프링이 만들어 매개변수로 넣어 준다.
    //   결과   : model.addAttribute("이름", 값) 으로 넣은 값을 템플릿에서 ${이름} 으로 꺼낸다.
    public String index(Model model) {
        // var: 오른쪽 값의 자료형을 컴파일러가 알아서 정한다. 여기서는 DashboardService.SetupStatus 레코드.
        // setup 예) root=/root/my-publisher, transcriptsFound=true, booksFound=true
        var setup = dashboardService.setupStatus();
        // (1) dashboardService.allBooks()   책 목록 List<BookView>.  SQL: select … from book b1_0 order by b1_0.created_at
        // (2) model.addAttribute("books", …) 템플릿에서 ${books} 로 쓴다.  index.html 의 th:each="b : ${books}" 가 책 5권을 줄마다 그린다.
        model.addAttribute("books", dashboardService.allBooks());
        // 최근 2분 안에 기록이 남은 팀원 목록. (Duration.ofMinutes(2) = 2분 길이)
        model.addAttribute("active", dashboardService.activeMembers(Duration.ofMinutes(2)));
        model.addAttribute("root", setup.root());
        model.addAttribute("transcripts", setup.transcripts());
        model.addAttribute("transcriptsFound", setup.transcriptsFound());
        model.addAttribute("booksFound", setup.booksFound());
        // [흐름 A-③] 템플릿 이름을 돌려준다.
        // 스프링이 (1) templates/index.html 을 찾고 (2) model 의 값을 ${…} 자리에 넣어 (3) 완성된 HTML 을 200 으로 응답한다.
        return "index";
    }

    // [흐름 A-②] 책 상세
    // @GetMapping("/books/{id}") : {id} 는 주소의 바뀌는 부분.  예) GET /books/3 → id 자리에 "3"
    @GetMapping("/books/{id}")
    // @PathVariable Long id
    //   뜻     : 주소의 {id} 부분을 꺼내 매개변수에 넣는다. 글자 "3" 을 Long 3 으로 바꿔 준다.
    //   받는 것: GET /books/3
    //   결과   : id = 3
    //   /books/abc 처럼 숫자가 아니면 바꾸지 못해 400 이 된다.
    public String book(@PathVariable Long id, Model model) {
        // id 로 책을 찾는다. 없으면 NotFoundException 이 던져지고 이 메서드는 여기서 끝난다 → 404 (흐름 D-③).
        // v 예) folder="20261109-dogwalk", title="꼬리 살랑, 첫 산책", stage=DONE
        BookView v = dashboardService.bookOrThrow(id);
        model.addAttribute("v", v);
        // 원고 장마다 앞부분 미리 보기 목록. book.html 이 장마다 한 칸씩 그린다.
        model.addAttribute("chapters", dashboardService.chapters(v));
        return "book";
    }

    // [흐름 A-②] 직원 현황 GET /team
    @GetMapping("/team")
    public String team(Model model) {
        model.addAttribute("active", dashboardService.activeMembers(Duration.ofMinutes(2)));
        model.addAttribute("members", dashboardService.allMembers());
        return "team";
    }

    /** 지금 바로 다시 읽기 (10초를 기다리지 않고) */
    // [흐름 C] "지금 다시 읽기" 버튼 (index.html 의 <form method="post" action="/rescan">)
    // @PostMapping("/rescan") : POST 방식으로 /rescan 에 온 요청을 받는다.
    @PostMapping("/rescan")
    public String rescan() {
        // 10초를 기다리지 않고 책 폴더와 기록을 바로 읽는다(흐름 F 를 지금 한 번 실행).
        scanService.scanNow();
        // "redirect:" 로 시작하면 템플릿 이름이 아니다. 브라우저에게 다른 주소로 다시 요청하라고 응답한다.
        // 실제 응답) HTTP/1.1 302   Location: http://localhost:8080/   (몸통 없음)
        // 브라우저는 이 응답을 받고 GET / 을 새로 보낸다 → index() → 첫 화면.
        // 없으면(그냥 "index" 를 돌려주면): 화면은 보이지만 주소창이 /rescan 으로 남고, 새로고침하면 POST 가 다시 전송된다.
        return "redirect:/";
    }

    /** 완성 파일 내려받기 — 정해진 파일(PDF·EPUB·HTML·표지)만 */
    // 완성 파일 내려받기.  예) GET /download/3/pdf → 20261109-dogwalk/dist/book.pdf (389934바이트) 를 "꼬리 살랑, 첫 산책.pdf" 이름으로
    @GetMapping("/download/{id}/{kind}")
    // ResponseEntity<FileSystemResource>
    //   뜻     : 상태코드·헤더·몸통을 직접 정한 응답. 몸통은 디스크의 파일(FileSystemResource)이다.
    //   @PathVariable 두 개: id=3, kind="pdf"
    public ResponseEntity<FileSystemResource> download(@PathVariable Long id, @PathVariable String kind) {
        // (1) dashboardService.download(3, "pdf")  어떤 파일을 보낼지 정한다 → DownloadFile(경로, "꼬리 살랑, 첫 산책.pdf", "application/pdf", false)
        //                                          정해진 종류가 아니면 404, 폴더 밖 경로면 400(FILE_DENIED).
        // (2) FileResponses.of(…)                  200 + Content-Type + Content-Disposition 헤더 + 파일 바이트
        return FileResponses.of(dashboardService.download(id, kind));
    }
}
