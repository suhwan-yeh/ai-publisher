/*
 * [1] 역할
 *     관리 화면에서 쭌에게 보내는 길(흐름 B, C, D)을 시험한다. 진짜 fakechat 대신 같은 주소 규칙(GET / → 200, POST /upload → 204)을 가진
 *     작은 가짜 HTTP 서버를 이 시험 안에서 켠다. 시험 네 개는 @Order 순서대로 실행되며 앞 시험의 DB 상태를 이어 쓴다.
 *
 * [2] 받는 것 → 내보내는 것 (실제로 실행해서 얻은 값)
 *     확인하는 것 (실제 값)
 *       POST /order  text=고양이 나오는 짧은 동화 써 줘   → 302 → /chat,  가짜 서버가 받은 몸통에 name="text", name="id", "web-"
 *       POST /api/chat {"text":"좋아요 1번으로 해 줘"}      → 201, Location: /api/chat/{id}, {"fromBoss":true,"text":"좋아요 1번으로 해 줘",…}
 *       POST /api/chat {"text":"   "}                     → 400 {"code":"VALIDATION","message":"보낼 말을 적어 주세요."}  (가짜 서버에 가지 않음)
 *       가짜 서버를 끈 뒤 POST /api/chat {"text":"안녕"}    → 503 {"code":"LEAD_OFFLINE","message":"…출근…"}
 *       가짜 서버를 끈 뒤 POST /order                      → 302 Location: /   (flash 로 안내)
 *
 * [3] 앞뒤 파일
 *     (이 파일)의 가짜 서버  ←  client/FakechatClient.java  ←  service/ChatService.java  ←  api/ChatApiController.java, controller/ChatPageController.java
 *     (이 파일)  →  scan/TranscriptScanner.java (가짜 jsonl 을 읽힘)
 *
 * [4] 메서드 목록
 *     메서드                         확인하는 것                                            흐름 번호
 *     static { … }                   임시 폴더와 가짜 fakechat 서버를 만든다
 *     props()                        설정을 임시 폴더·가짜 서버 주소로 바꾼다
 *     orderFromHome          (1)     첫 화면 주문 → 쭌에게 전달 + book_order, chat_message 저장     흐름 C
 *     transcriptMergesAndReplies (2) 기록에 같은 메시지가 나와도 한 번만, 답장·첨부 파일 보이기        흐름 F-④, B′
 *     sendFromChat           (3)     POST /api/chat 201 + Location, 빈 글 400                     흐름 B, D-①
 *     offline                (4)     쭌이 없으면 503, 폼은 302 로 첫 화면                          흐름 D-②, C
 *
 * [5] 먼저 알 용어 (자세한 설명: docs/용어-풀이.md)
 *     @SpringBootTest, @TestMethodOrder·@Order, static 블록, HttpServer(JDK 내장), @DynamicPropertySource, @AfterAll, TestRestTemplate, ObjectMapper
 *
 * [6] 읽는 순서
 *     static { … } → props() → orderFromHome() → sendFromChat() → offline() → transcriptMergesAndReplies()
 *
 * [7] 다 읽고 확인
 *     - sendFromChat 에서 빈 글을 보낸 뒤 uploads 가 여전히 2개인 것은 무엇을 확인하는가? (@Valid 에서 막혀 쭌에게 가지 않았다)
 *     - offline 에서 java.net.http.HttpClient 를 따로 쓰는 이유는? (TestRestTemplate 은 302 를 따라가 버려 Location 을 볼 수 없다)
 */
package com.greendesk.publisher;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.greendesk.publisher.client.FakechatClient;
import com.greendesk.publisher.domain.ChatMessage;
import com.greendesk.publisher.repository.BookOrderRepository;
import com.greendesk.publisher.repository.ChatMessageRepository;
import com.greendesk.publisher.scan.TranscriptScanner;
import com.sun.net.httpserver.HttpServer;
import org.junit.jupiter.api.*;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.web.client.TestRestTemplate;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;
import org.springframework.util.LinkedMultiValueMap;

import java.io.IOException;
import java.net.InetSocketAddress;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.time.Instant;
import java.util.List;
import java.util.Map;
import java.util.concurrent.CopyOnWriteArrayList;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * 관리 화면 → 쭌(fakechat) 연결 시험.
 * 진짜 fakechat 대신, 같은 주소 규칙(GET /, POST /upload)을 가진 작은 가짜 서버를 띄운다.
 */
// @SpringBootTest(webEnvironment = RANDOM_PORT, properties = {…})
//   뜻     : 진짜 프로그램처럼 스프링 전체(컨트롤러·서비스·DB)를 켜고 시험한다. RANDOM_PORT = 비어 있는 아무 포트에 웹 서버를 연다.
//   받는 것: properties = 이 시험에서만 바꿀 설정.  jdbc:h2:mem:… = 메모리 DB(시험이 끝나면 사라짐),  scan-interval-ms=3600000 = 1시간(시험 중에 저절로 읽지 않게)
//   결과   : 시험마다 깨끗한 DB, 내 PC 의 실제 DB 파일은 건드리지 않는다.
@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT, properties = {
        "spring.datasource.url=jdbc:h2:mem:bridgetest;DB_CLOSE_DELAY=-1",
        "publisher.scan-interval-ms=3600000"
})
// @TestMethodOrder + @Order(n): 시험을 1, 2, 3, 4 순서로 실행한다. 보통 시험은 순서가 정해져 있지 않다.
@TestMethodOrder(MethodOrderer.OrderAnnotation.class)
class ChatBridgeTest {

    static HttpServer fake;
    // uploads: 가짜 서버가 받은 POST /upload 몸통 글을 모아 둔다. 웹 서버 스레드와 시험 스레드가 함께 쓰므로 CopyOnWriteArrayList.
    static final List<String> uploads = new CopyOnWriteArrayList<>();
    static Path home;

    // static 블록: 클래스가 처음 쓰일 때 한 번 실행된다. 스프링이 켜지기 전(설정을 읽기 전)에 가짜 서버 주소가 정해져야 하므로 여기서 만든다.
    static {
        try {
            // 임시 폴더. 이름은 /tmp/bridge 뒤에 매번 다른 숫자가 붙는다. 그 안에 my-publisher/books/20261109-test/dist/book.pdf 와 바깥 파일 secret.txt 를 만든다.
            home = Files.createTempDirectory("bridge");
            Files.createDirectories(home.resolve("my-publisher/books/20261109-test/dist"));
            Files.writeString(home.resolve("my-publisher/books/20261109-test/dist/book.pdf"), "%PDF-1.4 test");
            Files.writeString(home.resolve("secret.txt"), "밖의 파일");
            Files.createDirectories(home.resolve("transcripts"));
            // JDK 에 들어 있는 작은 HTTP 서버. 포트 0 = 운영체제가 비어 있는 포트를 고른다.
            fake = HttpServer.create(new InetSocketAddress("127.0.0.1", 0), 0);
            fake.createContext("/", ex -> {
                // POST /upload 이면 몸통을 uploads 에 넣고 204, 아니면(GET /) 200 "fakechat". 진짜 fakechat 과 같은 규칙이다.
                if (ex.getRequestURI().getPath().equals("/upload") && ex.getRequestMethod().equals("POST")) {
                    uploads.add(new String(ex.getRequestBody().readAllBytes(), StandardCharsets.UTF_8));
                    ex.sendResponseHeaders(204, -1);
                } else {
                    byte[] b = "fakechat".getBytes();
                    ex.sendResponseHeaders(200, b.length);
                    ex.getResponseBody().write(b);
                }
                ex.close();
            });
            fake.start();
        } catch (IOException e) {
            throw new IllegalStateException(e);
        }
    }

    @DynamicPropertySource
    static void props(DynamicPropertyRegistry r) {
        r.add("publisher.root", () -> home.resolve("my-publisher").toString());
        r.add("publisher.transcripts-dir", () -> home.resolve("transcripts").toString());
        // FakechatClient 가 진짜 8787 대신 가짜 서버로 보내게 한다. 포트 번호는 실행할 때마다 다르다.
        r.add("publisher.bridge-url", () -> "http://127.0.0.1:" + fake.getAddress().getPort());
    }

    // @AfterAll: 이 클래스의 시험이 모두 끝난 뒤 한 번. 가짜 서버를 끈다.
    @AfterAll
    static void stop() {
        fake.stop(0);
    }

    @Autowired FakechatClient bridge;
    @Autowired ChatMessageRepository chats;
    @Autowired BookOrderRepository orders;
    @Autowired TranscriptScanner scanner;
    @Autowired TestRestTemplate http;
    final ObjectMapper json = new ObjectMapper();

    @Test
    @Order(1)
    @DisplayName("첫 화면에서 주문하면 쭌에게 전달되고 주문·대화가 DB에 남는다")
    void orderFromHome() {
        assertThat(bridge.isOnline()).isTrue();
        HttpHeaders h = new HttpHeaders();
        // [흐름 C-①] 브라우저의 폼 전송과 같은 모양: Content-Type: application/x-www-form-urlencoded,  몸통 text=…
        h.setContentType(MediaType.APPLICATION_FORM_URLENCODED);
        var form = new LinkedMultiValueMap<String, String>();
        form.add("text", "고양이 나오는 짧은 동화 써 줘");
        ResponseEntity<String> r = http.postForEntity("/order", new HttpEntity<>(form, h), String.class);
        // 대화방(/chat)으로 넘어간다 (테스트 클라이언트가 이동까지 따라감)
        assertThat(r.getStatusCode().is2xxSuccessful() || r.getStatusCode().is3xxRedirection()).isTrue();
        if (r.getStatusCode().is2xxSuccessful()) assertThat(r.getBody()).contains("쭌 편집장과 대화");

        assertThat(uploads).hasSize(1);
        // 가짜 서버가 받은 multipart 몸통에 text 칸, id 칸, "web-" 로 시작하는 번호가 있어야 한다 (FakechatClient.send 가 만든 것).
        assertThat(uploads.get(0)).contains("name=\"text\"").contains("고양이 나오는 짧은 동화 써 줘").contains("name=\"id\"").contains("web-");
        assertThat(orders.findAll()).hasSize(1);
        ChatMessage sent = chats.findAll().get(0);
        assertThat(sent.getDirection()).isEqualTo(ChatMessage.Direction.FROM_BOSS);
        assertThat(sent.getChannel()).isEqualTo("web");
    }

    @Test
    @Order(2)
    @DisplayName("쭌의 기록에 같은 메시지가 나와도 두 번 저장하지 않고, 답장과 첨부 파일을 대화방에 보여 준다")
    void transcriptMergesAndReplies() throws Exception {
        ChatMessage sent = chats.findAll().get(0);
        String messageId = sent.getUniqueKey().substring("web:".length());
        Path pdf = home.resolve("my-publisher/books/20261109-test/dist/book.pdf");
        String ts = Instant.now().toString();
        // 쭌의 대화 기록 한 줄을 흉내 낸다: 사장님 말이 <channel …> 로 들어온 줄.  message_id 는 방금 관리 화면에서 보낸 번호.
        String user = json.writeValueAsString(Map.of("type", "user", "sessionId", "abcdef1234", "timestamp", ts,
                "message", Map.of("role", "user", "content",
                        "<channel source=\"fakechat\" chat_id=\"web\" message_id=\"" + messageId + "\" user=\"web\" ts=\"" + ts + "\">\n고양이 나오는 짧은 동화 써 줘\n</channel>")));
        // 쭌의 답장 줄: fakechat reply 도구 호출 + 첨부 파일 2개 (book.pdf, 출판사 폴더 밖의 secret.txt).
        String reply = json.writeValueAsString(Map.of("type", "assistant", "sessionId", "abcdef1234", "timestamp", ts,
                "message", Map.of("role", "assistant", "content", List.of(Map.of("type", "tool_use", "id", "toolu_1",
                        "name", "mcp__plugin_fakechat_fakechat__reply",
                        "input", Map.of("chat_id", "web", "text", "📕 책을 보내 드려요", "files", List.of(pdf.toString(), home.resolve("secret.txt").toString())))))));
        Files.writeString(home.resolve("transcripts/abcdef1234.jsonl"), user + "\n" + reply + "\n");
        scanner.scan();

        List<ChatMessage> all = chats.findAll();
        // 보낸 말 1개 + 답장 1개 = 2개. 보낸 말이 기록에 다시 나왔지만 새로 저장하지 않았다.
        assertThat(all).hasSize(2);
        assertThat(chats.findByUniqueKey(sent.getUniqueKey()).orElseThrow().getTeamName()).isEqualTo("session-abcdef12");
        ChatMessage answer = all.stream().filter(c -> c.getDirection() == ChatMessage.Direction.TO_BOSS).findFirst().orElseThrow();
        assertThat(answer.getChannel()).isEqualTo("web");

        Map<?, ?> poll = http.getForObject("/api/chat?after=0", Map.class);
        assertThat(poll.get("online")).isEqualTo(true);
        assertThat((List<?>) poll.get("messages")).hasSize(2);

        ResponseEntity<byte[]> file = http.getForEntity("/chat/" + answer.getId() + "/file/0", byte[].class);
        assertThat(file.getStatusCode().value()).isEqualTo(200);
        assertThat(new String(file.getBody())).startsWith("%PDF");
        // 출판사 폴더 밖 파일은 막는다
        // 두 번째 첨부(secret.txt)는 출판사 폴더 밖이다 → FileAccessDeniedException → 400 FILE_DENIED
        assertThat(http.getForEntity("/chat/" + answer.getId() + "/file/1", String.class).getStatusCode().value()).isEqualTo(400);

        String page = http.getForObject("/chat", String.class);
        assertThat(page).contains("🟢 쭌과 연결됨").contains("책을 보내 드려요").contains("⬇ book.pdf");
    }

    @Test
    @Order(3)
    @DisplayName("POST /api/chat: 201 Created + Location + 보낸 메시지, 빈 글은 400")
    void sendFromChat() {
        // [흐름 B] Map 을 넘기면 TestRestTemplate 이 JSON 으로 바꿔 보낸다.  실제 요청) POST /api/chat  {"text":"좋아요 1번으로 해 줘"}
        ResponseEntity<Map> r = http.postForEntity("/api/chat", Map.of("text", "좋아요 1번으로 해 줘"), Map.class);
        assertThat(r.getStatusCode().value()).isEqualTo(201);
        // 201 의 Location 헤더가 새 메시지 주소여야 한다.  예) /api/chat/3
        assertThat(r.getHeaders().getLocation().getPath()).isEqualTo("/api/chat/" + r.getBody().get("id"));
        assertThat(r.getBody().get("fromBoss")).isEqualTo(true);
        assertThat(r.getBody().get("text")).isEqualTo("좋아요 1번으로 해 줘");
        assertThat(uploads).hasSize(2);
        assertThat(orders.findAll()).hasSize(1); // 대화는 주문으로 세지 않는다

        // [흐름 D-①] 공백만 있는 글 → @NotBlank 실패 → 400 VALIDATION
        ResponseEntity<Map> blank = http.postForEntity("/api/chat", Map.of("text", "   "), Map.class);
        assertThat(blank.getStatusCode().value()).isEqualTo(400);
        assertThat(blank.getBody().get("code")).isEqualTo("VALIDATION");
        assertThat(blank.getBody().get("message")).isEqualTo("보낼 말을 적어 주세요.");
        assertThat(uploads).hasSize(2); // 쭌에게 가지 않았다
    }

    @Test
    @Order(4)
    @DisplayName("쭌이 출근 전이면 알려 주고 저장하지 않는다")
    void offline() throws Exception {
        long before = chats.count();
        // [흐름 D-②] 가짜 서버를 끈다 = 쭌이 퇴근한 상태.
        fake.stop(0);
        assertThat(bridge.isOnline()).isFalse();
        ResponseEntity<Map> r = http.postForEntity("/api/chat", Map.of("text", "안녕"), Map.class);
        assertThat(r.getStatusCode().value()).isEqualTo(503);
        assertThat(r.getBody().get("code")).isEqualTo("LEAD_OFFLINE");
        assertThat((String) r.getBody().get("message")).contains("출근");
        // 첫 화면 주문 폼은 오류 화면 대신 첫 화면(/)으로 돌아가 안내한다 (안내 문구는 flash 로 전달)
        // redirect 를 따라가지 않는 HTTP 도구. 302 응답과 Location 헤더를 직접 본다.
        var client = java.net.http.HttpClient.newHttpClient(); // 기본값: 이동(redirect)을 따라가지 않음
        var req = java.net.http.HttpRequest.newBuilder(java.net.URI.create(http.getRootUri() + "/order"))
                .header("Content-Type", "application/x-www-form-urlencoded")
                .POST(java.net.http.HttpRequest.BodyPublishers.ofString(
                        "text=" + java.net.URLEncoder.encode("책 하나 만들어 줘", StandardCharsets.UTF_8)))
                .build();
        var res = client.send(req, java.net.http.HttpResponse.BodyHandlers.discarding());
        assertThat(res.statusCode()).isEqualTo(302);
        assertThat(java.net.URI.create(res.headers().firstValue("Location").orElseThrow()).getPath()).isEqualTo("/");
        assertThat(orders.findAll()).hasSize(1); // 실패한 주문은 기록하지 않는다
        assertThat(chats.count()).isEqualTo(before);
        assertThat(http.getForObject("/chat", String.class)).contains("🔴 쭌이 출근 전이에요");
    }
}
