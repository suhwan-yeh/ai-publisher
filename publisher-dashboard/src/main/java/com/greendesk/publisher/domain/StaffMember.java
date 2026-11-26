/*
 * [1] 역할
 *     직원 명부(staff.yml)의 한 사람을 담는 값 객체다. DB 에 저장하지 않는다(엔티티가 아니다).
 *
 * [2] 받는 것 → 내보내는 것 (실제로 실행해서 얻은 값)
 *     staff.yml 의 한 줄   - { name: minjun, korean: 민준, role: 기획, agent: planner, team: book, color: "#5b8cff" }
 *     자바 객체           StaffMember(name="minjun", korean="민준", role="기획", agent="planner", team="book", color="#5b8cff")
 *
 * [3] 앞뒤 파일
 *     config/StaffDirectory.java (staff.yml 을 읽어 만듦)  →  (이 파일)  →  domain/Names.java (등록), dto/StaffResponse.java
 *
 * [4] 필드 목록
 *     필드     뜻
 *     name     영문 이름 (Claude Code 팀원 이름)
 *     korean   한글 이름
 *     role     역할
 *     agent    .claude/agents/<agent>.md 에이전트 종류
 *     team     lead · book · ops
 *     color    화면 색
 *
 * [5] 먼저 알 용어 (자세한 설명: docs/용어-풀이.md)
 *     record
 *
 * [6] 읽는 순서
 *     필드 목록이 전부다.
 *
 * [7] 다 읽고 확인
 *     - 이 클래스에는 @Entity 가 없다. 이 값은 어디에 저장되는가? (staff.yml 파일. 실행 중에는 메모리)
 *     - 신입 직원을 추가할 때 이 클래스를 고쳐야 하는가? (아니다. staff.yml 에 한 줄만 추가한다)
 */
package com.greendesk.publisher.domain;

/**
 * 직원 명부(staff.yml)의 한 사람.
 * name  : 영문 이름 (Claude Code 팀원 이름과 같음)
 * agent : .claude/agents/<agent>.md 에이전트 종류
 * team  : book(책 만드는 팀) · ops(서버·배포 팀) · lead(편집장)
 */
// record: 값만 담는 클래스.
public record StaffMember(String name, String korean, String role, String agent, String team, String color) {
}
