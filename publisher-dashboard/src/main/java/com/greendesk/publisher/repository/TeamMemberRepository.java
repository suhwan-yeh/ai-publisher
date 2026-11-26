/*
 * [1] 역할
 *     팀원(에이전트 직원)과 그 활동 시각을 다루는 Repository 다.
 *     TeamMember 엔티티를 DB 의 team_member 표에 저장하고 꺼낸다.
 *
 * [2] 받는 것 → 내보내는 것 (실제로 실행해서 얻은 값)
 *     메서드 이름으로 SQL 만들기 (스프링 데이터 JPA 가 메서드 이름을 읽어 실행할 때 SQL 을 만든다)
 *       findBy…        select … where …              existsBy…   select … 있으면 true
 *       countBy…       select count(…) where …       Top20       fetch first 20 rows only (20개만)
 *       And            조건 두 개를 and 로 연결        Between     between ? and ?
 *       After          > ?                           OrderBy…Asc / Desc   order by … asc / desc
 *
 * [3] 앞뒤 파일
 *     scan/TranscriptScanner.java, service/DashboardService.java, service/OfficeService.java  →  (이 파일)  →  DB 의 team_member 표
 *
 * [4] 메서드 목록
 *     메서드                                       실행되는 SQL (요약)
 *     findByTeamNameAndName(팀, 이름)               … where team_name=? and name=?
 *     findByLastActiveAfterOrderByNameAsc(시각)     … where last_active>? order by name
 *     findAllByOrderByLastActiveDesc()             … order by last_active desc
 *     findByTeamName(팀)                            … where team_name=?
 *
 * [5] 먼저 알 용어 (자세한 설명: docs/용어-풀이.md)
 *     interface, extends, JpaRepository, 메서드 이름 쿼리, Optional, List
 *
 * [6] 읽는 순서
 *     extends 줄 설명 → 메서드를 위에서 아래로 (각 메서드 위에 실제 SQL)
 *
 * [7] 다 읽고 확인
 *     - findByLastActiveAfter… 에 "2분 전" 시각을 넘기면 무엇을 얻는가?
 *     - 같은 팀에 같은 이름의 행이 두 개 생기지 않는 이유는 무엇인가? (TeamMember 의 uniqueConstraints)
 */
package com.greendesk.publisher.repository;

import com.greendesk.publisher.domain.TeamMember;
import org.springframework.data.jpa.repository.JpaRepository;

import java.time.Instant;
import java.util.List;
import java.util.Optional;

// public interface XxxRepository extends JpaRepository<엔티티, Long>
//   뜻     : 이 인터페이스에는 구현 코드가 없다. 스프링 데이터 JPA 가 프로그램 시작 때 구현 객체를 자동으로 만들어 스프링에 등록한다.
//   받는 것: <엔티티 클래스, 그 엔티티의 @Id 자료형>
//   결과   : save(엔티티), findById(번호), findAll(), count(), delete(엔티티) 같은 메서드를 따로 적지 않아도 쓸 수 있다.
//            save 의 SQL 예: insert into chat_message (at,attachment_paths,…,unique_key,id) values (?,?,?,?,?,?,?,?,default)
//   없으면(extends 를 지우면): 구현이 만들어지지 않아 이 Repository 를 쓰는 서비스를 만들 수 없고 프로그램 시작이 실패한다.
public interface TeamMemberRepository extends JpaRepository<TeamMember, Long> {
    // 팀과 이름이 모두 같은 직원 한 명.  SQL: … where tm1_0.team_name=? and tm1_0.name=?
    Optional<TeamMember> findByTeamNameAndName(String teamName, String name);

    // After = 그 시각보다 뒤.
    // 실제 SQL: select tm1_0.id,tm1_0.first_seen,tm1_0.last_active,tm1_0.name,tm1_0.role,tm1_0.team_name from team_member tm1_0 where tm1_0.last_active>? order by tm1_0.name
    List<TeamMember> findByLastActiveAfterOrderByNameAsc(Instant after);

    // 실제 SQL: select tm1_0.id,… from team_member tm1_0 order by tm1_0.last_active desc
    List<TeamMember> findAllByOrderByLastActiveDesc();

    // SQL: … where tm1_0.team_name=?
    List<TeamMember> findByTeamName(String teamName);
}
