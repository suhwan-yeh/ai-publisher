/*
 * [1] 역할
 *     책 한 권(= ~/my-publisher/books/ 아래 폴더 하나)을 나타내는 엔티티다. DB 의 book 표의 행 하나와 대응한다.
 *     값은 scan/BookScanner.java 가 책 폴더의 파일들을 읽어 채운다.
 *
 * [2] 받는 것 → 내보내는 것 (실제로 실행해서 얻은 값)
 *     책 폴더   /root/my-publisher/books/20261109-dogwalk  (plan/title.txt, manuscript/01.md …, dist/book.pdf)
 *     자바 객체 Book(id=3, folder="20261109-dogwalk", title="꼬리 살랑, 첫 산책", genre="실용서", stage=DONE, chapterCount=3, …)
 *     DB 의 행  book 표: id=3, folder='20261109-dogwalk', title='꼬리 살랑, 첫 산책', stage='DONE', …
 *
 * [3] 앞뒤 파일
 *     scan/BookScanner.java (저장·갱신)  →  (이 파일)  →  repository/BookRepository.java
 *     화면에서 쓰는 곳: service/BookView.java, dto/BookSummaryResponse.java, templates/index.html·book.html
 *
 * [4] 필드와 메서드 목록
 *     필드            DB 열            자료형           뜻                                          예
 *     id              id               Long             번호                                        3
 *     folder          folder           String           책 폴더 이름 (중복 불가)                      "20261109-dogwalk"
 *     title           title            String           제목 (plan/title.txt 1번째 줄)               "꼬리 살랑, 첫 산책"
 *     subtitle        subtitle         String           부제 (2번째 줄)
 *     genre           genre            String           장르                                        "실용서"
 *     stage           stage            Stage(enum)      진행 단계                                    DONE
 *     chapterCount    chapter_count    int              원고 장 수                                   3
 *     charCount       char_count       int              원고 글자 수
 *     createdAt       created_at       Instant          책 폴더가 생긴 시각
 *     updatedAt       updated_at       Instant          마지막으로 바뀐 시각
 *     files           (book_file 표)   List<BookFile>   완성 파일 목록 (PDF·EPUB·HTML·표지)
 *
 *     메서드              하는 일
 *     hasFile(종류)       그 종류의 완성 파일이 있는가
 *     displayTitle()      제목이 있으면 제목, 없으면 폴더 이름
 *
 * [5] 먼저 알 용어 (자세한 설명: docs/용어-풀이.md)
 *     @Entity, @Id, @GeneratedValue, @Column, @Enumerated, @OneToMany, @OrderBy, getter/setter
 *
 * [6] 읽는 순서
 *     필드 → @OneToMany 관계 → hasFile() → displayTitle()
 *
 * [7] 다 읽고 확인
 *     - 제목이 아직 정해지지 않은 책은 화면에 어떻게 표시되는가?
 *     - files 필드는 book 표의 열인가, 다른 표인가? (book_file 표. book_id 열로 연결된다)
 */
package com.greendesk.publisher.domain;

import jakarta.persistence.*;

import java.time.Instant;
import java.util.ArrayList;
import java.util.List;

/** 책 한 권 = books/ 아래 폴더 하나 */
// @Entity
//   뜻     : 이 클래스의 객체 하나가 DB 표의 행 하나에 대응한다. JPA(Hibernate)가 객체와 행을 서로 바꿔 준다.
//   결과   : Repository 의 save(객체) 가 insert/update SQL 로, find…() 가 select SQL 의 결과를 이 클래스의 객체로 바꾼다.
//   없으면 : JPA 가 이 클래스를 모른다. 이 엔티티를 다루는 Repository 를 만들 수 없어 프로그램 시작이 실패한다.
@Entity
@Table(name = "book")
public class Book {

    // @Id                                          이 필드가 행을 구별하는 기본 키(primary key)다.
    // @GeneratedValue(strategy = GenerationType.IDENTITY)
    //                                              번호는 DB 가 정한다. insert SQL 의 id 자리에 default 가 들어가고,
    //                                              저장이 끝나면 DB 가 정한 번호가 이 필드에 채워진다.   예) 103
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    // folder 는 비어 있으면 안 되고, 같은 폴더 이름의 행이 두 개 있으면 안 된다.
    @Column(nullable = false, unique = true)
    private String folder;

    private String title;
    private String subtitle;
    private String genre;

    // @Enumerated(EnumType.STRING)
    //   enum 값을 DB 에 이름 글자로 저장한다.   예) FROM_BOSS → 'FROM_BOSS'
    //   없으면(기본값 ORDINAL): 순서 번호(0, 1, …)로 저장된다. enum 순서를 바꾸면 기존 데이터의 뜻이 달라진다.
    @Enumerated(EnumType.STRING)
    // 새 책의 처음 단계는 ORDERED(주문 접수).
    private Stage stage = Stage.ORDERED;

    private int chapterCount;
    private int charCount;
    private Instant createdAt;
    private Instant updatedAt;

    // @OneToMany : 책 하나(One)에 완성 파일 여러 개(Many). 실제 연결 정보는 book_file 표의 book_id 열에 있다.
    //   mappedBy = "book"       BookFile 클래스의 book 필드가 연결을 관리한다는 뜻
    //   cascade = ALL           책을 저장하면 목록 안의 파일 행도 함께 저장한다
    //   orphanRemoval = true    목록에서 빠진 파일은 DB 에서도 지운다
    //   fetch = EAGER           책을 읽을 때 파일 목록도 바로 함께 읽는다
    @OneToMany(mappedBy = "book", cascade = CascadeType.ALL, orphanRemoval = true, fetch = FetchType.EAGER)
    // 목록을 kind(파일 종류) 순서로 정렬해 읽는다.
    @OrderBy("kind ASC")
    private List<BookFile> files = new ArrayList<>();

    protected Book() {
    }

    public Book(String folder) {
        this.folder = folder;
    }

    public boolean hasFile(BookFile.Kind kind) {
        // 파일 목록 중 종류가 같은 것이 하나라도 있으면 true.  타임리프: ${v.book().hasFile(…PDF)}
        return files.stream().anyMatch(f -> f.getKind() == kind);
    }

    public String displayTitle() {
        // 제목이 있고 비어 있지 않으면 제목, 아니면 폴더 이름.   예) title=null → "20261109-dinosaur"
        return title != null && !title.isBlank() ? title : folder;
    }

    // getter·setter: 필드 값을 꺼내고 바꾸는 메서드. JPA 와 타임리프가 이 메서드로 값에 접근한다.
    public Long getId() { return id; }
    public String getFolder() { return folder; }
    public String getTitle() { return title; }
    public void setTitle(String title) { this.title = title; }
    public String getSubtitle() { return subtitle; }
    public void setSubtitle(String subtitle) { this.subtitle = subtitle; }
    public String getGenre() { return genre; }
    public void setGenre(String genre) { this.genre = genre; }
    public Stage getStage() { return stage; }
    public void setStage(Stage stage) { this.stage = stage; }
    public int getChapterCount() { return chapterCount; }
    public void setChapterCount(int chapterCount) { this.chapterCount = chapterCount; }
    public int getCharCount() { return charCount; }
    public void setCharCount(int charCount) { this.charCount = charCount; }
    public Instant getCreatedAt() { return createdAt; }
    public void setCreatedAt(Instant createdAt) { this.createdAt = createdAt; }
    public Instant getUpdatedAt() { return updatedAt; }
    public void setUpdatedAt(Instant updatedAt) { this.updatedAt = updatedAt; }
    public List<BookFile> getFiles() { return files; }
}
