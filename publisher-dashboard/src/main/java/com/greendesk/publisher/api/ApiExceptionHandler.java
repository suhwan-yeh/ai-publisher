/*
 * [1] 역할
 *     api 패키지의 컨트롤러에서 예외(오류)가 발생했을 때, 예외 종류에 맞는 상태코드와 JSON 오류 몸통을 만들어 응답한다.
 *     오류 몸통의 모양은 항상 ErrorResponse 하나다: {"status":…,"code":"…","message":"…","timestamp":"…"}
 *
 * [2] 받는 것 → 내보내는 것 (실제로 실행해서 얻은 값)
 *     받는 것   컨트롤러나 서비스에서 발생한 예외 객체
 *     내보내는 것
 *       빈 글 전송        400  {"status":400,"code":"VALIDATION","message":"보낼 말을 적어 주세요.","timestamp":"2026-11-09T21:46:33.819759499Z"}
 *       없는 책 조회      404  {"status":404,"code":"NOT_FOUND","message":"책을 찾을 수 없어요.","timestamp":"2026-11-09T21:46:34.104575673Z"}
 *       숫자 자리에 글자  400  {"status":400,"code":"BAD_REQUEST","message":"요청 형식이 올바르지 않아요.","timestamp":"…"}
 *       쭌과 연결 안 됨   503  {"status":503,"code":"LEAD_OFFLINE","message":"쭌이 출근 전이에요. 우분투 창에서 '출근'을 입력한 뒤 다시 보내 주세요.","timestamp":"…"}
 *
 * [3] 앞뒤 파일
 *     api/*Controller.java, service/*.java (예외가 발생하는 곳)  →  (이 파일)  →  static/js/chatpanel.js (message 를 화면에 표시)
 *     오류 몸통의 모양: dto/ErrorResponse.java
 *
 * [4] 메서드 목록
 *     메서드       처리하는 예외                                응답 상태코드   code 값        흐름 번호
 *     invalid()    MethodArgumentNotValidException (@Valid 실패)  400            VALIDATION     흐름 D-①
 *     unreadable() 요청 몸통·주소 값을 변환하지 못함              400            BAD_REQUEST
 *     illegal()    IllegalArgumentException                      400            VALIDATION
 *     denied()     FileAccessDeniedException                     400            FILE_DENIED
 *     notFound()   NotFoundException                             404            NOT_FOUND      흐름 D-③
 *     offline()    ChannelUnavailableException                   503            LEAD_OFFLINE   흐름 D-②
 *     body()       위 메서드들이 공통으로 쓰는 응답 만들기
 *
 * [5] 먼저 알 용어 (자세한 설명: docs/용어-풀이.md)
 *     예외(Exception), @RestControllerAdvice, @ExceptionHandler, HTTP 상태코드 400·404·503
 *
 * [6] 읽는 순서
 *     body() → invalid() → notFound() → offline() → 나머지
 *
 * [7] 다 읽고 확인
 *     - ChatService.send() 에서 ChannelUnavailableException 이 발생하면 이 파일의 어느 메서드가 실행되는가?
 *     - 이 클래스가 없다면 @Valid 검사 실패 때 응답 몸통의 모양은 누가 정하는가? (스프링의 기본 오류 응답이 나간다)
 */
package com.greendesk.publisher.api;

import com.greendesk.publisher.client.ChannelUnavailableException;
import com.greendesk.publisher.dto.ErrorResponse;
import com.greendesk.publisher.service.FileAccessDeniedException;
import com.greendesk.publisher.service.NotFoundException;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.http.converter.HttpMessageNotReadableException;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;
import org.springframework.web.method.annotation.MethodArgumentTypeMismatchException;

/**
 * REST API(api 패키지)에서 난 오류를 모두 같은 모양(ErrorResponse)과 알맞은 상태코드로 바꾼다.
 * 화면용 컨트롤러는 여기에 해당하지 않는다(오류 화면으로 감).
 */
// @RestControllerAdvice(basePackages = "com.greendesk.publisher.api")
//   뜻     : api 패키지의 컨트롤러에서 예외가 발생하면, 이 클래스의 @ExceptionHandler 메서드 중 맞는 것을 실행한다.
//   basePackages : 적용 범위. controller 패키지(HTML 화면용)에는 적용하지 않는다.
//   결과   : 각 메서드의 return 값이 JSON 으로 응답된다. (이름에 Rest 가 붙어 있어 @RestController 와 같은 방식으로 응답한다)
//   없으면 : 예외가 발생했을 때 스프링의 기본 오류 응답이 나간다. 몸통의 모양이 ErrorResponse 와 달라진다.
@RestControllerAdvice(basePackages = "com.greendesk.publisher.api")
public class ApiExceptionHandler {

    /** @Valid 검사 실패 → 400 */
    // [흐름 D-①] @Valid 검사에 실패했을 때
    //   발생 지점 : ChatApiController.send() 의 @Valid — 본문이 실행되기 전에 스프링이 MethodArgumentNotValidException 을 발생시킨다.
    //
    // @ExceptionHandler(예외클래스.class)
    //   뜻     : 괄호 안의 예외가 발생하면 이 메서드를 실행한다.
    //   받는 것: 발생한 예외 객체 (매개변수 e)
    //   결과   : 이 메서드의 return 값이 응답이 된다.
    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<ErrorResponse> invalid(MethodArgumentNotValidException e) {
        // 아래 두 줄은 다음 순서로 실행된다. (예: {"text":"   "} 를 보냈을 때)
        //   (1) e.getBindingResult()        검사 결과 전체를 꺼낸다.
        //   (2) .getFieldErrors()           규칙을 어긴 필드의 목록을 꺼낸다.     예) [text 필드: @NotBlank 위반]
        //   (3) .stream()                   목록의 원소를 하나씩 처리할 준비를 한다.
        //   (4) .map(f -> f.getDefaultMessage())   원소마다 오류 문장을 꺼낸다.   예) "보낼 말을 적어 주세요."
        //                                   이 문장은 SendMessageRequest 의 @NotBlank(message = "…") 에 적은 글자다.
        //                                   f -> f.getDefaultMessage() 는 "f 를 받아서 f.getDefaultMessage() 를 돌려준다"는 뜻의 람다식이다.
        //   (5) .findFirst()                첫 번째 것만 고른다.                   자료형: Optional<String>
        //   (6) .orElse("요청 값이 올바르지 않아요.")   하나도 없으면 이 문장을 쓴다.
        //   (7) msg = 결과                  예) msg = "보낼 말을 적어 주세요."
        String msg = e.getBindingResult().getFieldErrors().stream()
                .map(f -> f.getDefaultMessage()).findFirst().orElse("요청 값이 올바르지 않아요.");
        // 맨 아래 body() 메서드를 호출해 응답을 만든다.   HttpStatus.BAD_REQUEST = 400
        // 실제 응답: 400  {"status":400,"code":"VALIDATION","message":"보낼 말을 적어 주세요.","timestamp":"2026-11-09T21:46:33.819759499Z"}
        // → chatpanel.js 가 이 몸통의 message 를 화면에 표시한다. [흐름 D-④]
        return body(HttpStatus.BAD_REQUEST, "VALIDATION", msg);
    }

    /** JSON 모양이 틀림, 숫자 자리에 글자 등 → 400 */
    // 중괄호 { , } 안에 예외를 두 개 적으면 둘 중 어느 것이 발생해도 이 메서드가 실행된다.
    //   HttpMessageNotReadableException       : 요청 몸통이 JSON 문법에 맞지 않을 때             예) {"text": 
    //   MethodArgumentTypeMismatchException   : 숫자 자리에 숫자가 아닌 글자가 왔을 때            예) GET /api/books/abc
    // 실제 응답(GET /api/chat/abc): 400  {"status":400,"code":"BAD_REQUEST","message":"요청 형식이 올바르지 않아요.",...}
    @ExceptionHandler({HttpMessageNotReadableException.class, MethodArgumentTypeMismatchException.class})
    public ResponseEntity<ErrorResponse> unreadable(Exception e) {
        return body(HttpStatus.BAD_REQUEST, "BAD_REQUEST", "요청 형식이 올바르지 않아요.");
    }

    /** 서비스가 검사해서 거절 → 400 */
    // ChatService.send() 가 글자 수 등을 직접 검사해 throw new IllegalArgumentException("…") 을 실행했을 때.
    // e.getMessage() = 예외를 만들 때 괄호 안에 넣은 문장.
    @ExceptionHandler(IllegalArgumentException.class)
    public ResponseEntity<ErrorResponse> illegal(IllegalArgumentException e) {
        return body(HttpStatus.BAD_REQUEST, "VALIDATION", e.getMessage());
    }

    // 출판사 폴더 밖의 파일을 내려받으려 했을 때 (ChatService.attachment() 에서 발생).
    @ExceptionHandler(FileAccessDeniedException.class)
    public ResponseEntity<ErrorResponse> denied(FileAccessDeniedException e) {
        return body(HttpStatus.BAD_REQUEST, "FILE_DENIED", e.getMessage());
    }

    // [흐름 D-③] 찾는 데이터가 없을 때
    //   발생 지점 예 : DashboardService.bookOrThrow(9999) → throw new NotFoundException("책을 찾을 수 없어요.")
    //   실제 응답(GET /api/books/9999): 404  {"status":404,"code":"NOT_FOUND","message":"책을 찾을 수 없어요.",...}
    //   HttpStatus.NOT_FOUND = 404
    @ExceptionHandler(NotFoundException.class)
    public ResponseEntity<ErrorResponse> notFound(NotFoundException e) {
        return body(HttpStatus.NOT_FOUND, "NOT_FOUND", e.getMessage());
    }

    /** 쭌이 출근 전 → 503 */
    // [흐름 D-②] 쭌(Claude Code)과 연결되지 않았을 때
    //   발생 지점 : FakechatClient.send() → throw new ChannelUnavailableException("쭌이 출근 전이에요. …")
    //               ChatService.send() 안에서 호출되므로, 예외가 ChatService → ChatApiController 를 거쳐 여기까지 올라온다.
    //   실제 응답(POST /api/chat): 503  {"status":503,"code":"LEAD_OFFLINE","message":"쭌이 출근 전이에요. 우분투 창에서 '출근'을 입력한 뒤 다시 보내 주세요.",...}
    //   HttpStatus.SERVICE_UNAVAILABLE = 503 (서버가 지금은 이 요청을 처리할 수 없음)
    @ExceptionHandler(ChannelUnavailableException.class)
    public ResponseEntity<ErrorResponse> offline(ChannelUnavailableException e) {
        return body(HttpStatus.SERVICE_UNAVAILABLE, "LEAD_OFFLINE", e.getMessage());
    }

    // 위의 모든 메서드가 공통으로 쓰는 메서드. 상태코드와 오류 몸통을 가진 응답을 만든다.
    //   매개변수 예) status = HttpStatus.BAD_REQUEST, code = "VALIDATION", message = "보낼 말을 적어 주세요."
    private static ResponseEntity<ErrorResponse> body(HttpStatus status, String code, String message) {
        // (1) status.value()                               상태코드의 숫자를 꺼낸다.          예) 400
        // (2) ErrorResponse.of(400, "VALIDATION", "보낼 말을 적어 주세요.")   오류 몸통 객체를 만든다. 현재 시각(timestamp)이 함께 들어간다.
        // (3) ResponseEntity.status(status)                응답의 상태코드를 400 으로 정한다.
        // (4) .body((2)의 값)                              응답 몸통에 넣는다. 응답할 때 JSON 으로 바뀐다.
        return ResponseEntity.status(status).body(ErrorResponse.of(status.value(), code, message));
    }
}
