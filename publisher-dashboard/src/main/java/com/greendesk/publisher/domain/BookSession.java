/*
 * [1] 역할
 *     어느 팀(쭌의 Claude 세션)이 어느 책 폴더를 다뤘는지 기록하는 엔티티다. DB 의 book_session 표와 대응한다.
 *     대화 기록 속에 "books/20261109-dogwalk/…" 같은 경로가 나오면 TranscriptScanner 가 한 행을 저장한다.
 *
 * [2] 받는 것 → 내보내는 것 (실제로 실행해서 얻은 값)
 *     DB 의 행  book_session 표: id=1, folder='20261109-dogwalk', team_name='session-bbaed2ce'
 *
 * [3] 앞뒤 파일
 *     scan/TranscriptScanner.java 의 linkBook()  →  (이 파일)  →  repository/BookSessionRepository.java  →  service/DashboardService.java 의 view()
 *
 * [4] 필드 목록
 *     필드       DB 열       뜻
 *     id         id          번호
 *     folder     folder      책 폴더 이름
 *     teamName   team_name   쭌의 세션 이름 ("session-" + 세션 번호 앞 8자리)
 *
 * [5] 먼저 알 용어 (자세한 설명: docs/용어-풀이.md)
 *     @Entity, @Table(uniqueConstraints)
 *
 * [6] 읽는 순서
 *     필드 → 생성자
 *
 * [7] 다 읽고 확인
 *     - 같은 (folder, team_name) 짝이 두 번 저장되지 않는 이유는 무엇인가?
 *     - 이 기록은 책별 메시지를 고를 때 어떻게 쓰이는가? (DashboardService.view() 의 고르는 방법 1)
 */
package com.greendesk.publisher.domain;

import jakarta.persistence.*;

/** 어느 팀(쭌의 세션)이 어느 책 폴더를 다뤘는지 (대화 기록 속 파일 경로로 찾음) */
// @Entity
//   뜻     : 이 클래스의 객체 하나가 DB 표의 행 하나에 대응한다. JPA(Hibernate)가 객체와 행을 서로 바꿔 준다.
//   결과   : Repository 의 save(객체) 가 insert/update SQL 로, find…() 가 select SQL 의 결과를 이 클래스의 객체로 바꾼다.
//   없으면 : JPA 가 이 클래스를 모른다. 이 엔티티를 다루는 Repository 를 만들 수 없어 프로그램 시작이 실패한다.
@Entity
// uniqueConstraints : (folder, teamName) 두 열의 짝이 같은 행은 두 개 있으면 안 된다.
@Table(name = "book_session", uniqueConstraints = @UniqueConstraint(columnNames = {"folder", "teamName"}))
public class BookSession {

    // @Id                                          이 필드가 행을 구별하는 기본 키(primary key)다.
    // @GeneratedValue(strategy = GenerationType.IDENTITY)
    //                                              번호는 DB 가 정한다. insert SQL 의 id 자리에 default 가 들어가고,
    //                                              저장이 끝나면 DB 가 정한 번호가 이 필드에 채워진다.   예) 103
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    private String folder;
    private String teamName;

    // protected 기본 생성자 (매개변수 없는 생성자)
    //   JPA 가 DB 에서 읽은 행으로 객체를 만들 때 이 생성자를 쓴다. 우리 코드에서 직접 쓰지 않도록 protected 로 둔다.
    //   없으면: select 결과를 객체로 만들 수 없어 오류가 난다.
    protected BookSession() {
    }

    public BookSession(String folder, String teamName) {
        this.folder = folder;
        this.teamName = teamName;
    }

    public String getFolder() { return folder; }
    public String getTeamName() { return teamName; }
}
