/*
 * [1] 역할
 *     사장님과 쭌이 주고받은 대화 메시지 한 건을 나타내는 엔티티다. DB 의 chat_message 표의 행 하나와 대응한다.
 *
 * [2] 받는 것 → 내보내는 것 (실제로 실행해서 얻은 값)
 *     자바 객체     ChatMessage(id=103, uniqueKey="web:web-1762724793776-a1b2c3", direction=FROM_BOSS, text="좋아요, 이대로 진행해 주세요.", channel="web")
 *     DB 의 행      chat_message 표: id=103, unique_key='web:web-…', direction='FROM_BOSS', text='좋아요, …', channel='web', at='2026-11-09 21:46:33.776008'
 *     서버(MySQL) 표 정의: src/main/resources/db/migration/V1__init.sql 의 create table chat_message
 *
 * [3] 앞뒤 파일
 *     service/ChatService.java (보낸 메시지 저장), scan/TranscriptScanner.java (기록에서 읽어 저장)  →  (이 파일)  →  repository/ChatMessageRepository.java
 *     화면으로 나갈 때: dto/ChatMessageResponse.java 로 바뀐다
 *
 * [4] 필드와 메서드 목록
 *     필드              DB 열               자료형      뜻                                             예
 *     id                id                  Long        번호 (DB 가 정함)                                103
 *     uniqueKey         unique_key          String      같은 메시지를 두 번 저장하지 않기 위한 고유 키       "web:web-1762724793776-a1b2c3"
 *     direction         direction           enum        FROM_BOSS(사장님 → 쭌) 또는 TO_BOSS(쭌 → 사장님)    FROM_BOSS
 *     text              text (longtext)     String      메시지 글자                                      "좋아요, 이대로 진행해 주세요."
 *     attachments       attachments         String      첨부 파일 이름들 (쉼표로 구분)                     "book.pdf"
 *     at                at                  Instant     보낸 시각
 *     teamName          team_name           String      이 메시지를 처리한 쭌의 세션                       "session-2d8e941e"
 *     channel           channel             String      web(관리 화면) 또는 telegram                      "web"
 *     attachmentPaths   attachment_paths    String      첨부 파일의 전체 경로 (줄바꿈으로 구분)
 *
 *     메서드                  하는 일
 *     withChannel(…)          channel 을 넣고 자기 자신을 돌려준다 (이어서 호출하기 위해)
 *     withAttachmentPaths(…)  경로 목록을 한 글자로 이어 저장한다
 *     assignTeam(…)           팀 이름이 비어 있을 때만 넣는다
 *     attachmentPathList()    저장된 경로 글자를 다시 목록으로 나눈다
 *     attachmentNameList()    경로에서 파일 이름만 남긴 목록 (화면 표시용)
 *     hasAttachments()        첨부가 있는가
 *     isReport()              쭌이 사장님께 보낸 보고인가 (점검 ③에 쓰임)
 *
 * [5] 먼저 알 용어 (자세한 설명: docs/용어-풀이.md)
 *     @Entity, @Table, @Id, @GeneratedValue, @Column, @Enumerated, @Lob, enum, protected 생성자
 *
 * [6] 읽는 순서
 *     클래스 위 어노테이션 → 필드 → 생성자 → with… 메서드 → 나머지
 *
 * [7] 다 읽고 확인
 *     - 같은 unique_key 로 두 번 저장하려 하면 DB 는 어떻게 하는가? (unique 제약 때문에 오류가 난다)
 *     - 엔티티를 그대로 JSON 으로 응답하지 않고 ChatMessageResponse 로 바꾸는 이유를 필드 attachmentPaths 로 설명해 보라.
 */
package com.greendesk.publisher.domain;

import jakarta.persistence.*;

import java.time.Instant;

/** 사장님 ↔ 쭌 (텔레그램 등 채널) 메시지 */
// @Entity
//   뜻     : 이 클래스의 객체 하나가 DB 표의 행 하나에 대응한다. JPA(Hibernate)가 객체와 행을 서로 바꿔 준다.
//   결과   : Repository 의 save(객체) 가 insert/update SQL 로, find…() 가 select SQL 의 결과를 이 클래스의 객체로 바꾼다.
//   없으면 : JPA 가 이 클래스를 모른다. 이 엔티티를 다루는 Repository 를 만들 수 없어 프로그램 시작이 실패한다.
@Entity
// @Table(name = "chat_message") : 이 엔티티가 대응하는 표 이름. 적지 않으면 클래스 이름으로 정해진다.
@Table(name = "chat_message")
public class ChatMessage {

    // enum Direction: 메시지 방향. FROM_BOSS = 사장님이 보냄, TO_BOSS = 쭌이 사장님께 보냄.
    public enum Direction {FROM_BOSS, TO_BOSS}

    // @Id                                          이 필드가 행을 구별하는 기본 키(primary key)다.
    // @GeneratedValue(strategy = GenerationType.IDENTITY)
    //                                              번호는 DB 가 정한다. insert SQL 의 id 자리에 default 가 들어가고,
    //                                              저장이 끝나면 DB 가 정한 번호가 이 필드에 채워진다.   예) 103
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    // @Column(nullable = false, unique = true) : 이 열은 비어 있으면 안 되고(not null), 같은 값이 두 번 있으면 안 된다(unique).
    @Column(nullable = false, unique = true)
    private String uniqueKey;

    // @Enumerated(EnumType.STRING)
    //   enum 값을 DB 에 이름 글자로 저장한다.   예) FROM_BOSS → 'FROM_BOSS'
    //   없으면(기본값 ORDINAL): 순서 번호(0, 1, …)로 저장된다. enum 순서를 바꾸면 기존 데이터의 뜻이 달라진다.
    @Enumerated(EnumType.STRING)
    private Direction direction;

    // @Lob : 긴 글자를 저장하는 열로 만든다. MySQL 에서는 longtext, H2 에서는 CLOB 형식이 된다.
    //        없으면 varchar(255) 가 되어 255자를 넘는 메시지를 저장할 때 오류가 난다.
    @Lob
    private String text;

    /** 함께 보낸 파일 이름들 (쉼표로 구분) */
    private String attachments;

    private Instant at;

    /** 이 메시지를 받은/보낸 쭌의 세션 */
    private String teamName;

    /** 어느 통로(채널)로 오갔나: web(관리 화면) / telegram */
    private String channel;

    /** 첨부 파일의 전체 경로 (줄바꿈으로 구분) — 관리 화면에서 내려받기용 */
    @Lob
    private String attachmentPaths;

    // protected 기본 생성자 (매개변수 없는 생성자)
    //   JPA 가 DB 에서 읽은 행으로 객체를 만들 때 이 생성자를 쓴다. 우리 코드에서 직접 쓰지 않도록 protected 로 둔다.
    //   없으면: select 결과를 객체로 만들 수 없어 오류가 난다.
    protected ChatMessage() {
    }

    // 우리 코드가 새 메시지를 만들 때 쓰는 생성자.  id 는 넣지 않는다(저장할 때 DB 가 정한다).
    // 예) new ChatMessage("web:web-…", null, Direction.FROM_BOSS, "좋아요, …", null, Instant.now())
    public ChatMessage(String uniqueKey, String teamName, Direction direction, String text, String attachments, Instant at) {
        this.teamName = teamName;
        this.uniqueKey = uniqueKey;
        this.direction = direction;
        this.text = text;
        this.attachments = attachments;
        this.at = at;
    }

    // channel 을 넣고 return this(자기 자신)를 돌려준다. 그래서 new ChatMessage(…).withChannel("web") 처럼 이어 쓸 수 있다.
    public ChatMessage withChannel(String channel) {
        this.channel = channel;
        return this;
    }

    public ChatMessage withAttachmentPaths(java.util.List<String> paths) {
        // 경로 목록을 줄바꿈 글자로 이어 한 글자로 저장한다. 목록이 비어 있으면 null.
        // 예) ["/a/book.pdf", "/a/book.epub"] → "/a/book.pdf\n/a/book.epub"
        this.attachmentPaths = paths == null || paths.isEmpty() ? null : String.join("\n", paths);
        return this;
    }

    /** 관리 화면에서 보낸 메시지가 쭌의 기록에서 확인되면 세션을 이어 붙인다 */
    public void assignTeam(String teamName) {
        // 관리 화면에서 보낸 메시지는 저장할 때 팀을 모른다(null). 나중에 쭌의 기록에서 이 메시지를 찾으면 그때 팀 이름을 채운다.
        if (this.teamName == null) this.teamName = teamName;
    }

    public java.util.List<String> attachmentPathList() {
        // 저장된 글자를 줄바꿈으로 나눠 목록으로 돌려준다. 없으면 빈 목록.  split("\n") = 줄바꿈 글자에서 나눈다.
        return attachmentPaths == null || attachmentPaths.isBlank() ? java.util.List.of() : java.util.List.of(attachmentPaths.split("\n"));
    }

    /** 첨부 파일 이름만 (화면 표시용) */
    public java.util.List<String> attachmentNameList() {
        // 경로마다 파일 이름만 남긴다.  예) "/a/b/book.pdf" → "book.pdf"  (chat.html 의 ⬇ 단추 글자에 쓰인다)
        return attachmentPathList().stream().map(p -> java.nio.file.Path.of(p).getFileName().toString()).toList();
    }

    public boolean hasAttachments() {
        return attachments != null && !attachments.isBlank();
    }

    /** 사장님께 드린 보고·제안인가 */
    public boolean isReport() {
        // 쭌 → 사장님 메시지이고, 글자에 [제안]·[최종 보고]·[보고]·📘 가 들어 있으면 보고로 센다.
        return direction == Direction.TO_BOSS && text != null
                && (text.contains("[제안]") || text.contains("[최종 보고]") || text.contains("[보고]") || text.contains("📘"));
    }

    // getter: 필드 값을 꺼내는 메서드. 타임리프에서 ${c.id} 라고 쓰면 c.getId() 가 호출된다.
    public Long getId() { return id; }
    public String getUniqueKey() { return uniqueKey; }
    public Direction getDirection() { return direction; }
    public String getText() { return text; }
    public String getAttachments() { return attachments; }
    public Instant getAt() { return at; }
    public String getTeamName() { return teamName; }
    public String getChannel() { return channel; }
}
