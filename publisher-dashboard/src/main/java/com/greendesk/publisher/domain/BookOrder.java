/*
 * [1] 역할
 *     관리 화면 첫 화면의 "새 책 주문하기"로 넣은 주문 한 건을 나타내는 엔티티다. DB 의 book_order 표와 대응한다.
 *
 * [2] 받는 것 → 내보내는 것 (실제로 실행해서 얻은 값)
 *     실제 SQL  insert into book_order (at,chat_key,text,id) values (?,?,?,default)
 *     DB 의 행   book_order 표: id=1, text='고양이 나오는 짧은 동화 써 줘', chat_key='web:web-…', at='2026-11-09 21:46:34'
 *
 * [3] 앞뒤 파일
 *     service/ChatService.java 의 order()  →  (이 파일)  →  repository/BookOrderRepository.java
 *
 * [4] 필드 목록
 *     필드      DB 열      자료형     뜻
 *     id        id         Long       번호
 *     text      text       String     주문 글 (@Lob: 긴 글자)
 *     chatKey   chat_key   String     같은 내용으로 저장된 대화 메시지의 unique_key (중복 불가)
 *     at        at         Instant    주문 시각
 *
 * [5] 먼저 알 용어 (자세한 설명: docs/용어-풀이.md)
 *     @Entity, @Id, @GeneratedValue, @Lob, @Column(unique)
 *
 * [6] 읽는 순서
 *     필드 → 생성자
 *
 * [7] 다 읽고 확인
 *     - 첫 화면 폼으로 주문하면 이 표와 chat_message 표 중 어디에 저장되는가? (둘 다. ChatService.order())
 *     - 대화방 입력칸에서 보낸 말은 이 표에 저장되는가? (아니다. send() 만 실행된다)
 */
package com.greendesk.publisher.domain;

import jakarta.persistence.*;

import java.time.Instant;

/** 관리 화면에서 넣은 책 주문 (사장님이 처음 한 말) */
// @Entity
//   뜻     : 이 클래스의 객체 하나가 DB 표의 행 하나에 대응한다. JPA(Hibernate)가 객체와 행을 서로 바꿔 준다.
//   결과   : Repository 의 save(객체) 가 insert/update SQL 로, find…() 가 select SQL 의 결과를 이 클래스의 객체로 바꾼다.
//   없으면 : JPA 가 이 클래스를 모른다. 이 엔티티를 다루는 Repository 를 만들 수 없어 프로그램 시작이 실패한다.
@Entity
@Table(name = "book_order")
public class BookOrder {

    // @Id                                          이 필드가 행을 구별하는 기본 키(primary key)다.
    // @GeneratedValue(strategy = GenerationType.IDENTITY)
    //                                              번호는 DB 가 정한다. insert SQL 의 id 자리에 default 가 들어가고,
    //                                              저장이 끝나면 DB 가 정한 번호가 이 필드에 채워진다.   예) 103
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    // @Lob : 긴 글자 열 (MySQL longtext).
    @Lob
    private String text;

    /** 쭌에게 보낸 메시지(ChatMessage.uniqueKey) */
    // chat_key 는 같은 값이 두 번 있으면 안 된다.
    @Column(unique = true)
    private String chatKey;

    private Instant at;

    // protected 기본 생성자 (매개변수 없는 생성자)
    //   JPA 가 DB 에서 읽은 행으로 객체를 만들 때 이 생성자를 쓴다. 우리 코드에서 직접 쓰지 않도록 protected 로 둔다.
    //   없으면: select 결과를 객체로 만들 수 없어 오류가 난다.
    protected BookOrder() {
    }

    public BookOrder(String text, String chatKey, Instant at) {
        this.text = text;
        this.chatKey = chatKey;
        this.at = at;
    }

    public Long getId() { return id; }
    public String getText() { return text; }
    public String getChatKey() { return chatKey; }
    public Instant getAt() { return at; }
}
