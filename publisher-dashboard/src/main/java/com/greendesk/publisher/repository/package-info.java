/*
 * [1] 역할
 *     DB 에 넣고 꺼내는 JpaRepository 인터페이스 묶음. 메서드 이름만 적으면 Spring Data JPA 가 SQL 을 만든다.
 *
 * [2] 받는 것 → 내보내는 것 (실제로 실행해서 얻은 값)
 *     chats.existsByUniqueKey("web:web-…")
 *       → select cm1_0.id from chat_message cm1_0 where cm1_0.unique_key=? fetch first ? rows only
 *     chats.save(새 ChatMessage)
 *       → insert into chat_message (at,attachment_paths,attachments,channel,direction,team_name,text,unique_key,id) values (?,?,?,?,?,?,?,?,default)
 *
 * [3] 앞뒤 파일
 *     계층 (화살표 = 부르는 방향, 거꾸로 부르지 않는다)
 *       브라우저 → controller / api → service → repository → DB
 *                                       service → client → fakechat(쭌), tmux
 *       scan(시각에 맞춰 실행) → service → scan 의 읽기 클래스 → repository → DB
 *       dto  : api 가 JSON 으로 주고받는 모양     domain : DB 표와 대응하는 엔티티     config : 설정
 *
 * [4] 파일 목록
 *     ChatMessageRepository      chat_message 표
 *     BookRepository             book 표 (+ book_file)
 *     BookOrderRepository        book_order 표
 *     BookSessionRepository      book_session 표
 *     TeamMemberRepository       team_member 표
 *     TeamMessageRepository      team_message 표
 *
 * [5] 먼저 알 용어 (자세한 설명: docs/용어-풀이.md)
 *     interface, JpaRepository<엔티티, 키 자료형>, 메서드 이름 쿼리(findBy…, existsBy…, OrderBy…), Optional
 *
 * [6] 읽는 순서
 *     ChatMessageRepository → BookRepository → 나머지
 *
 * [7] 다 읽고 확인
 *     - 구현 클래스를 쓰지 않았는데 save() 가 동작하는 이유는?
 *     - existsByUniqueKey 가 만드는 SQL 의 "fetch first ? rows only" 는 무슨 뜻인가? (한 줄만 찾으면 멈춘다)
 */
package com.greendesk.publisher.repository;
