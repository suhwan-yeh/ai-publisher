/*
 * [1] 역할
 *     자바스크립트 fetch 요청을 받아 JSON 을 돌려주는 @RestController 묶음과, 오류를 JSON 으로 바꾸는 ApiExceptionHandler.
 *
 * [2] 받는 것 → 내보내는 것 (실제로 실행해서 얻은 값)
 *     POST /api/chat {"text":"좋아요, 이대로 진행해 주세요."}
 *       → 201  Location: /api/chat/103
 *              {"id":103,"fromBoss":true,"text":"좋아요, 이대로 진행해 주세요.","at":"2026-11-09T21:46:33.776008Z","channel":"web","files":[]}
 *
 * [3] 앞뒤 파일
 *     계층 (화살표 = 부르는 방향, 거꾸로 부르지 않는다)
 *       브라우저 → controller / api → service → repository → DB
 *                                       service → client → fakechat(쭌), tmux
 *       scan(시각에 맞춰 실행) → service → scan 의 읽기 클래스 → repository → DB
 *       dto  : api 가 JSON 으로 주고받는 모양     domain : DB 표와 대응하는 엔티티     config : 설정
 *
 * [4] 파일 목록
 *     ChatApiController       /api/chat (보내기·폴링·한 건·상태)                    흐름 B, B′, D
 *     BookApiController       /api/books
 *     OfficeApiController     /api/office, /api/meeting, /api/staff                흐름 E
 *     ApiExceptionHandler     예외 → 400 / 404 / 503 JSON                      흐름 D
 *
 * [5] 먼저 알 용어 (자세한 설명: docs/용어-풀이.md)
 *     @RestController, @RequestBody, @Valid, ResponseEntity, @RestControllerAdvice, @ExceptionHandler
 *
 * [6] 읽는 순서
 *     ChatApiController → ApiExceptionHandler → OfficeApiController → BookApiController
 *
 * [7] 다 읽고 확인
 *     - controller 패키지와 api 패키지의 차이를 돌려주는 것으로 설명해 보라.
 *     - 빈 글을 보내 400 이 날 때 JSON 을 만드는 클래스는 어느 것인가?
 */
package com.greendesk.publisher.api;
