/*
 * [1] 역할
 *     직원끼리 주고받은 메시지 한 건을 응답 JSON 으로 내보낼 때의 모양이다. 메시지의 종류(지시·보고·의논·알림)도 여기서 정한다.
 *
 * [2] 받는 것 → 내보내는 것 (실제로 실행해서 얻은 값)
 *     받는 것        엔티티 TeamMessage(fromName="minjun", toName="jihun", kind=TALK, text="민준이야. 공룡 동화 기획 중이야. …")
 *     내보내는 것    {"id":41,"from":"minjun","fromKorean":"민준","to":"jihun","toKorean":"지훈","text":"민준이야. …","category":"의논","at":"…"}
 *
 * [3] 앞뒤 파일
 *     domain/TeamMessage.java  →  (이 파일)  →  dto/OfficeResponse.java, dto/MeetingResponse.java  →  static/js/office.js (봉투), meeting.js (말풍선·회의록)
 *
 * [4] 필드와 메서드 목록
 *     필드         자료형    뜻                          예
 *     id           Long      메시지 번호                   41
 *     from         String    보낸 사람 영문 이름            "minjun"
 *     fromKorean   String    보낸 사람 한글 이름            "민준"
 *     to           String    받는 사람 영문 이름            "jihun"
 *     toKorean     String    받는 사람 한글 이름            "지훈"
 *     text         String    메시지 글자                   "민준이야. …"
 *     category     String    지시 · 보고 · 의논 · 알림      "의논"
 *     at           Instant   보낸 시각
 *
 *     메서드       하는 일
 *     from()       엔티티 TeamMessage 를 받아 종류(category)를 정하고 TeamMessageResponse 를 만든다
 *
 * [5] 먼저 알 용어 (자세한 설명: docs/용어-풀이.md)
 *     record, static 메서드, if / else if / else, enum 비교(==), 논리 연산자 ||
 *
 * [6] 읽는 순서
 *     필드 목록 → from()
 *
 * [7] 다 읽고 확인
 *     - 쭌(team-lead)이 민준에게 보낸 메시지의 category 는 무엇인가?
 *     - 민준이 쭌에게 보낸 메시지는 kind 가 TALK 여도 "보고" 가 된다. 어느 조건 때문인가?
 */
package com.greendesk.publisher.dto;

import com.greendesk.publisher.domain.Names;
import com.greendesk.publisher.domain.TeamMessage;

import java.time.Instant;

/**
 * 직원끼리 주고받은 메시지 하나.
 * category: 지시(쭌 → 직원) · 보고(직원 → 쭌) · 의논(직원 ↔ 직원) · 알림(종료 요청 등)
 */
// record
//   뜻     : 값만 담는 클래스를 짧게 선언하는 자바 문법이다. 괄호 안에 적은 이름들이 필드가 된다.
//   결과   : 자바가 생성자, 필드 값을 꺼내는 메서드(예: text()), equals, toString 을 자동으로 만든다.
//            값을 바꾸는 메서드(setter)는 만들지 않는다. 한 번 만든 객체의 값은 바뀌지 않는다.
//   JSON   : 스프링이 이 객체를 JSON 으로 바꿀 때 필드 이름이 JSON 의 이름이 된다.
public record TeamMessageResponse(Long id, String from, String fromKorean, String to, String toKorean,
                                  String text, String category, Instant at) {

    // ▶ 받는 값: TeamMessage m (엔티티)      ▶ 돌려주는 값: TeamMessageResponse
    public static TeamMessageResponse from(TeamMessage m) {
        // 종류를 담을 변수. 아래 if 문에서 네 가지 중 하나가 들어간다. 위에서부터 차례로 검사하고, 처음 맞는 조건에서 끝난다.
        String category;
        // 조건 1: 메시지 종류가 CONTROL(종료 요청 같은 시스템 메시지)이면 "알림"
        if (m.getKind() == TeamMessage.Kind.CONTROL) category = "알림";
        // 조건 2: 보낸 사람이 쭌이면 "지시"      예) fromName="team-lead" → Names.isLead(…) = true
        else if (Names.isLead(m.getFromName())) category = "지시";
        // 조건 3: 종류가 REPORT 이거나( || 는 "또는"), 받는 사람이 쭌이면 "보고"
        //   예) fromName="taeyang", toName="team-lead" → "보고"
        else if (m.getKind() == TeamMessage.Kind.REPORT || Names.isLead(m.getToName())) category = "보고";
        // 위 세 조건에 모두 해당하지 않으면 직원끼리 주고받은 것이므로 "의논"      예) minjun → jihun
        else category = "의논";
        // 아래 두 줄로 객체를 만들어 return 한다.
        //   Names.canonical("minjun-2") = "minjun"    같은 사람의 다른 표기를 하나로 맞춘다.
        //   Names.korean("minjun")      = "민준"      영문 이름을 한글 이름으로 바꾼다.
        return new TeamMessageResponse(m.getId(), Names.canonical(m.getFromName()), Names.korean(m.getFromName()),
                Names.canonical(m.getToName()), Names.korean(m.getToName()), m.getText(), category, m.getAt());
    }
}
