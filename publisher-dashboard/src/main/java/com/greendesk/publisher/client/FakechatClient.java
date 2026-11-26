/*
 * [1] 역할
 *     관리 화면(스프링)에서 쭌(Claude Code)에게 HTTP 로 메시지를 보내는 클래스다.
 *     쭌은 출근할 때 공식 채널 플러그인 fakechat 을 켜고, fakechat 은 이 PC 안에서만 접속되는 작은 웹 서버(127.0.0.1:8787)를 연다.
 *     이 클래스가 그 서버의 /upload 주소로 POST 하면, fakechat 이 그 글을 쭌의 Claude Code 세션에 채널 메시지로 넣는다.
 *     DB 작업은 하지 않는다. 저장은 ChatService 가 한다.
 *
 * [2] 받는 것 → 내보내는 것 (실제로 실행해서 얻은 값)
 *     send("web-1762724793776-a1b2c3", "좋아요, 이대로 진행해 주세요.") 가 보내는 실제 HTTP 요청:
 *       POST http://127.0.0.1:8787/upload
 *       Content-Type: multipart/form-data; boundary=----publisher3f2a…
 *       몸통:
 *         ------publisher3f2a…
 *         Content-Disposition: form-data; name="id"
 *         Content-Type: text/plain; charset=UTF-8
 *
 *         web-1762724793776-a1b2c3
 *         ------publisher3f2a…
 *         Content-Disposition: form-data; name="text"
 *         Content-Type: text/plain; charset=UTF-8
 *
 *         좋아요, 이대로 진행해 주세요.
 *         ------publisher3f2a…--
 *       응답: 204 (성공)          연결 실패: ChannelUnavailableException → 503
 *
 * [3] 앞뒤 파일
 *     service/ChatService.java  →  (이 파일)  →  fakechat 서버(127.0.0.1:8787)  →  쭌(Claude Code)
 *     실패할 때 던지는 예외: client/ChannelUnavailableException.java
 *
 * [4] 메서드 목록
 *     메서드                하는 일                                              흐름 번호
 *     newMessageId()        메시지 고유 번호를 만든다          예) "web-1762724793776-a1b2c3"
 *     chatKey(번호)          DB 에 쓸 키를 만든다              예) "web:web-1762724793776-a1b2c3"
 *     isOnline()            GET / 를 보내 200 이면 true
 *     send(번호, 글)         POST /upload 로 쭌에게 전달                             흐름 B-③
 *     part(…)               multipart 몸통의 한 부분을 만든다
 *
 * [5] 먼저 알 용어 (자세한 설명: docs/용어-풀이.md)
 *     @Component, @Value, HttpClient·HttpRequest·HttpResponse, multipart/form-data, try-catch, throw
 *
 * [6] 읽는 순서
 *     생성자 → isOnline() → send() → part()
 *
 * [7] 다 읽고 확인
 *     - 쭌이 출근하지 않아 8787 포트에 아무도 없으면 send() 의 어느 줄에서 예외가 나는가?
 *     - fakechat 이 500 을 응답하면 예외 문장은 무엇이 되는가?
 */
package com.greendesk.publisher.client;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import java.io.ByteArrayOutputStream;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.nio.charset.StandardCharsets;
import java.time.Duration;
import java.util.UUID;

/**
 * 외부 연결 클라이언트: 관리 화면 → 쭌 편집장.
 *
 * 쭌(Claude Code)은 공식 채널 플러그인 fakechat 을 켜 두고 있다(출근 스크립트가 켬).
 * fakechat 은 PC 안에서만 열리는 작은 서버(기본 127.0.0.1:8787)이고,
 *   POST /upload (id, text)  → 쭌에게 <channel source="fakechat"> 메시지로 전달된다.
 * 이 클래스는 HTTP 통신만 맡는다. DB 저장은 ChatService 가 한다.
 */
// @Component
//   뜻     : 스프링이 이 클래스의 객체를 하나 만들어 관리한다(@Service 와 같은 기능, 이름만 다르다). 외부 연결을 맡는 클래스에 쓴다.
//   결과   : ChatService 생성자에 이 객체가 자동으로 넘어간다.
@Component
public class FakechatClient {

    /** 관리 화면에서 보낸 메시지 id 앞머리 (대화 기록에서 같은 메시지를 알아보는 데 씀) */
    // 관리 화면에서 보낸 메시지 번호의 앞머리. TranscriptScanner 가 대화 기록에서 이 앞머리를 보고 "관리 화면에서 보낸 메시지"임을 알아본다.
    public static final String ID_PREFIX = "web-";
    // Logger: 프로그램 실행 중의 일을 콘솔(로그)에 기록하는 객체.
    private static final Logger log = LoggerFactory.getLogger(FakechatClient.class);

    private final String baseUrl;
    private final String offlineMessage;
    // HttpClient: 자바에 들어 있는 HTTP 요청 도구. connectTimeout(2초) = 2초 안에 연결이 안 되면 실패로 처리한다.
    private final HttpClient http = HttpClient.newBuilder().connectTimeout(Duration.ofSeconds(2)).build();

    // @Value("${publisher.bridge-url:http://127.0.0.1:8787}")
    //   뜻     : application.yml 의 publisher.bridge-url 값을 매개변수에 넣는다. 설정이 없으면 콜론(:) 뒤의 값을 쓴다.
    //   결과   : baseUrl = "http://127.0.0.1:8787"
    // 두 번째 @Value 는 쭌과 연결되지 않을 때 보여 줄 문장이다. 서버(prod) 설정에서는 다른 문장으로 바뀐다.
    public FakechatClient(@Value("${publisher.bridge-url:http://127.0.0.1:8787}") String baseUrl,
                          @Value("${publisher.offline-message:쭌이 출근 전이에요. 우분투 창에서 '출근'을 입력한 뒤 다시 보내 주세요.}") String offlineMessage) {
        this.offlineMessage = offlineMessage;
        // 주소 끝에 / 가 있으면 지운다. 뒤에서 "/upload" 를 붙일 때 // 가 되지 않게 하려고.
        this.baseUrl = baseUrl.endsWith("/") ? baseUrl.substring(0, baseUrl.length() - 1) : baseUrl;
    }

    /** DB에 저장할 때 쓰는 고유 키 */
    public static String chatKey(String messageId) {
        // 예) "web-1762724793776-a1b2c3" → "web:web-1762724793776-a1b2c3"
        return "web:" + messageId;
    }

    public static String newMessageId() {
        // "web-" + 지금 시각(밀리초) + "-" + 무작위 글자 6개.   예) "web-1762724793776-a1b2c3"
        // UUID.randomUUID() = 겹칠 가능성이 거의 없는 무작위 번호.
        return ID_PREFIX + System.currentTimeMillis() + "-" + UUID.randomUUID().toString().substring(0, 6);
    }

    /** 쭌이 출근해 있어 메시지를 받을 수 있나 */
    public boolean isOnline() {
        try {
            // 보낼 요청을 만든다: GET http://127.0.0.1:8787/  (2초 안에 응답이 없으면 실패)
            HttpRequest req = HttpRequest.newBuilder(URI.create(baseUrl + "/")).timeout(Duration.ofSeconds(2)).GET().build();
            // (1) http.send(req, …)        요청을 보내고 응답을 기다린다. discarding() = 응답 몸통은 읽지 않고 버린다.
            // (2) .statusCode() == 200     상태코드가 200 이면 true.
            // 연결 자체가 안 되면 예외 → 아래 catch → false.
            return http.send(req, HttpResponse.BodyHandlers.discarding()).statusCode() == 200;
        } catch (Exception e) {
            return false;
        }
    }

    /** 쭌에게 보낸다. 실패하면 ChannelUnavailableException */
    public void send(String messageId, String text) {
        // multipart 몸통에서 부분과 부분을 나누는 구분 글자. 내용에 나올 리 없는 무작위 글자로 만든다.
        // 예) "----publisher3f2a9c…"
        String boundary = "----publisher" + UUID.randomUUID().toString().replace("-", "");
        // 요청 몸통을 바이트로 차례로 써 넣을 그릇. (ByteArrayOutputStream: 메모리에 바이트를 이어 쓰는 클래스)
        ByteArrayOutputStream body = new ByteArrayOutputStream();
        // form 값 id 를 몸통에 쓴다.
        part(body, boundary, "id", messageId);
        // form 값 text 를 몸통에 쓴다.
        part(body, boundary, "text", text);
        // 몸통의 끝 표시: --구분글자-- (\r\n = 줄바꿈)
        body.writeBytes(("--" + boundary + "--\r\n").getBytes(StandardCharsets.UTF_8));
        // 보낼 요청을 만든다 (아래 다섯 줄)
        //   주소       : http://127.0.0.1:8787/upload
        //   timeout    : 5초
        //   헤더       : Content-Type: multipart/form-data; boundary=구분글자  (fakechat 서버가 form 값을 읽을 수 있게)
        //   POST(…)    : 위에서 만든 몸통 바이트
        HttpRequest req = HttpRequest.newBuilder(URI.create(baseUrl + "/upload"))
                .timeout(Duration.ofSeconds(5))
                .header("Content-Type", "multipart/form-data; boundary=" + boundary)
                .POST(HttpRequest.BodyPublishers.ofByteArray(body.toByteArray()))
                .build();
        int code;
        try {
            // 요청을 보내고 상태코드만 받는다.   예) 204
            code = http.send(req, HttpResponse.BodyHandlers.discarding()).statusCode();
        } catch (Exception e) {
            log.info("쭌에게 전달 실패: {}", e.toString());
            // 연결이 안 되면(쭌이 출근 전) 예외를 던진다 → ChatService → ChatApiController → ApiExceptionHandler.offline() → 503 [흐름 D-②]
            throw new ChannelUnavailableException(offlineMessage);
        }
        // 상태코드가 200번대(200~299)가 아니면 실패.   code / 100 = 백의 자리 숫자.   예) 204 / 100 = 2
        if (code / 100 != 2) {
            throw new ChannelUnavailableException("쭌에게 전달하지 못했어요 (응답 " + code + ").");
        }
    }

    // multipart 몸통의 한 부분을 다음 모양으로 쓴다:
    //   --구분글자
    //   Content-Disposition: form-data; name="이름"
    //   Content-Type: text/plain; charset=UTF-8
    //   (빈 줄)
    //   값
    private static void part(ByteArrayOutputStream out, String boundary, String name, String value) {
        String s = "--" + boundary + "\r\n"
                + "Content-Disposition: form-data; name=\"" + name + "\"\r\n"
                + "Content-Type: text/plain; charset=UTF-8\r\n\r\n"
                + value + "\r\n";
        out.writeBytes(s.getBytes(StandardCharsets.UTF_8));
    }
}
