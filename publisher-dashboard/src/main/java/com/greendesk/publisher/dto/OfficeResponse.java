/*
 * [1] 역할
 *     GET /api/office 응답 몸통의 모양이다. 사무실 화면을 그리는 데 필요한 값을 한 번에 담는다.
 *
 * [2] 받는 것 → 내보내는 것 (실제로 실행해서 얻은 값)
 *     내보내는 것
 *       {"source":"기록","teamName":"session-2d8e941e","book":{"id":2,"title":"20261109-dinosaur",…},
 *        "agents":[{"name":"team-lead","korean":"쭌",…}, …6명],
 *        "messages":[{"id":41,"from":"minjun","fromKorean":"민준","to":"jihun",…}],
 *        "leadWaitingPermission":false,"now":"2026-11-09T21:46:34.182509578Z"}
 *
 * [3] 앞뒤 파일
 *     service/OfficeService.java 의 office() 가 만든다  →  api/OfficeApiController.java 가 return  →  static/js/office.js 의 poll()
 *
 * [4] 필드 목록
 *     필드                    자료형                       뜻                                                   예
 *     source                  String                       직원 상태를 어디서 읽었는가: "tmux" 또는 "기록"         "기록"
 *     teamName                String                       지금 팀(쭌의 Claude 세션) 이름                        "session-2d8e941e"
 *     book                    BookSummaryResponse          가장 최근 책의 요약 (없으면 null)                      {…}
 *     agents                  List<AgentStatusResponse>    쭌과 직원 한 명씩의 상태                               6명
 *     messages                List<TeamMessageResponse>    직원끼리 주고받은 새 메시지                            1건
 *     leadWaitingPermission   boolean                      쭌이 허용 질문에서 멈춰 있는가                         false
 *     now                     Instant                      서버의 현재 시각                                      "2026-11-09T21:46:34.182509578Z"
 *
 * [5] 먼저 알 용어 (자세한 설명: docs/용어-풀이.md)
 *     record, 객체 안의 객체(중첩 JSON), List
 *
 * [6] 읽는 순서
 *     필드 목록이 전부다.
 *
 * [7] 다 읽고 확인
 *     - JSON 에서 book 은 { } 로, agents 는 [ ] 로 표시된다. 자바 자료형과 어떤 관계가 있는가?
 *     - source 가 "기록" 이면 화면의 모니터에는 무엇이 표시되는가? (office.js 의 updateDesk 참고)
 */
package com.greendesk.publisher.dto;

import java.time.Instant;
import java.util.List;

/**
 * GET /api/office 응답: 사무실 전체 모습.
 * source : "tmux"(칸 화면을 직접 읽음) 또는 "기록"(tmux 없이 대화 기록으로만)
 */
// record
//   뜻     : 값만 담는 클래스를 짧게 선언하는 자바 문법이다. 괄호 안에 적은 이름들이 필드가 된다.
//   결과   : 자바가 생성자, 필드 값을 꺼내는 메서드(예: text()), equals, toString 을 자동으로 만든다.
//            값을 바꾸는 메서드(setter)는 만들지 않는다. 한 번 만든 객체의 값은 바뀌지 않는다.
//   JSON   : 스프링이 이 객체를 JSON 으로 바꿀 때 필드 이름이 JSON 의 이름이 된다.
// [흐름 E-⑦] OfficeService.office() 가 만든 이 객체가 JSON 으로 응답된다.
public record OfficeResponse(String source, String teamName, BookSummaryResponse book,
                             List<AgentStatusResponse> agents, List<TeamMessageResponse> messages,
                             boolean leadWaitingPermission, Instant now) {
}
