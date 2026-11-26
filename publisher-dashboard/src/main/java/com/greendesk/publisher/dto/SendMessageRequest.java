/*
 * [1] 역할
 *     POST /api/chat 요청 몸통의 모양과 검사 규칙을 정한 클래스다. (DTO = Data Transfer Object, 계층 사이에 값을 전달하는 객체)
 *
 * [2] 받는 것 → 내보내는 것 (실제로 실행해서 얻은 값)
 *     받는 것        요청 몸통 JSON   {"text":"좋아요, 이대로 진행해 주세요."}
 *     내보내는 것    자바 객체        SendMessageRequest(text="좋아요, 이대로 진행해 주세요.")
 *     규칙을 어긴 예  {"text":"   "}  →  400  {"status":400,"code":"VALIDATION","message":"보낼 말을 적어 주세요.",…}
 *
 * [3] 앞뒤 파일
 *     static/js/chatpanel.js (JSON 을 만들어 보냄)  →  (이 파일)  →  api/ChatApiController.java 의 send()
 *
 * [4] 필드 목록
 *     필드   자료형   규칙                          규칙을 어겼을 때의 문장
 *     text   String   비어 있으면 안 됨, 4000자 이하   "보낼 말을 적어 주세요." / "4000자 이내로 적어 주세요."
 *
 * [5] 먼저 알 용어 (자세한 설명: docs/용어-풀이.md)
 *     record, @NotBlank, @Size, Bean Validation(@Valid 와 함께 동작하는 검사 기능)
 *
 * [6] 읽는 순서
 *     클래스 선언 한 덩어리가 전부다. 위에서 아래로 읽는다.
 *
 * [7] 다 읽고 확인
 *     - {"text":""} 를 보내면 어느 규칙에 걸리는가?
 *     - 이 클래스에 규칙을 적어 두기만 하면 검사가 실행되는가? (ChatApiController.send() 의 @Valid 가 있어야 실행된다)
 */
package com.greendesk.publisher.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

/** POST /api/chat 요청 몸통: 사장님이 쭌에게 보내는 말 */
// record
//   뜻     : 값만 담는 클래스를 짧게 선언하는 자바 문법이다. 괄호 안에 적은 이름들이 필드가 된다.
//   결과   : 자바가 생성자, 필드 값을 꺼내는 메서드(예: text()), equals, toString 을 자동으로 만든다.
//            값을 바꾸는 메서드(setter)는 만들지 않는다. 한 번 만든 객체의 값은 바뀌지 않는다.
//   JSON   : 스프링이 이 객체를 JSON 으로 바꿀 때 필드 이름이 JSON 의 이름이 된다.
//
// [흐름 B-②] ChatApiController.send() 의 @RequestBody 가 JSON 을 이 객체로 바꾸고, @Valid 가 아래 규칙을 검사한다.
public record SendMessageRequest(
        // @NotBlank
        //   뜻     : 값이 null 이거나, 길이가 0 이거나, 공백 문자만 있으면 규칙 위반이다.
        //   예     : "좋아요" 통과 / "" 위반 / "   " 위반 / null 위반
        //   message: 위반했을 때 사용할 문장. ApiExceptionHandler.invalid() 가 이 문장을 꺼내 응답 몸통의 message 에 넣는다. [흐름 D-①]
        @NotBlank(message = "보낼 말을 적어 주세요.")
        // @Size(max = 4000)
        //   뜻     : 글자 수가 4000 을 넘으면 규칙 위반이다.
        @Size(max = 4000, message = "4000자 이내로 적어 주세요.")
        // 필드 text. 자료형: String.  꺼낼 때는 request.text() 로 쓴다.   예) "좋아요, 이대로 진행해 주세요."
        String text) {
}
