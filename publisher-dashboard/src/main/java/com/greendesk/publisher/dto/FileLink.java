/*
 * [1] 역할
 *     메시지에 첨부된 파일 하나의 이름과 내려받기 주소를 담는다.
 *
 * [2] 받는 것 → 내보내는 것 (실제로 실행해서 얻은 값)
 *     내보내는 것  {"name":"book.pdf","url":"/chat/59/file/0"}
 *
 * [3] 앞뒤 파일
 *     dto/ChatMessageResponse.java 의 from() 이 만든다  →  static/js/chatpanel.js 의 render() 가 <a href="주소">⬇ 이름</a> 을 만든다
 *
 * [4] 필드 목록
 *     필드   자료형   뜻                                 예
 *     name   String   파일 이름                          "book.pdf"
 *     url    String   이 파일을 내려받는 주소              "/chat/59/file/0"
 *
 * [5] 먼저 알 용어 (자세한 설명: docs/용어-풀이.md)
 *     record
 *
 * [6] 읽는 순서
 *     필드 두 개가 전부다.
 *
 * [7] 다 읽고 확인
 *     - url 의 59 와 0 은 각각 무엇인가? (59 = 메시지 번호, 0 = 그 메시지의 첨부 중 몇 번째인지)
 *     - 이 주소로 GET 요청을 보내면 어느 컨트롤러 메서드가 실행되는가? (controller/ChatPageController.java 의 file())
 */
package com.greendesk.publisher.dto;

/** 메시지에 붙은 파일: 이름과 내려받기 주소 */
// record
//   뜻     : 값만 담는 클래스를 짧게 선언하는 자바 문법이다. 괄호 안에 적은 이름들이 필드가 된다.
//   결과   : 자바가 생성자, 필드 값을 꺼내는 메서드(예: text()), equals, toString 을 자동으로 만든다.
//            값을 바꾸는 메서드(setter)는 만들지 않는다. 한 번 만든 객체의 값은 바뀌지 않는다.
//   JSON   : 스프링이 이 객체를 JSON 으로 바꿀 때 필드 이름이 JSON 의 이름이 된다.
public record FileLink(String name, String url) {
}
