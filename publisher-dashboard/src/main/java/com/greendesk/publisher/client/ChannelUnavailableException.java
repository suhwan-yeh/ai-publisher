/*
 * [1] 역할
 *     쭌(Claude Code)에게 메시지를 전달할 수 없을 때 FakechatClient 가 던지는 예외다.
 *
 * [2] 받는 것 → 내보내는 것 (실제로 실행해서 얻은 값)
 *     throw new ChannelUnavailableException("쭌이 출근 전이에요. …")
 *       → API 요청: ApiExceptionHandler.offline() → 503 {"status":503,"code":"LEAD_OFFLINE","message":"쭌이 출근 전이에요. …",…}
 *       → 화면 폼(POST /order): ChatPageController 가 catch 해서 첫 화면으로 되돌려 안내 문장을 보여 준다
 *
 * [3] 앞뒤 파일
 *     client/FakechatClient.java (던짐)  →  service/ChatService.java (그대로 위로 전달)  →  api/ApiExceptionHandler.java 또는 controller/ChatPageController.java
 *
 * [4] 생성자 목록
 *     생성자 ChannelUnavailableException(문장)   예외 문장을 저장한다
 *
 * [5] 먼저 알 용어 (자세한 설명: docs/용어-풀이.md)
 *     예외, RuntimeException, @ResponseStatus, HTTP 503
 *
 * [6] 읽는 순서
 *     위에서 아래로 읽는다.
 *
 * [7] 다 읽고 확인
 *     - 503 은 어떤 뜻의 상태코드인가? (서버가 지금은 요청을 처리할 수 없음)
 *     - ChatService.send() 는 이 예외를 catch 하지 않는다. 그러면 예외는 어디로 가는가?
 */
package com.greendesk.publisher.client;

import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.ResponseStatus;

/** 쭌(Claude Code)이 출근 전이라 메시지를 전달할 수 없음 → 503 */
// 이 예외가 처리되지 않고 스프링까지 오면 상태코드 503 으로 응답한다.
@ResponseStatus(HttpStatus.SERVICE_UNAVAILABLE)
// RuntimeException 을 상속: 메서드 선언에 throws 를 적지 않아도 던질 수 있다.
public class ChannelUnavailableException extends RuntimeException {
    public ChannelUnavailableException(String message) {
        super(message);
    }
}
