/*
 * [1] 역할
 *     직원끼리(그리고 직원과 쭌 사이) 주고받은 메시지 한 건을 나타내는 엔티티다.
 *     Claude Code 의 SendMessage 도구 호출 하나가 대화 기록에 남으면, TranscriptScanner 가 한 행으로 저장한다.
 *
 * [2] 받는 것 → 내보내는 것 (실제로 실행해서 얻은 값)
 *     대화 기록의 한 줄(요약)  {"type":"assistant","message":{"content":[{"type":"tool_use","name":"SendMessage","input":{"to":"jihun","message":"민준이야. …"}}]}}
 *     DB 의 행                 team_message 표: id=41, team_name='session-…', from_name='minjun', to_name='jihun', kind='TALK', text='민준이야. …'
 *
 * [3] 앞뒤 파일
 *     scan/TranscriptScanner.java 의 teamMessage()  →  (이 파일)  →  repository/TeamMessageRepository.java
 *     화면으로 나갈 때: dto/TeamMessageResponse.java
 *
 * [4] 필드와 메서드 목록
 *     필드         DB 열         뜻
 *     id           id            번호
 *     uniqueKey    unique_key    도구 호출 번호 (중복 저장 방지)
 *     teamName     team_name     팀 이름
 *     fromName     from_name     보낸 사람 영문 이름
 *     toName       to_name       받는 사람 영문 이름
 *     text         text          메시지 글자 (@Lob)
 *     kind         kind          TALK(대화) · REPORT([보고]) · CONTROL(종료 요청 같은 시스템 메시지)
 *     at           at            보낸 시각
 *
 *     메서드          하는 일
 *     isPeerTalk()    직원끼리 직접 주고받은 대화인가 (점검 ②)
 *
 * [5] 먼저 알 용어 (자세한 설명: docs/용어-풀이.md)
 *     @Entity, @Lob, @Enumerated, enum
 *
 * [6] 읽는 순서
 *     필드 → isPeerTalk()
 *
 * [7] 다 읽고 확인
 *     - 쭌이 민준에게 보낸 메시지는 isPeerTalk() 가 true 인가?
 *     - kind 가 CONTROL 인 메시지는 점검 ②에 포함되는가?
 */
package com.greendesk.publisher.domain;

import jakarta.persistence.*;

import java.time.Instant;

/** 팀원 ↔ 팀원, 팀원 ↔ 쭌 사이의 메시지 (SendMessage 도구 호출) */
// @Entity
//   뜻     : 이 클래스의 객체 하나가 DB 표의 행 하나에 대응한다. JPA(Hibernate)가 객체와 행을 서로 바꿔 준다.
//   결과   : Repository 의 save(객체) 가 insert/update SQL 로, find…() 가 select SQL 의 결과를 이 클래스의 객체로 바꾼다.
//   없으면 : JPA 가 이 클래스를 모른다. 이 엔티티를 다루는 Repository 를 만들 수 없어 프로그램 시작이 실패한다.
@Entity
@Table(name = "team_message")
public class TeamMessage {

    // enum Kind: TALK = 일반 대화, REPORT = [보고] 또는 직원 → 쭌, CONTROL = 종료 요청 같은 시스템 메시지
    public enum Kind {TALK, REPORT, CONTROL}

    // @Id                                          이 필드가 행을 구별하는 기본 키(primary key)다.
    // @GeneratedValue(strategy = GenerationType.IDENTITY)
    //                                              번호는 DB 가 정한다. insert SQL 의 id 자리에 default 가 들어가고,
    //                                              저장이 끝나면 DB 가 정한 번호가 이 필드에 채워진다.   예) 103
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, unique = true)
    private String uniqueKey;

    private String teamName;
    private String fromName;
    private String toName;

    // @Lob : 긴 글자 열.
    @Lob
    private String text;

    // @Enumerated(EnumType.STRING)
    //   enum 값을 DB 에 이름 글자로 저장한다.   예) FROM_BOSS → 'FROM_BOSS'
    //   없으면(기본값 ORDINAL): 순서 번호(0, 1, …)로 저장된다. enum 순서를 바꾸면 기존 데이터의 뜻이 달라진다.
    @Enumerated(EnumType.STRING)
    private Kind kind;

    private Instant at;

    // protected 기본 생성자 (매개변수 없는 생성자)
    //   JPA 가 DB 에서 읽은 행으로 객체를 만들 때 이 생성자를 쓴다. 우리 코드에서 직접 쓰지 않도록 protected 로 둔다.
    //   없으면: select 결과를 객체로 만들 수 없어 오류가 난다.
    protected TeamMessage() {
    }

    public TeamMessage(String uniqueKey, String teamName, String fromName, String toName, String text, Kind kind, Instant at) {
        this.uniqueKey = uniqueKey;
        this.teamName = teamName;
        this.fromName = fromName;
        this.toName = toName;
        this.text = text;
        this.kind = kind;
        this.at = at;
    }

    /** 직원끼리 직접 주고받은 의논인가 (쭌을 거치지 않음) */
    public boolean isPeerTalk() {
        // 종류가 TALK 이고, 보낸 사람과 받는 사람이 모두 직원(쭌이 아님)이면 true.
        return kind == Kind.TALK && Names.isStaff(fromName) && Names.isStaff(toName);
    }

    public Long getId() { return id; }
    public String getUniqueKey() { return uniqueKey; }
    public String getTeamName() { return teamName; }
    public String getFromName() { return fromName; }
    public String getToName() { return toName; }
    public String getText() { return text; }
    public Kind getKind() { return kind; }
    public Instant getAt() { return at; }
    public String fromKorean() { return Names.korean(fromName); }
    public String toKorean() { return Names.korean(toName); }
}
