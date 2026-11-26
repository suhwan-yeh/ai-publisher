/*
 * [1] 역할
 *     책(책 폴더 하나)을 다루는 Repository 다.
 *     Book 엔티티를 DB 의 book 표에 저장하고 꺼낸다.
 *
 * [2] 받는 것 → 내보내는 것 (실제로 실행해서 얻은 값)
 *     메서드 이름으로 SQL 만들기 (스프링 데이터 JPA 가 메서드 이름을 읽어 실행할 때 SQL 을 만든다)
 *       findBy…        select … where …              existsBy…   select … 있으면 true
 *       countBy…       select count(…) where …       Top20       fetch first 20 rows only (20개만)
 *       And            조건 두 개를 and 로 연결        Between     between ? and ?
 *       After          > ?                           OrderBy…Asc / Desc   order by … asc / desc
 *
 * [3] 앞뒤 파일
 *     service/DashboardService.java, scan/BookScanner.java  →  (이 파일)  →  DB 의 book 표
 *
 * [4] 메서드 목록
 *     메서드                          실행되는 SQL (요약)
 *     findByFolder(폴더)               … from book b1_0 where b1_0.folder=?
 *     findAllByOrderByCreatedAtDesc()  … from book b1_0 order by b1_0.created_at desc
 *     findAllByOrderByCreatedAtAsc()   … from book b1_0 order by b1_0.created_at
 *
 * [5] 먼저 알 용어 (자세한 설명: docs/용어-풀이.md)
 *     interface, extends, JpaRepository, 메서드 이름 쿼리, Optional, List
 *
 * [6] 읽는 순서
 *     extends 줄 설명 → 메서드를 위에서 아래로 (각 메서드 위에 실제 SQL)
 *
 * [7] 다 읽고 확인
 *     - 같은 폴더 이름의 책이 두 개 생길 수 있는가? (Book 엔티티의 folder 에 unique = true 가 있다)
 *     - findByFolder 의 결과가 List 가 아니라 Optional 인 이유는 무엇인가?
 */
package com.greendesk.publisher.repository;

import com.greendesk.publisher.domain.Book;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

// public interface XxxRepository extends JpaRepository<엔티티, Long>
//   뜻     : 이 인터페이스에는 구현 코드가 없다. 스프링 데이터 JPA 가 프로그램 시작 때 구현 객체를 자동으로 만들어 스프링에 등록한다.
//   받는 것: <엔티티 클래스, 그 엔티티의 @Id 자료형>
//   결과   : save(엔티티), findById(번호), findAll(), count(), delete(엔티티) 같은 메서드를 따로 적지 않아도 쓸 수 있다.
//            save 의 SQL 예: insert into chat_message (at,attachment_paths,…,unique_key,id) values (?,?,?,?,?,?,?,?,default)
//   없으면(extends 를 지우면): 구현이 만들어지지 않아 이 Repository 를 쓰는 서비스를 만들 수 없고 프로그램 시작이 실패한다.
public interface BookRepository extends JpaRepository<Book, Long> {
    // 폴더 이름으로 책을 찾는다. 결과가 없을 수 있어 Optional.
    // 실제 SQL: select b1_0.id,b1_0.chapter_count,…,b1_0.updated_at from book b1_0 where b1_0.folder=?
    Optional<Book> findByFolder(String folder);

    // 만든 시각의 최신 순.  SQL: … order by b1_0.created_at desc
    List<Book> findAllByOrderByCreatedAtDesc();

    // 만든 시각의 오래된 순.  실제 SQL: select b1_0.id,b1_0.chapter_count,…,b1_0.updated_at from book b1_0 order by b1_0.created_at
    // (Asc 를 적지 않아도 기본은 오름차순이다)
    List<Book> findAllByOrderByCreatedAtAsc();
}
