/*
 * [1] 역할
 *     서버(prod) 모드의 로그인 규칙(config/SecurityConfig.java)을 시험한다. 진짜 서버를 열지 않고 MockMvc 로 요청을 흉내 낸다.
 *
 * [2] 받는 것 → 내보내는 것 (실제로 실행해서 얻은 값)
 *     로그인 없이  GET /office (HTML)        → 302 Location: …/login
 *                 GET /api/books             → 401
 *                 GET /actuator/health       → 200 {"status":"UP"}
 *     로그인      boss / 틀린비번             → 302 /login?error
 *                 boss / sajang-1234          → 302 /office
 *     로그인 후    POST /api/chat (CSRF 없음)  → 403
 *                 POST /api/chat (CSRF 있음)  → 503 {"code":"LEAD_OFFLINE"}   (서버에는 쭌이 없다)
 *                 GET /office 의 HTML 에 name="_csrf" 가 있다
 *
 * [3] 앞뒤 파일
 *     (이 파일)  →  config/SecurityConfig.java  →  api/*, controller/*
 *
 * [4] 메서드 목록
 *     메서드          확인하는 것
 *     anonymous       로그인 없이: 화면은 로그인으로, API 는 401, health 만 200
 *     login           사장님 계정으로만 로그인
 *     csrfOnApi       CSRF 토큰 없는 POST 는 403, 있으면 서비스 규칙까지 간다
 *
 * [5] 먼저 알 용어 (자세한 설명: docs/용어-풀이.md)
 *     @SpringBootTest(웹 서버 없이), @AutoConfigureMockMvc, MockMvc, perform·andExpect, formLogin, with(user), with(csrf), jsonPath, 401·403
 *
 * [6] 읽는 순서
 *     클래스 위 properties → anonymous() → login() → csrfOnApi()
 *
 * [7] 다 읽고 확인
 *     - 401 과 403 의 차이는? (401 = 누구인지 모름(로그인 안 함), 403 = 누구인지 알지만 허용하지 않음)
 *     - 서버 모드에서 chatpanel.js 가 CSRF 헤더를 싣지 않으면 보내기는 몇 번 상태코드가 되는가? (403)
 */
package com.greendesk.publisher;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;

import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestBuilders.formLogin;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.csrf;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.user;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

/** 서버 모드(로그인 켬)에서 지켜야 할 것: 로그인 없이는 못 보고, 상태 확인만 열리고, CSRF 토큰 없는 POST 는 막힌다 */
// 웹 서버 포트를 열지 않는다(webEnvironment 기본값 MOCK). 아래 @AutoConfigureMockMvc 의 MockMvc 로 요청을 흉내 낸다.
// publisher.security.enabled=true = 서버 모드처럼 로그인을 켠다.  bridge-url 1번 포트 = 쭌 없음.
@SpringBootTest(properties = {
        "spring.datasource.url=jdbc:h2:mem:sectest;DB_CLOSE_DELAY=-1",
        "publisher.scan-interval-ms=3600000",
        "publisher.root=/nonexistent",
        "publisher.security.enabled=true",
        "publisher.security.username=boss",
        "publisher.security.password=sajang-1234",
        "publisher.bridge-url=http://127.0.0.1:1"
})
// MockMvc
//   뜻     : 네트워크 없이 스프링 MVC 에 요청을 넣고 응답을 확인하는 시험 도구.
//   결과   : mvc.perform(get("/api/books")).andExpect(status().isUnauthorized())  → GET /api/books 의 응답이 401 인지 확인
@AutoConfigureMockMvc
class SecurityEnabledTest {

    @Autowired MockMvc mvc;

    @Test
    @DisplayName("로그인 없이: 화면은 로그인으로, API 는 401, 상태 확인(/actuator/health)만 200")
    void anonymous() throws Exception {
        // 브라우저처럼 HTML 을 원하면(Accept: text/html) 로그인 화면으로 302.
        mvc.perform(get("/office").accept(MediaType.TEXT_HTML)).andExpect(status().is3xxRedirection())
                .andExpect(redirectedUrlPattern("**/login"));
        // fetch 같은 API 요청은 302 대신 401 (자바스크립트가 로그인 화면 HTML 을 JSON 으로 잘못 읽지 않게).
        mvc.perform(get("/api/books")).andExpect(status().isUnauthorized());
        mvc.perform(get("/actuator/health")).andExpect(status().isOk()).andExpect(jsonPath("$.status").value("UP"));
        mvc.perform(get("/login")).andExpect(status().isOk());
    }

    @Test
    @DisplayName("사장님 계정으로만 로그인된다")
    void login() throws Exception {
        // formLogin: login.html 폼 전송(POST /login, username·password, CSRF)을 흉내 낸다.
        mvc.perform(formLogin("/login").user("boss").password("틀린비번")).andExpect(redirectedUrl("/login?error"));
        mvc.perform(formLogin("/login").user("boss").password("sajang-1234")).andExpect(redirectedUrl("/office"));
    }

    @Test
    @DisplayName("로그인해도 CSRF 토큰 없는 POST 는 403, 토큰이 있으면 통과해서 서비스 규칙(503: 서버엔 AI 팀 없음)까지 간다")
    void csrfOnApi() throws Exception {
        String body = "{\"text\":\"서버에서 주문\"}";
        // with(user("boss")): 로그인한 상태로 요청.  CSRF 토큰이 없으므로 403.
        mvc.perform(post("/api/chat").with(user("boss")).contentType(MediaType.APPLICATION_JSON).content(body))
                .andExpect(status().isForbidden());
        // with(csrf()): 올바른 CSRF 토큰을 싣는다 → 보안 검사를 통과해 ChatService 까지 가고, 쭌이 없어 503.
        mvc.perform(post("/api/chat").with(user("boss")).with(csrf()).contentType(MediaType.APPLICATION_JSON).content(body))
                .andExpect(status().isServiceUnavailable())
                .andExpect(jsonPath("$.code").value("LEAD_OFFLINE"));
        mvc.perform(get("/api/books").with(user("boss"))).andExpect(status().isOk());
        mvc.perform(get("/office").with(user("boss"))).andExpect(status().isOk())
                .andExpect(content().string(org.hamcrest.Matchers.containsString("name=\"_csrf\"")));
    }
}
