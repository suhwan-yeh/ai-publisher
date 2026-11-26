/*
 * [1] 역할
 *     사장님과 쭌이 주고받은 대화 메시지를 다루는 Repository 다.
 *     ChatMessage 엔티티를 DB 의 chat_message 표에 저장하고 꺼낸다.
 *
 * [2] 받는 것 → 내보내는 것 (실제로 실행해서 얻은 값)
 *     메서드 이름으로 SQL 만들기 (스프링 데이터 JPA 가 메서드 이름을 읽어 실행할 때 SQL 을 만든다)
 *       findBy…        select … where …              existsBy…   select … 있으면 true
 *       countBy…       select count(…) where …       Top20       fetch first 20 rows only (20개만)
 *       And            조건 두 개를 and 로 연결        Between     between ? and ?
 *       After          > ?                           OrderBy…Asc / Desc   order by … asc / desc
 *
 * [3] 앞뒤 파일
 *     service/ChatService.java, service/OfficeService.java, service/DashboardService.java, scan/TranscriptScanner.java  →  (이 파일)  →  DB 의 chat_message 표
 *
 * [4] 메서드 목록
 *     메서드                                   실행되는 SQL (요약)                                              흐름 번호
 *     save(엔티티)  (JpaRepository 에 들어 있음)   insert into chat_message (…) values (…)                          흐름 B-④
 *     existsByUniqueKey(키)                    select … where unique_key=? (있으면 true)                         흐름 F
 *     findByAtBetweenOrderByAtAsc(시작, 끝)      … where at between ? and ? order by at
 *     findByUniqueKey(키)                       … where unique_key=?
 *     findTop200ByOrderByAtDescIdDesc()        … order by at desc, id desc fetch first 200 rows only              흐름 B′-③
 *     findTop5ByDirectionOrderByAtDesc(방향)     … where direction=? order by at desc fetch first 5 rows only
 *
 * [5] 먼저 알 용어 (자세한 설명: docs/용어-풀이.md)
 *     interface, extends, JpaRepository, 메서드 이름 쿼리, Optional, List
 *
 * [6] 읽는 순서
 *     extends 줄 설명 → 메서드를 위에서 아래로 (각 메서드 위에 실제 SQL)
 *
 * [7] 다 읽고 확인
 *     - 메서드 이름을 findTop200ByOrderByAtDesc 로 바꾸면 SQL 의 order by 는 어떻게 바뀌는가?
 *     - save() 는 이 파일에 적혀 있지 않은데 ChatService 에서 쓸 수 있다. 어디에서 온 메서드인가?
 */
package com.greendesk.publisher.repository;

import com.greendesk.publisher.domain.ChatMessage;
import org.springframework.data.jpa.repository.JpaRepository;

import java.time.Instant;
import java.util.List;

// public interface XxxRepository extends JpaRepository<엔티티, Long>
//   뜻     : 이 인터페이스에는 구현 코드가 없다. 스프링 데이터 JPA 가 프로그램 시작 때 구현 객체를 자동으로 만들어 스프링에 등록한다.
//   받는 것: <엔티티 클래스, 그 엔티티의 @Id 자료형>
//   결과   : save(엔티티), findById(번호), findAll(), count(), delete(엔티티) 같은 메서드를 따로 적지 않아도 쓸 수 있다.
//            save 의 SQL 예: insert into chat_message (at,attachment_paths,…,unique_key,id) values (?,?,?,?,?,?,?,?,default)
//   없으면(extends 를 지우면): 구현이 만들어지지 않아 이 Repository 를 쓰는 서비스를 만들 수 없고 프로그램 시작이 실패한다.
public interface ChatMessageRepository extends JpaRepository<ChatMessage, Long> {
    // existsBy + UniqueKey : unique_key 값이 같은 행이 있으면 true.  기록 파일을 다시 읽어도 같은 메시지를 두 번 저장하지 않으려고 쓴다.
    // 실제 SQL: select cm1_0.id from chat_message cm1_0 where cm1_0.unique_key=? fetch first ? rows only
    boolean existsByUniqueKey(String uniqueKey);

    // findBy + At + Between + OrderBy + At + Asc
    // 실제 SQL: select cm1_0.id,cm1_0.at,…,cm1_0.unique_key from chat_message cm1_0 where cm1_0.at between ? and ? order by cm1_0.at
    List<ChatMessage> findByAtBetweenOrderByAtAsc(Instant from, Instant to);

    // 모든 메시지를 시각 순서로.  SQL: … from chat_message cm1_0 order by cm1_0.at
    List<ChatMessage> findAllByOrderByAtAsc();

    // 결과가 0개 또는 1개이므로 Optional 로 받는다. (없으면 빈 Optional)
    // 실제 SQL: select cm1_0.id,…,cm1_0.unique_key from chat_message cm1_0 where cm1_0.unique_key=?
    java.util.Optional<ChatMessage> findByUniqueKey(String uniqueKey);

    // [흐름 B′-③] 최근 200개 (시각이 같으면 번호가 큰 것 먼저)
    // 실제 SQL: select cm1_0.id,cm1_0.at,…,cm1_0.unique_key from chat_message cm1_0 order by cm1_0.at desc,cm1_0.id desc fetch first ? rows only
    List<ChatMessage> findTop200ByOrderByAtDescIdDesc();

    // 방향(direction)이 같은 메시지 중 최근 5개.  회의실 메모 영역에 사장님 말 5개를 보여 줄 때 FROM_BOSS 를 넘긴다.
    // SQL: … from chat_message cm1_0 where cm1_0.direction=? order by cm1_0.at desc fetch first ? rows only
    List<ChatMessage> findTop5ByDirectionOrderByAtDesc(ChatMessage.Direction direction);
}
