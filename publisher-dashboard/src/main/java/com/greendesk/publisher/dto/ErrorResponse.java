/*
 * [1] 역할
 *     REST API 에서 오류가 났을 때 응답 몸통의 모양이다. 어떤 오류든 이 모양 하나만 쓴다.
 *
 * [2] 받는 것 → 내보내는 것 (실제로 실행해서 얻은 값)
 *     내보내는 것  {"status":400,"code":"VALIDATION","message":"보낼 말을 적어 주세요.","timestamp":"2026-11-09T21:46:33.819759499Z"}
 *
 * [3] 앞뒤 파일
 *     api/ApiExceptionHandler.java 의 body() 가 만든다  →  static/js/chatpanel.js 가 message 를 화면에 표시한다
 *
 * [4] 필드와 메서드 목록
 *     필드        자료형    뜻                                          예
 *     status      int       HTTP 상태코드와 같은 숫자                     400
 *     code        String    프로그램이 오류 종류를 구분할 때 쓰는 짧은 이름   "VALIDATION"
 *     message     String    화면에 그대로 표시할 한국어 문장               "보낼 말을 적어 주세요."
 *     timestamp   Instant   오류가 발생한 시각                            "2026-11-09T21:46:33.819759499Z"
 *
 *     메서드      하는 일
 *     of()        status, code, message 를 받아 현재 시각을 넣은 ErrorResponse 를 만든다
 *
 * [5] 먼저 알 용어 (자세한 설명: docs/용어-풀이.md)
 *     record, static 메서드, Instant.now()
 *
 * [6] 읽는 순서
 *     필드 목록 → of()
 *
 * [7] 다 읽고 확인
 *     - 오류 응답의 모양을 하나로 통일하면 화면의 자바스크립트 코드는 어떤 점이 간단해지는가?
 *     - code 가 "LEAD_OFFLINE" 인 응답의 status 는 몇인가?
 */
package com.greendesk.publisher.dto;

import java.time.Instant;

/**
 * 모든 API 오류의 공통 모양.
 * status  : HTTP 상태코드 (400, 404, 503 …)
 * code    : 프로그램이 구분할 짧은 이름 (VALIDATION, NOT_FOUND, LEAD_OFFLINE …)
 * message : 화면에 그대로 보여 줄 한국어 문장
 */
// record
//   뜻     : 값만 담는 클래스를 짧게 선언하는 자바 문법이다. 괄호 안에 적은 이름들이 필드가 된다.
//   결과   : 자바가 생성자, 필드 값을 꺼내는 메서드(예: text()), equals, toString 을 자동으로 만든다.
//            값을 바꾸는 메서드(setter)는 만들지 않는다. 한 번 만든 객체의 값은 바뀌지 않는다.
//   JSON   : 스프링이 이 객체를 JSON 으로 바꿀 때 필드 이름이 JSON 의 이름이 된다.
public record ErrorResponse(int status, String code, String message, Instant timestamp) {

    // ▶ 받는 값: status, code, message      예) of(400, "VALIDATION", "보낼 말을 적어 주세요.")
    // ▶ 돌려주는 값: ErrorResponse 객체
    public static ErrorResponse of(int status, String code, String message) {
        // Instant.now() = 이 줄이 실행되는 순간의 시각.   예) 2026-11-09T21:46:33.819759499Z
        return new ErrorResponse(status, code, message, Instant.now());
    }
}
