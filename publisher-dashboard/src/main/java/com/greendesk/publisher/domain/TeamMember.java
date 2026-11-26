/*
 * [1] 역할
 *     에이전트 팀원(직원) 한 명을 나타내는 엔티티다. 대화 기록에 처음 나타난 시각과 마지막 활동 시각을 기록한다.
 *
 * [2] 받는 것 → 내보내는 것 (실제로 실행해서 얻은 값)
 *     DB 의 행  team_member 표: id=12, team_name='session-2d8e941e', name='jihun', role='자료 조사', first_seen='…21:01:52', last_active='…21:02:40'
 *
 * [3] 앞뒤 파일
 *     scan/TranscriptScanner.java 의 touchMember()  →  (이 파일)  →  repository/TeamMemberRepository.java
 *     쓰는 곳: service/BookView (점검 ①), service/OfficeService (마지막 활동), templates/team.html
 *
 * [4] 필드와 메서드 목록
 *     필드         DB 열         뜻
 *     id           id            번호
 *     teamName     team_name     팀(쭌의 세션) 이름
 *     name         name          영문 이름                     "jihun"
 *     role         role          역할                          "자료 조사"
 *     firstSeen    first_seen    기록에 처음 나타난 시각
 *     lastActive   last_active   마지막으로 활동한 시각
 *
 *     메서드          하는 일
 *     touch(시각)     처음·마지막 시각을 넓혀 갱신한다
 *     koreanName()    한글 이름 ("지훈")
 *
 * [5] 먼저 알 용어 (자세한 설명: docs/용어-풀이.md)
 *     @Entity, @Table(uniqueConstraints), Instant.isBefore / isAfter
 *
 * [6] 읽는 순서
 *     필드 → 생성자 → touch()
 *
 * [7] 다 읽고 확인
 *     - touch() 에 지금보다 예전 시각을 넣으면 lastActive 는 바뀌는가?
 *     - 한 사람이 두 팀(두 세션)에서 일하면 행은 몇 개인가?
 */
package com.greendesk.publisher.domain;

import jakarta.persistence.*;

import java.time.Instant;

/** 에이전트 팀원 (기록에 처음 나타난 시각과 마지막 활동 시각) */
// @Entity
//   뜻     : 이 클래스의 객체 하나가 DB 표의 행 하나에 대응한다. JPA(Hibernate)가 객체와 행을 서로 바꿔 준다.
//   결과   : Repository 의 save(객체) 가 insert/update SQL 로, find…() 가 select SQL 의 결과를 이 클래스의 객체로 바꾼다.
//   없으면 : JPA 가 이 클래스를 모른다. 이 엔티티를 다루는 Repository 를 만들 수 없어 프로그램 시작이 실패한다.
@Entity
// 같은 팀 안에서 같은 이름의 행은 하나뿐이다.
@Table(name = "team_member", uniqueConstraints = @UniqueConstraint(columnNames = {"teamName", "name"}))
public class TeamMember {

    // @Id                                          이 필드가 행을 구별하는 기본 키(primary key)다.
    // @GeneratedValue(strategy = GenerationType.IDENTITY)
    //                                              번호는 DB 가 정한다. insert SQL 의 id 자리에 default 가 들어가고,
    //                                              저장이 끝나면 DB 가 정한 번호가 이 필드에 채워진다.   예) 103
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    /** 팀 이름 (팀장 세션 단위, 예: session-18ecadb0) */
    private String teamName;
    /** 영문 이름 (minjun, jihun ...) */
    private String name;
    private String role;
    private Instant firstSeen;
    private Instant lastActive;

    // protected 기본 생성자 (매개변수 없는 생성자)
    //   JPA 가 DB 에서 읽은 행으로 객체를 만들 때 이 생성자를 쓴다. 우리 코드에서 직접 쓰지 않도록 protected 로 둔다.
    //   없으면: select 결과를 객체로 만들 수 없어 오류가 난다.
    protected TeamMember() {
    }

    public TeamMember(String teamName, String name, String role, Instant firstSeen) {
        this.teamName = teamName;
        this.name = name;
        this.role = role;
        this.firstSeen = firstSeen;
        this.lastActive = firstSeen;
    }

    // 기록에서 이 직원의 활동을 하나 발견할 때마다 호출한다. 기록을 시간 순서대로 읽지 않아도 맞게 갱신되도록 비교해서 넣는다.
    public void touch(Instant at) {
        if (at == null) return;
        // at 이 지금의 firstSeen 보다 이르면 firstSeen 을 바꾼다.
        if (firstSeen == null || at.isBefore(firstSeen)) firstSeen = at;
        // at 이 지금의 lastActive 보다 늦으면 lastActive 를 바꾼다.
        if (lastActive == null || at.isAfter(lastActive)) lastActive = at;
    }

    public String koreanName() {
        return Names.korean(name);
    }

    public Long getId() { return id; }
    public String getTeamName() { return teamName; }
    public String getName() { return name; }
    public String getRole() { return role; }
    public void setRole(String role) { this.role = role; }
    public Instant getFirstSeen() { return firstSeen; }
    public Instant getLastActive() { return lastActive; }
}
