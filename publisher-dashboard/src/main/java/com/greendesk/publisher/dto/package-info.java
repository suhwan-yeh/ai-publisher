/*
 * [1] 역할
 *     API 가 주고받는 JSON 의 모양을 정한 record 묶음. 엔티티를 그대로 내보내지 않고 화면에 필요한 값만 담는다.
 *
 * [2] 받는 것 → 내보내는 것 (실제로 실행해서 얻은 값)
 *     요청 DTO  SendMessageRequest  ← {"text":"좋아요"}
 *     응답 DTO  ChatMessageResponse → {"id":103,"fromBoss":true,"text":"…","at":"…","channel":"web","files":[]}
 *     오류 DTO  ErrorResponse       → {"status":400,"code":"VALIDATION","message":"보낼 말을 적어 주세요.",…}
 *
 * [3] 앞뒤 파일
 *     계층 (화살표 = 부르는 방향, 거꾸로 부르지 않는다)
 *       브라우저 → controller / api → service → repository → DB
 *                                       service → client → fakechat(쭌), tmux
 *       scan(시각에 맞춰 실행) → service → scan 의 읽기 클래스 → repository → DB
 *       dto  : api 가 JSON 으로 주고받는 모양     domain : DB 표와 대응하는 엔티티     config : 설정
 *
 * [4] 파일 목록
 *     SendMessageRequest                       요청 몸통 (@NotBlank, @Size 검사 규칙)          흐름 B-②
 *     ChatMessageResponse, ChatPollResponse    대화 응답                                       흐름 B-⑤, B′
 *     ErrorResponse                            오류 응답                                       흐름 D
 *     OfficeResponse, AgentStatusResponse, ScreenResponse, TeamMessageResponse, MeetingResponse, OfficeStatusResponse, StaffResponse
 *                                              사무실·회의실 응답                                흐름 E
 *     BookSummaryResponse, FileLink            책 목록 응답
 *
 * [5] 먼저 알 용어 (자세한 설명: docs/용어-풀이.md)
 *     record, @NotBlank, @Size, 정적 팩토리 메서드 from()
 *
 * [6] 읽는 순서
 *     SendMessageRequest → ChatMessageResponse → ErrorResponse → OfficeResponse
 *
 * [7] 다 읽고 확인
 *     - ChatMessage 엔티티의 uniqueKey 는 왜 ChatMessageResponse 에 없는가?
 *     - record 의 필드 이름이 JSON 의 이름이 되는가? (그렇다. Jackson 이 이름 그대로 쓴다)
 */
package com.greendesk.publisher.dto;
