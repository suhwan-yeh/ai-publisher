/*
 * [1] 역할
 *     GET /api/staff 응답의 한 줄이다. 직원 명부(staff.yml)의 한 사람을 화면에 필요한 값만 담아 내보낸다.
 *
 * [2] 받는 것 → 내보내는 것 (실제로 실행해서 얻은 값)
 *     받는 것        domain/StaffMember(name="minjun", korean="민준", role="기획", agent="planner", team="book", color="#5b8cff")
 *     내보내는 것    {"name":"minjun","korean":"민준","role":"기획","team":"book","color":"#5b8cff"}
 *
 * [3] 앞뒤 파일
 *     domain/StaffMember.java  →  (이 파일)  →  api/OfficeApiController.java 의 staff()  →  static/js/people.js
 *
 * [4] 필드와 메서드 목록
 *     필드     자료형   뜻                         예
 *     name     String   영문 이름                   "minjun"
 *     korean   String   한글 이름                   "민준"
 *     role     String   역할                       "기획"
 *     team     String   lead · book · ops          "book"
 *     color    String   화면에서 쓰는 색 (16진수)     "#5b8cff"
 *
 *     메서드   하는 일
 *     from()   StaffMember 를 받아 StaffResponse 를 만든다 (agent 필드는 화면에 필요 없어서 옮기지 않는다)
 *
 * [5] 먼저 알 용어 (자세한 설명: docs/용어-풀이.md)
 *     record, static 메서드
 *
 * [6] 읽는 순서
 *     필드 목록 → from()
 *
 * [7] 다 읽고 확인
 *     - StaffMember 에는 있고 StaffResponse 에는 없는 필드는 무엇인가?
 *     - people.js 는 team 값이 "ops" 인 사람의 책상을 어느 영역에 넣는가? (office.js 의 buildDesk: 서버실)
 */
package com.greendesk.publisher.dto;

import com.greendesk.publisher.domain.StaffMember;

/** GET /api/staff 응답 한 줄: 직원 명부의 한 사람 (화면이 색·자리를 정할 때 씀) */
// record
//   뜻     : 값만 담는 클래스를 짧게 선언하는 자바 문법이다. 괄호 안에 적은 이름들이 필드가 된다.
//   결과   : 자바가 생성자, 필드 값을 꺼내는 메서드(예: text()), equals, toString 을 자동으로 만든다.
//            값을 바꾸는 메서드(setter)는 만들지 않는다. 한 번 만든 객체의 값은 바뀌지 않는다.
//   JSON   : 스프링이 이 객체를 JSON 으로 바꿀 때 필드 이름이 JSON 의 이름이 된다.
public record StaffResponse(String name, String korean, String role, String team, String color) {

    public static StaffResponse from(StaffMember s) {
        // s.name() 처럼 record 의 필드 값은 "필드이름()" 으로 꺼낸다.   예) s.name() = "minjun"
        return new StaffResponse(s.name(), s.korean(), s.role(), s.team(), s.color());
    }
}
