/*
 * [1] 역할
 *     관리 화면 전체를 켜고, 실제 시험 기록(src/test/resources/fixture)을 읽혀 화면·API·점검 네 가지가 맞는지 확인하는 통합 시험이다.
 *     fixture 에는 책 한 권(20261109-sea-kitten)과, 그 책을 만든 팀(session-ad6f13d3)·중간에 멈춘 팀(session-18ecadb0)의 대화 기록이 있다.
 *
 * [2] 받는 것 → 내보내는 것 (실제로 실행해서 얻은 값)
 *     받는 것 : fixture/my-publisher/books/20261109-sea-kitten,  fixture/transcripts/*.jsonl
 *     확인하는 것 (실제 값)
 *       제목 "바다를 건너는 아기 고양이", 장 3개, 단계 DONE
 *       GET /api/books           → 200, application/json, [{"title":"바다를 건너는 아기 고양이","members":4,"checksPassed":4,"filesDelivered":true,…}]
 *       GET /api/books/9999      → 404 {"status":404,"code":"NOT_FOUND","message":…,"timestamp":…}
 *       GET /api/books/abc       → 400 {"code":"BAD_REQUEST",…}
 *       GET /download/{id}/pdf   → 200, 몸통이 "%PDF" 로 시작      GET /download/{id}/secret → 404
 *     실행: ./gradlew test   (결과 보고서: build/reports/tests/test/index.html)
 *
 * [3] 앞뒤 파일
 *     (이 파일)  →  scan/BookScanner.java, scan/TranscriptScanner.java (직접 부름)
 *     (이 파일)  →  TestRestTemplate 으로 진짜 HTTP 요청  →  controller/*, api/*  (흐름 A, D)
 *     fixture 경로: FixturePaths.java
 *
 * [4] 메서드 목록
 *     메서드                         확인하는 것                                          흐름 번호
 *     scan()  (@BeforeEach)          시험마다 먼저 책 폴더·기록을 읽는다                     흐름 F
 *     readsBookFolder                제목·장 수·단계·완성 파일
 *     check1 ~ check4                점검 ① 팀원 ② 직원끼리 ③ 보고 ④ 파일 도착
 *     bossMessages                   사장님 주문 글이 저장됐다
 *     otherSessionExcluded           다른 팀의 기록이 이 책에 섞이지 않는다
 *     idempotent                     다시 읽어도 두 번 저장하지 않는다
 *     webPages                       화면·내려받기, 없는 파일 404                            흐름 A, D-③
 *     restApiContract                API 상태코드 200/404/400 과 오류 JSON 모양              흐름 D
 *
 * [5] 먼저 알 용어 (자세한 설명: docs/용어-풀이.md)
 *     @SpringBootTest, RANDOM_PORT, @DynamicPropertySource, @Autowired(필드 주입), @BeforeEach, @Test, @DisplayName, TestRestTemplate, assertThat(AssertJ)
 *
 * [6] 읽는 순서
 *     클래스 위 @SpringBootTest → paths() → scan() → readsBookFolder() → restApiContract()
 *
 * [7] 다 읽고 확인
 *     - @BeforeEach 를 지우면 readsBookFolder 는 어떻게 되는가? (DB 가 비어 hasSize(1) 에서 실패)
 *     - 이 시험이 내 PC 의 ~/.publisher-dashboard/db 파일을 바꾸는가? (아니다. jdbc:h2:mem 메모리 DB)
 */
package com.greendesk.publisher;

import com.greendesk.publisher.domain.ChatMessage;
import com.greendesk.publisher.domain.Stage;
import com.greendesk.publisher.domain.TeamMember;
import com.greendesk.publisher.repository.BookSessionRepository;
import com.greendesk.publisher.repository.ChatMessageRepository;
import com.greendesk.publisher.scan.BookScanner;
import com.greendesk.publisher.scan.TranscriptScanner;
import com.greendesk.publisher.service.BookView;
import com.greendesk.publisher.service.DashboardService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.web.client.TestRestTemplate;
import org.springframework.http.ResponseEntity;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;

import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * 실제 시험 기록으로 4가지 점검을 확인한다.
 * 기록에는 이번 책을 만든 팀(session-ad6f13d3)과, 중간에 멈춘 이전 팀(session-18ecadb0)의 기록이 함께 있다.
 */
// @SpringBootTest(webEnvironment = RANDOM_PORT, properties = {…})
//   뜻     : 진짜 프로그램처럼 스프링 전체(컨트롤러·서비스·DB)를 켜고 시험한다. RANDOM_PORT = 비어 있는 아무 포트에 웹 서버를 연다.
//   받는 것: properties = 이 시험에서만 바꿀 설정.  jdbc:h2:mem:… = 메모리 DB(시험이 끝나면 사라짐),  scan-interval-ms=3600000 = 1시간(시험 중에 저절로 읽지 않게)
//   결과   : 시험마다 깨끗한 DB, 내 PC 의 실제 DB 파일은 건드리지 않는다.
@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT, properties = {
        "spring.datasource.url=jdbc:h2:mem:dashtest;DB_CLOSE_DELAY=-1",
        "publisher.scan-interval-ms=3600000"
})
class DashboardIntegrationTest {

    // @DynamicPropertySource
    //   뜻     : 시험이 시작할 때 계산한 값으로 설정을 넣는다. (위 properties 는 글자만 쓸 수 있고, 여기서는 경로를 계산할 수 있다)
    // 결과: publisher.root = …/build/resources/test/fixture/my-publisher
    @DynamicPropertySource
    static void paths(DynamicPropertyRegistry r) {
        r.add("publisher.root", () -> FixturePaths.publisher().toString());
        r.add("publisher.transcripts-dir", () -> FixturePaths.transcripts().toString());
    }

    // @Autowired
    //   뜻     : 스프링이 만든 객체를 이 필드에 넣어 준다. 시험 클래스는 생성자 주입 대신 이렇게 쓴다.
    @Autowired BookScanner bookScanner;
    @Autowired TranscriptScanner transcriptScanner;
    @Autowired DashboardService service;
    @Autowired ChatMessageRepository chats;
    @Autowired BookSessionRepository bookSessions;
    // TestRestTemplate
    //   뜻     : 시험용 HTTP 요청 도구. RANDOM_PORT 로 켠 서버 주소가 미리 들어 있다.
    //   결과   : http.getForEntity("/api/books", List.class) → 실제로 GET http://localhost:임의포트/api/books 를 보내고 응답을 받는다.
    @Autowired TestRestTemplate http;

    // @BeforeEach: 각 @Test 메서드를 실행하기 직전마다 이 메서드를 먼저 실행한다.
    @BeforeEach
    void scan() {
        bookScanner.scan();
        transcriptScanner.scan();
    }

    private BookView theBook() {
        List<BookView> all = service.allBooks();
        // assertThat(실제 값).hasSize(1)
        //   뜻     : "실제 값이 이래야 한다"를 확인한다. 아니면 시험이 실패하고 무엇이 달랐는지 보여 준다.
        assertThat(all).hasSize(1);
        return all.get(0);
    }

    @Test
    // @Test        : 이 메서드가 시험 하나다.  ./gradlew test 가 찾아 실행한다.
    // @DisplayName : 보고서에 보일 한글 이름.
    @DisplayName("책 폴더에서 제목·장르·단계·완성 파일을 읽는다")
    void readsBookFolder() {
        BookView v = theBook();
        assertThat(v.book().getFolder()).isEqualTo("20261109-sea-kitten");
        assertThat(v.book().getTitle()).isEqualTo("바다를 건너는 아기 고양이");
        assertThat(v.book().getChapterCount()).isEqualTo(3);
        assertThat(v.book().getStage()).isEqualTo(Stage.DONE);
        assertThat(v.filesMade()).isTrue();
    }

    @Test
    @DisplayName("① 팀원 4명이 자동으로 생겼다")
    void check1_membersCreated() {
        BookView v = theBook();
        // extracting(TeamMember::getName): 목록에서 이름만 뽑는다.  → ["minjun","jihun","seoyeon","taeyang"] (순서 상관없이 같아야 한다)
        assertThat(v.members()).extracting(TeamMember::getName)
                .containsExactlyInAnyOrder("minjun", "jihun", "seoyeon", "taeyang");
        assertThat(v.check1()).isTrue();
    }

    @Test
    @DisplayName("② 팀원끼리 직접 메시지를 주고받았다 (예: 민준 → 지훈)")
    void check2_peerMessages() {
        BookView v = theBook();
        assertThat(v.peerTalkCount()).isGreaterThan(0);
        // anyMatch(조건): 하나라도 조건에 맞으면 통과.  여기서는 "민준 → 지훈 직원끼리 메시지가 있다"
        assertThat(v.teamMessages()).anyMatch(m -> m.isPeerTalk() && m.getFromName().equals("minjun") && m.getToName().equals("jihun"));
        assertThat(v.check2()).isTrue();
    }

    @Test
    @DisplayName("③ 보고가 왔다 (직원→쭌 [보고], 쭌→사장님 [제안]/[최종 보고])")
    void check3_reports() {
        BookView v = theBook();
        assertThat(v.reportCount()).isGreaterThan(0);
        assertThat(v.chat()).anyMatch(c -> c.getText().contains("[최종 보고]"));
        assertThat(v.check3()).isTrue();
    }

    @Test
    @DisplayName("④ 동의 뒤 PDF·EPUB 파일이 사장님께 갔다")
    void check4_filesDelivered() {
        BookView v = theBook();
        assertThat(v.chat()).anyMatch(c -> c.getDirection() == ChatMessage.Direction.TO_BOSS
                && c.getAttachments() != null && c.getAttachments().contains("book.pdf"));
        assertThat(v.chat()).anyMatch(c -> c.getAttachments() != null && c.getAttachments().contains("book.epub"));
        assertThat(v.check4()).isTrue();
    }

    @Test
    @DisplayName("사장님의 평소 말투 주문이 기록된다")
    void bossMessages() {
        BookView v = theBook();
        assertThat(v.chat()).anyMatch(c -> c.getDirection() == ChatMessage.Direction.FROM_BOSS
                && c.getText().contains("바다를 건너는 아기 고양이 동화"));
    }

    @Test
    @DisplayName("중간에 멈춘 다른 팀의 기록은 이 책에 섞이지 않는다")
    void otherSessionExcluded() {
        BookView v = theBook();
        assertThat(bookSessions.findByFolder("20261109-sea-kitten")).extracting(s -> s.getTeamName()).contains("session-ad6f13d3");
        // "몽이"는 중간에 멈춘 다른 팀(session-18ecadb0)의 책 제목에 나오는 이름이다. 이 책의 대화에 섞이면 안 된다.
        assertThat(v.chat()).noneMatch(c -> c.getText().contains("몽이"));
        assertThat(v.members()).allMatch(m -> m.getTeamName().equals("session-ad6f13d3"));
    }

    @Test
    @DisplayName("다시 읽어도 같은 기록이 두 번 저장되지 않는다")
    void idempotent() {
        // chats.count() SQL: select count(*) from chat_message
        // 같은 기록을 한 번 더 읽어도 개수가 같아야 한다 (TranscriptScanner 의 existsByUniqueKey 검사).
        long before = chats.count();
        transcriptScanner.scan();
        bookScanner.scan();
        assertThat(chats.count()).isEqualTo(before);
    }

    @Test
    @DisplayName("화면과 다운로드가 열린다 · 정해진 파일 말고는 내려받을 수 없다")
    void webPages() {
        Long id = theBook().book().getId();
        // [흐름 A] GET / 의 HTML 글자에 이 두 글이 들어 있어야 한다.
        assertThat(http.getForEntity("/", String.class).getBody()).contains("④ 파일 도착", "바다를 건너는 아기 고양이");
        assertThat(http.getForEntity("/books/" + id, String.class).getBody()).contains("직원들끼리 주고받은 말");
        assertThat(http.getForEntity("/team", String.class).getStatusCode().is2xxSuccessful()).isTrue();
        ResponseEntity<byte[]> pdf = http.getForEntity("/download/" + id + "/pdf", byte[].class);
        assertThat(pdf.getStatusCode().is2xxSuccessful()).isTrue();
        // PDF 파일은 늘 "%PDF" 로 시작한다. 진짜 파일 바이트가 왔는지 본다.
        assertThat(new String(pdf.getBody())).startsWith("%PDF");
        // [흐름 D-③] 정해진 종류(pdf, epub, html, cover)가 아니면 404
        assertThat(http.getForEntity("/download/" + id + "/secret", String.class).getStatusCode().value()).isEqualTo(404);
        assertThat(http.getForEntity("/books/9999", String.class).getStatusCode().value()).isEqualTo(404);
    }

    @Test
    @DisplayName("REST API: GET /api/books 200, 없는 책 404, 잘못된 id 400 — 오류는 모두 ErrorResponse 모양")
    void restApiContract() {
        Long id = theBook().book().getId();
        // JSON 배열 응답을 자바 List 로 받는다. 항목 하나하나는 Map(이름 → 값).
        ResponseEntity<java.util.List> list = http.getForEntity("/api/books", java.util.List.class);
        assertThat(list.getStatusCode().value()).isEqualTo(200);
        assertThat(list.getHeaders().getContentType().toString()).startsWith("application/json");
        java.util.Map<?, ?> first = (java.util.Map<?, ?>) list.getBody().get(0);
        assertThat(first.get("title")).isEqualTo("바다를 건너는 아기 고양이");
        assertThat(first.get("members")).isEqualTo(4);
        assertThat(first.get("checksPassed")).isEqualTo(4);
        assertThat(first.get("filesDelivered")).isEqualTo(true);

        ResponseEntity<java.util.Map> one = http.getForEntity("/api/books/" + id, java.util.Map.class);
        assertThat(one.getStatusCode().value()).isEqualTo(200);
        assertThat(one.getBody().get("stage")).isEqualTo("전자책 완성");

        ResponseEntity<java.util.Map> missing = http.getForEntity("/api/books/9999", java.util.Map.class);
        assertThat(missing.getStatusCode().value()).isEqualTo(404);
        // [흐름 D] 오류는 모두 ErrorResponse 모양 {status, code, message, timestamp} 이어야 한다.
        assertThat(missing.getBody()).containsKeys("status", "code", "message", "timestamp");
        assertThat(missing.getBody().get("code")).isEqualTo("NOT_FOUND");

        // "abc" 는 Long 으로 바꿀 수 없다 → MethodArgumentTypeMismatchException → 400 BAD_REQUEST
        ResponseEntity<java.util.Map> bad = http.getForEntity("/api/books/abc", java.util.Map.class);
        assertThat(bad.getStatusCode().value()).isEqualTo(400);
        assertThat(bad.getBody().get("code")).isEqualTo("BAD_REQUEST");

        ResponseEntity<java.util.Map> noMsg = http.getForEntity("/api/chat/999999", java.util.Map.class);
        assertThat(noMsg.getStatusCode().value()).isEqualTo(404);
    }
}
