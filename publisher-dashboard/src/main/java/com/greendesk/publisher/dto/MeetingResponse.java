/*
 * [1] 역할
 *     GET /api/meeting 응답 몸통의 모양이다. 회의실 화면에 표시할 책 정보와 직원 메시지를 담는다.
 *
 * [2] 받는 것 → 내보내는 것 (실제로 실행해서 얻은 값)
 *     내보내는 것
 *       {"teamName":"session-2d8e941e","bookId":2,"bookTitle":"20261109-dinosaur","stage":"기획 완료","chapters":[],
 *        "live":false,"messages":[{"id":41,"from":"minjun",…}],"bossNotes":[{"id":101,"fromBoss":true,"text":"초등학생이 읽을 공룡 이야기 동화 하나 만들어 줘",…}]}
 *
 * [3] 앞뒤 파일
 *     service/OfficeService.java 의 meeting() 이 만든다  →  api/OfficeApiController.java  →  static/js/meeting.js
 *
 * [4] 필드 목록
 *     필드        자료형                       뜻                                              예
 *     teamName    String                       팀(쭌의 세션) 이름                              "session-2d8e941e"
 *     bookId      Long                         책 번호 (없으면 null)                           2
 *     bookTitle   String                       책 제목                                        "20261109-dinosaur"
 *     stage       String                       진행 단계 한글 이름                             "기획 완료"
 *     chapters    List<String>                 장 제목 목록 (화이트보드에 표시)                 []
 *     live        boolean                      최근 2분 안에 직원 메시지가 있었는가             false
 *     messages    List<TeamMessageResponse>    직원 메시지 목록                                1건 이상
 *     bossNotes   List<ChatMessageResponse>    사장님이 최근에 보낸 말 (화면의 메모 영역에 표시)   최대 5건
 *
 * [5] 먼저 알 용어 (자세한 설명: docs/용어-풀이.md)
 *     record, List
 *
 * [6] 읽는 순서
 *     필드 목록이 전부다.
 *
 * [7] 다 읽고 확인
 *     - live 가 false 이면 회의실 화면 위쪽에는 어떤 글자가 표시되는가? (meeting.js 의 setState: "회의 쉬는 중")
 *     - bossNotes 의 자료형은 대화방에서 쓰는 것과 같은 ChatMessageResponse 다. DTO 를 여러 응답에서 다시 쓰면 어떤 점이 좋은가?
 */
package com.greendesk.publisher.dto;

import java.util.List;

/**
 * GET /api/meeting 응답: 회의실.
 * live      : 최근 2분 안에 대화가 있었나 (회의 중 / 쉬는 중)
 * chapters  : 화이트보드에 적을 장 제목들
 * bossNotes : 사장님이 최근에 한 말 (메모지로 붙임)
 */
// record
//   뜻     : 값만 담는 클래스를 짧게 선언하는 자바 문법이다. 괄호 안에 적은 이름들이 필드가 된다.
//   결과   : 자바가 생성자, 필드 값을 꺼내는 메서드(예: text()), equals, toString 을 자동으로 만든다.
//            값을 바꾸는 메서드(setter)는 만들지 않는다. 한 번 만든 객체의 값은 바뀌지 않는다.
//   JSON   : 스프링이 이 객체를 JSON 으로 바꿀 때 필드 이름이 JSON 의 이름이 된다.
public record MeetingResponse(String teamName, Long bookId, String bookTitle, String stage, List<String> chapters,
                              boolean live, List<TeamMessageResponse> messages, List<ChatMessageResponse> bossNotes) {
}
