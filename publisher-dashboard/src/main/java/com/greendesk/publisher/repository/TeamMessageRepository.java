/*
 * [1] 역할
 *     직원끼리(그리고 직원과 쭌 사이) 주고받은 메시지를 다루는 Repository 다.
 *     TeamMessage 엔티티를 DB 의 team_message 표에 저장하고 꺼낸다.
 *
 * [2] 받는 것 → 내보내는 것 (실제로 실행해서 얻은 값)
 *     메서드 이름으로 SQL 만들기 (스프링 데이터 JPA 가 메서드 이름을 읽어 실행할 때 SQL 을 만든다)
 *       findBy…        select … where …              existsBy…   select … 있으면 true
 *       countBy…       select count(…) where …       Top20       fetch first 20 rows only (20개만)
 *       And            조건 두 개를 and 로 연결        Between     between ? and ?
 *       After          > ?                           OrderBy…Asc / Desc   order by … asc / desc
 *
 * [3] 앞뒤 파일
 *     scan/TranscriptScanner.java (저장), service/DashboardService.java, service/OfficeService.java (조회)  →  (이 파일)  →  DB 의 team_message 표
 *
 * [4] 메서드 목록
 *     메서드                                       실행되는 SQL (요약)                                   흐름 번호
 *     existsByUniqueKey(키)                         … where unique_key=? (있으면 true)                     흐름 F
 *     findByAtBetweenOrderByAtAsc(시작, 끝)          … where at between ? and ? order by at
 *     findTopByOrderByAtDesc()                      … order by at desc fetch first 1 rows only
 *     findTop200ByTeamNameOrderByIdDesc(팀)          … where team_name=? order by id desc fetch first 200 rows only   흐름 E
 *     countByTeamNameAndFromName(팀, 보낸 사람)       select count(…) where team_name=? and from_name=?
 *
 * [5] 먼저 알 용어 (자세한 설명: docs/용어-풀이.md)
 *     interface, extends, JpaRepository, 메서드 이름 쿼리, Optional, List
 *
 * [6] 읽는 순서
 *     extends 줄 설명 → 메서드를 위에서 아래로 (각 메서드 위에 실제 SQL)
 *
 * [7] 다 읽고 확인
 *     - findTopByOrderByAtDesc 와 findTop200ByTeamNameOrderByIdDesc 의 Top 뒤 숫자는 각각 몇 개를 뜻하는가?
 *     - 사무실 출근부의 "보낸 메시지" 숫자는 이 파일의 어느 메서드로 얻는가?
 */
package com.greendesk.publisher.repository;

import com.greendesk.publisher.domain.TeamMessage;
import org.springframework.data.jpa.repository.JpaRepository;

import java.time.Instant;
import java.util.List;

// public interface XxxRepository extends JpaRepository<엔티티, Long>
//   뜻     : 이 인터페이스에는 구현 코드가 없다. 스프링 데이터 JPA 가 프로그램 시작 때 구현 객체를 자동으로 만들어 스프링에 등록한다.
//   받는 것: <엔티티 클래스, 그 엔티티의 @Id 자료형>
//   결과   : save(엔티티), findById(번호), findAll(), count(), delete(엔티티) 같은 메서드를 따로 적지 않아도 쓸 수 있다.
//            save 의 SQL 예: insert into chat_message (at,attachment_paths,…,unique_key,id) values (?,?,?,?,?,?,?,?,default)
//   없으면(extends 를 지우면): 구현이 만들어지지 않아 이 Repository 를 쓰는 서비스를 만들 수 없고 프로그램 시작이 실패한다.
public interface TeamMessageRepository extends JpaRepository<TeamMessage, Long> {
    // 같은 메시지를 두 번 저장하지 않으려고 저장 전에 확인한다.
    boolean existsByUniqueKey(String uniqueKey);

    // SQL: … from team_message tm1_0 where tm1_0.at between ? and ? order by tm1_0.at
    List<TeamMessage> findByAtBetweenOrderByAtAsc(Instant from, Instant to);

    // Top (숫자 없음) = 1개.  가장 최근 메시지 하나. 없으면 빈 Optional.
    java.util.Optional<TeamMessage> findTopByOrderByAtDesc();

    // [흐름 E] 한 팀의 최근 200개 (번호가 큰 것 먼저).
    List<TeamMessage> findTop200ByTeamNameOrderByIdDesc(String teamName);

    // countBy = 개수만 센다. 자료형 long.  SQL: select count(tm1_0.id) from team_message tm1_0 where tm1_0.team_name=? and tm1_0.from_name=?
    long countByTeamNameAndFromName(String teamName, String fromName);
}
