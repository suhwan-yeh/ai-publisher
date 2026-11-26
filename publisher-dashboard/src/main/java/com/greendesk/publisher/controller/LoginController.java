/*
 * [1] 역할
 *     로그인 화면(GET /login)을 돌려준다. 서버(prod) 모드에서만 쓰인다.
 *     아이디·비밀번호를 받는 POST /login 은 이 클래스가 아니라 Spring Security 가 처리한다(config/SecurityConfig.java).
 *
 * [2] 받는 것 → 내보내는 것 (실제로 실행해서 얻은 값)
 *     요청   GET /login
 *     응답   200  text/html   (templates/login.html)
 *     로그인하지 않고 GET / 을 열면(서버 모드):  302  Location: /login
 *
 * [3] 앞뒤 파일
 *     config/SecurityConfig.java (로그인하지 않은 요청을 /login 으로 보냄)  →  (이 파일)  →  templates/login.html
 *
 * [4] 메서드 목록
 *     메서드          주소            돌려주는 것
 *     login()         GET /login      login.html
 *
 * [5] 먼저 알 용어 (자세한 설명: docs/용어-풀이.md)
 *     @Controller, @GetMapping
 *
 * [6] 읽는 순서
 *     login()
 *
 * [7] 다 읽고 확인
 *     - 이 PC(로컬) 모드에서 /login 을 열면 화면이 보이는가? (보인다. 다만 보안 설정이 꺼져 있어 로그인 없이도 모든 화면이 열린다)
 *     - 로그인 폼의 POST /login 을 받는 메서드가 이 클래스에 없는데 왜 동작하는가?
 */
package com.greendesk.publisher.controller;

import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.GetMapping;

/** 화면용 컨트롤러: 로그인 (서버 모드에서만 쓰임) */
@Controller
public class LoginController {

    // @GetMapping("/login") : GET /login 요청을 받는다. "login" → templates/login.html
    // POST /login 은 Spring Security 의 필터가 컨트롤러보다 먼저 가로채 처리한다.
    @GetMapping("/login")
    public String login() {
        return "login";
    }
}
