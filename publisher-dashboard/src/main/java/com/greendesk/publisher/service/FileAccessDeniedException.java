/*
 * [1] 역할
 *     출판사 폴더 밖의 파일을 요청했을 때 발생시키는 예외다. 서비스가 throw 하면 컨트롤러를 거쳐 위로 전달되고, 상태코드 400 응답으로 바뀐다.
 *
 * [2] 받는 것 → 내보내는 것 (실제로 실행해서 얻은 값)
 *     throw new FileAccessDeniedException("…")
 *       REST API 요청이면  → api/ApiExceptionHandler.java 가 400 + ErrorResponse(JSON) 로 응답한다
 *       화면 요청이면      → 아래 @ResponseStatus 에 따라 스프링이 400 오류 화면으로 응답한다
 *
 * [3] 앞뒤 파일
 *     service/DashboardService.java, service/ChatService.java, service/OfficeService.java (throw 하는 곳)  →  (이 파일)  →  api/ApiExceptionHandler.java
 *
 * [4] 생성자 목록
 *     생성자 FileAccessDeniedException(String message)   예외 문장을 받아 부모 클래스(RuntimeException)에 넘긴다. 나중에 e.getMessage() 로 꺼낸다.
 *
 * [5] 먼저 알 용어 (자세한 설명: docs/용어-풀이.md)
 *     예외, throw, RuntimeException, extends, @ResponseStatus
 *
 * [6] 읽는 순서
 *     위에서 아래로 읽는다.
 *
 * [7] 다 읽고 확인
 *     - 이 예외가 api 패키지 컨트롤러에서 발생하면 @ResponseStatus 와 ApiExceptionHandler 중 어느 쪽이 응답을 정하는가? (ApiExceptionHandler)
 *     - RuntimeException 을 상속하면 메서드 선언에 throws 를 적지 않아도 된다. 이 점이 어떤 코드를 간단하게 만드는가?
 */
package com.greendesk.publisher.service;

import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.ResponseStatus;

/** 출판사 폴더 밖의 파일을 달라고 함 → 400 */
// @ResponseStatus(HttpStatus.BAD_REQUEST)
//   뜻     : 이 예외가 처리되지 않고 스프링까지 올라오면 응답 상태코드를 400 으로 정한다.
//   쓰이는 곳: 화면용 컨트롤러(controller 패키지). api 패키지에서는 ApiExceptionHandler 가 먼저 처리한다.
@ResponseStatus(HttpStatus.BAD_REQUEST)
// extends RuntimeException : 자바의 RuntimeException 클래스를 상속한다(그 기능을 물려받는다).
// RuntimeException 계열 예외는 메서드 선언에 "throws 예외이름" 을 적지 않아도 던질 수 있다.
public class FileAccessDeniedException extends RuntimeException {
    public FileAccessDeniedException(String message) {
        // super(…) = 부모 클래스(RuntimeException)의 생성자를 호출한다. 예외 문장이 저장되고 getMessage() 로 꺼낼 수 있다.
        super(message);
    }
}
