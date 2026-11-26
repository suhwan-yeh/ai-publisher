/*
 * [1] 역할
 *     로그인과 보안 규칙을 정하는 설정 클래스다(Spring Security).
 *       내 PC(기본): 로그인 없이 모든 주소가 열린다.
 *       서버(prod 프로필): 사장님 계정 하나로 로그인해야 열린다. POST 요청은 CSRF 토큰을 확인한다.
 *
 * [2] 받는 것 → 내보내는 것 (실제로 실행해서 얻은 값)
 *     내 PC        GET /office → 200 (로그인 없음)
 *     서버(prod)   GET /office (로그인 안 함) → 302  Location: /login
 *                  GET /api/books (로그인 안 함) → 401
 *                  GET /actuator/health → 200 {"status":"UP"} (로그인 없이 열림)
 *                  POST /api/chat (로그인 함, CSRF 토큰 없음) → 403
 *
 * [3] 앞뒤 파일
 *     application.yml(publisher.security.*), application-prod.yml  →  (이 파일)  →  모든 요청이 컨트롤러에 닿기 전에 이 규칙을 지난다
 *     화면 쪽: templates/login.html, templates/fragments.html(로그아웃 단추), office.html·chat.html 의 CSRF meta 태그, static/js/chatpanel.js(CSRF 헤더)
 *     시험: src/test/java/…/SecurityEnabledTest.java
 *
 * [4] 메서드 목록
 *     메서드                   하는 일
 *     securityFilterChain()    주소별 허용 규칙, 로그인 화면, 로그아웃, CSRF, API 의 401 처리
 *     bossAccount()            사장님 계정 하나를 메모리에 만든다 (비밀번호는 암호화해서 보관)
 *     passwordEncoder()        비밀번호 암호화 방식
 *
 * [5] 먼저 알 용어 (자세한 설명: docs/용어-풀이.md)
 *     @Configuration, @Bean, Spring Security, SecurityFilterChain, CSRF, 401·403, 환경 변수
 *
 * [6] 읽는 순서
 *     securityFilterChain() 의 if (!enabled) 부분 → 그 아래 서버 규칙 → bossAccount()
 *
 * [7] 다 읽고 확인
 *     - 서버 모드에서 로그인하지 않고 /js/chatpanel.js 를 요청하면 열리는가? (열린다: permitAll 목록)
 *     - BOSS_PASSWORD 를 7자로 주고 서버 모드로 시작하면 어떻게 되는가? (시작이 실패한다)
 */
package com.greendesk.publisher.config;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.HttpStatus;
import org.springframework.security.config.Customizer;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.core.userdetails.User;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.crypto.factory.PasswordEncoderFactories;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.provisioning.InMemoryUserDetailsManager;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.authentication.HttpStatusEntryPoint;

import java.util.UUID;

/**
 * 로그인 설정.
 *  - 내 PC(기본): publisher.security.enabled=false → 로그인 없이 열림 (127.0.0.1 에서만 쓰는 관리 화면)
 *  - 서버(prod 프로필): true → 사장님 계정 하나로 로그인해야 열림. 화면 폼과 fetch 요청 모두 CSRF 토큰 확인.
 * 사장님 계정은 환경변수 BOSS_USERNAME / BOSS_PASSWORD 로 받는다 (코드·git 에 비밀번호를 두지 않음).
 */
// @Configuration : 이 클래스는 설정 클래스다. 안의 @Bean 메서드가 돌려준 객체를 스프링이 등록해 쓴다.
@Configuration
public class SecurityConfig {

    // @Bean : 이 메서드가 돌려준 객체를 스프링에 등록한다. 스프링 시큐리티가 이 SecurityFilterChain 을 찾아 모든 요청에 적용한다.
    @Bean
    SecurityFilterChain securityFilterChain(HttpSecurity http,
                                            @Value("${publisher.security.enabled:false}") boolean enabled) throws Exception {
        // publisher.security.enabled 가 false(내 PC 기본값)이면:
        //   anyRequest().permitAll()  모든 주소를 로그인 없이 허용
        //   csrf(c -> c.disable())    CSRF 검사를 끈다
        if (!enabled) {
            return http
                    .authorizeHttpRequests(a -> a.anyRequest().permitAll())
                    .csrf(c -> c.disable())
                    .build();
        }
        return http
                .authorizeHttpRequests(a -> a
                        // 서버 모드: 이 주소들은 로그인 없이 허용한다. (상태 확인, 로그인 화면, 화면 꾸미기 파일)  /** = 그 아래 모든 주소
                        .requestMatchers("/actuator/health", "/login", "/style.css", "/css/**", "/js/**", "/favicon.ico", "/error").permitAll()
                        // 그 밖의 모든 주소는 로그인한 사람만.
                        .anyRequest().authenticated())
                // 로그인 화면 주소는 /login. 로그인에 성공하면 원래 가려던 주소로, 없으면 /office 로 이동한다.
                .formLogin(f -> f.loginPage("/login").defaultSuccessUrl("/office", false).permitAll())
                .logout(l -> l.logoutSuccessUrl("/login?logout").permitAll())
                // CSRF 검사를 켠다. POST 요청에 서버가 준 토큰이 없으면 403.
                // (다른 사이트가 사장님 브라우저를 이용해 몰래 POST 를 보내는 것을 막는다)
                // 화면 폼은 th:action 이 토큰을 자동으로 넣고, fetch 는 chatpanel.js 가 meta 태그의 토큰을 헤더에 넣는다.
                .csrf(Customizer.withDefaults())
                // REST API 는 로그인 화면으로 보내지 않고 401 을 돌려준다
                // /api/ 로 시작하는 주소를 로그인 없이 요청하면, 로그인 화면으로 보내지 않고 401(Unauthorized)을 응답한다.
                // (fetch 는 HTML 로그인 화면이 아니라 상태코드로 판단하기 때문)
                .exceptionHandling(e -> e.defaultAuthenticationEntryPointFor(
                        new HttpStatusEntryPoint(HttpStatus.UNAUTHORIZED), request -> request.getRequestURI().startsWith("/api/")))
                .build();
    }

    @Bean
    // 사장님 계정을 메모리에 하나 만든다. 아이디·비밀번호는 환경 변수(BOSS_USERNAME, BOSS_PASSWORD)에서 받는다.
    UserDetailsService bossAccount(@Value("${publisher.security.enabled:false}") boolean enabled,
                                   @Value("${publisher.security.username:boss}") String username,
                                   @Value("${publisher.security.password:}") String password,
                                   PasswordEncoder encoder) {
        // 서버 모드인데 비밀번호가 없거나 8자보다 짧으면 시작을 멈춘다.
        if (enabled && (password == null || password.length() < 8)) {
            throw new IllegalStateException("서버 모드에서는 BOSS_PASSWORD 환경변수(8자 이상)를 꼭 정해 주세요.");
        }
        // 내 PC 모드처럼 비밀번호가 없으면 아무도 모르는 무작위 비밀번호를 쓴다 (로그인 기능 자체를 쓰지 않으므로).
        String pw = password == null || password.isBlank() ? UUID.randomUUID().toString() : password;
        // encoder.encode(pw) = 비밀번호를 그대로 두지 않고 암호화한 값으로 보관한다.
        return new InMemoryUserDetailsManager(User.withUsername(username).password(encoder.encode(pw)).roles("BOSS").build());
    }

    @Bean
    PasswordEncoder passwordEncoder() {
        // 스프링 시큐리티의 기본 암호화 방식(bcrypt). 저장 값 예) {bcrypt}$2a$10$…
        return PasswordEncoderFactories.createDelegatingPasswordEncoder();
    }
}
