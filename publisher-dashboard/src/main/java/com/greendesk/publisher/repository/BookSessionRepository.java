/*
 * [1] 역할
 *     어느 팀(쭌의 Claude 세션)이 어느 책 폴더를 다뤘는지를 다루는 Repository 다.
 *     BookSession 엔티티를 DB 의 book_session 표에 저장하고 꺼낸다.
 *
 * [2] 받는 것 → 내보내는 것 (실제로 실행해서 얻은 값)
 *     메서드 이름으로 SQL 만들기 (스프링 데이터 JPA 가 메서드 이름을 읽어 실행할 때 SQL 을 만든다)
 *       findBy…        select … where …              existsBy…   select … 있으면 true
 *       countBy…       select count(…) where …       Top20       fetch first 20 rows only (20개만)
 *       And            조건 두 개를 and 로 연결        Between     between ? and ?
 *       After          > ?                           OrderBy…Asc / Desc   order by … asc / desc
 *
 * [3] 앞뒤 파일
 *     scan/TranscriptScanner.java (저장), service/DashboardService.java (조회)  →  (이 파일)  →  DB 의 book_session 표
 *
 * [4] 메서드 목록
 *     메서드                                  실행되는 SQL (요약)
 *     existsByFolderAndTeamName(폴더, 팀)       … where folder=? and team_name=? (있으면 true)
 *     findByFolder(폴더)                        … where folder=?
 *
 * [5] 먼저 알 용어 (자세한 설명: docs/용어-풀이.md)
 *     interface, extends, JpaRepository, 메서드 이름 쿼리, Optional, List
 *
 * [6] 읽는 순서
 *     extends 줄 설명 → 메서드를 위에서 아래로 (각 메서드 위에 실제 SQL)
 *
 * [7] 다 읽고 확인
 *     - existsByFolderAndTeamName 은 왜 저장하기 전에 호출하는가?
 *     - 이 표가 없으면 DashboardService 는 책의 메시지를 어떤 방법으로 고르는가? (시간으로만 나눈다)
 */
package com.greendesk.publisher.repository;

import com.greendesk.publisher.domain.BookSession;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

// public interface XxxRepository extends JpaRepository<엔티티, Long>
//   뜻     : 이 인터페이스에는 구현 코드가 없다. 스프링 데이터 JPA 가 프로그램 시작 때 구현 객체를 자동으로 만들어 스프링에 등록한다.
//   받는 것: <엔티티 클래스, 그 엔티티의 @Id 자료형>
//   결과   : save(엔티티), findById(번호), findAll(), count(), delete(엔티티) 같은 메서드를 따로 적지 않아도 쓸 수 있다.
//            save 의 SQL 예: insert into chat_message (at,attachment_paths,…,unique_key,id) values (?,?,?,?,?,?,?,?,default)
//   없으면(extends 를 지우면): 구현이 만들어지지 않아 이 Repository 를 쓰는 서비스를 만들 수 없고 프로그램 시작이 실패한다.
public interface BookSessionRepository extends JpaRepository<BookSession, Long> {
    // And = 두 조건을 and 로 잇는다.  SQL: … where bs1_0.folder=? and bs1_0.team_name=?
    boolean existsByFolderAndTeamName(String folder, String teamName);

    // 한 책 폴더를 여러 팀이 다뤘을 수 있어 List 로 받는다.  SQL: … where bs1_0.folder=?
    List<BookSession> findByFolder(String folder);
}
