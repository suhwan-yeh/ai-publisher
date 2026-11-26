/*
 * [1] 역할
 *     책의 완성 파일 하나(PDF, EPUB, HTML, 표지)를 나타내는 엔티티다. DB 의 book_file 표와 대응한다.
 *     파일 종류별 위치·이름·형식은 안쪽 enum Kind 에 정해 둔다.
 *
 * [2] 받는 것 → 내보내는 것 (실제로 실행해서 얻은 값)
 *     자바 객체  BookFile(id=7, book=Book(3), kind=PDF, size=407549)
 *     DB 의 행   book_file 표: id=7, book_id=3, kind='PDF', size=407549
 *
 * [3] 앞뒤 파일
 *     scan/BookScanner.java (책 폴더의 dist/·design/ 을 보고 만든다)  →  (이 파일)  →  domain/Book.java 의 files 목록
 *     쓰는 곳: service/DashboardService.java 의 download() (Kind 의 경로·형식), templates/book.html (sizeLabel())
 *
 * [4] enum 과 필드 목록
 *     enum Kind    상대 경로              화면 이름        Content-Type
 *     PDF          dist/book.pdf          PDF 책          application/pdf
 *     EPUB         dist/book.epub         EPUB 전자책     application/epub+zip
 *     HTML         dist/book.html         HTML(인쇄용)    text/html
 *     COVER        design/cover.svg       표지 그림        image/svg+xml
 *
 *     필드     DB 열     뜻
 *     id       id        번호
 *     book     book_id   어느 책의 파일인가 (book 표의 id)
 *     kind     kind      파일 종류
 *     size     size      파일 크기(바이트)
 *
 * [5] 먼저 알 용어 (자세한 설명: docs/용어-풀이.md)
 *     enum (필드와 생성자를 가진 enum), @ManyToOne, @Enumerated
 *
 * [6] 읽는 순서
 *     enum Kind → 필드 → sizeLabel()
 *
 * [7] 다 읽고 확인
 *     - 새 종류(예: 오디오북 mp3)를 추가하려면 이 파일의 어디를 고치면 되는가?
 *     - 주소 /download/3/secret 은 왜 404 가 되는가? (Kind 에 SECRET 이 없어 valueOf 가 실패한다)
 */
package com.greendesk.publisher.domain;

import jakarta.persistence.*;

/** 완성 파일 (PDF, EPUB, HTML, 표지) */
// @Entity
//   뜻     : 이 클래스의 객체 하나가 DB 표의 행 하나에 대응한다. JPA(Hibernate)가 객체와 행을 서로 바꿔 준다.
//   결과   : Repository 의 save(객체) 가 insert/update SQL 로, find…() 가 select SQL 의 결과를 이 클래스의 객체로 바꾼다.
//   없으면 : JPA 가 이 클래스를 모른다. 이 엔티티를 다루는 Repository 를 만들 수 없어 프로그램 시작이 실패한다.
@Entity
@Table(name = "book_file")
public class BookFile {

    // 필드와 생성자를 가진 enum. 상수마다 (상대 경로, 화면 이름, Content-Type) 세 값을 함께 갖는다.
    //   예) Kind.PDF.getRelativePath() = "dist/book.pdf", Kind.PDF.getMediaType() = "application/pdf"
    public enum Kind {
        PDF("dist/book.pdf", "PDF 책", "application/pdf"),
        EPUB("dist/book.epub", "EPUB 전자책", "application/epub+zip"),
        HTML("dist/book.html", "HTML(인쇄용)", "text/html"),
        COVER("design/cover.svg", "표지 그림", "image/svg+xml");

        private final String relativePath;
        private final String label;
        private final String mediaType;

        Kind(String relativePath, String label, String mediaType) {
            this.relativePath = relativePath;
            this.label = label;
            this.mediaType = mediaType;
        }

        public String getRelativePath() { return relativePath; }
        public String getLabel() { return label; }
        public String getMediaType() { return mediaType; }
    }

    // @Id                                          이 필드가 행을 구별하는 기본 키(primary key)다.
    // @GeneratedValue(strategy = GenerationType.IDENTITY)
    //                                              번호는 DB 가 정한다. insert SQL 의 id 자리에 default 가 들어가고,
    //                                              저장이 끝나면 DB 가 정한 번호가 이 필드에 채워진다.   예) 103
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    // @ManyToOne : 파일 여러 개(Many)가 책 하나(One)에 속한다. DB 에는 book_id 열(book 표의 id)로 저장된다.
    //   optional = false : 책이 없는 파일 행은 만들 수 없다.
    @ManyToOne(optional = false)
    private Book book;

    // @Enumerated(EnumType.STRING)
    //   enum 값을 DB 에 이름 글자로 저장한다.   예) FROM_BOSS → 'FROM_BOSS'
    //   없으면(기본값 ORDINAL): 순서 번호(0, 1, …)로 저장된다. enum 순서를 바꾸면 기존 데이터의 뜻이 달라진다.
    @Enumerated(EnumType.STRING)
    private Kind kind;

    private long size;

    // protected 기본 생성자 (매개변수 없는 생성자)
    //   JPA 가 DB 에서 읽은 행으로 객체를 만들 때 이 생성자를 쓴다. 우리 코드에서 직접 쓰지 않도록 protected 로 둔다.
    //   없으면: select 결과를 객체로 만들 수 없어 오류가 난다.
    protected BookFile() {
    }

    public BookFile(Book book, Kind kind, long size) {
        this.book = book;
        this.kind = kind;
        this.size = size;
    }

    public Long getId() { return id; }
    public Book getBook() { return book; }
    public Kind getKind() { return kind; }
    public long getSize() { return size; }
    public void setSize(long size) { this.size = size; }
    public String sizeLabel() {
        // 1MB(1024×1024 바이트) 이상이면 소수 한 자리 MB, 아니면 KB.   예) 407549 → "397KB"
        return size >= 1024 * 1024 ? String.format("%.1fMB", size / 1024.0 / 1024.0) : (size / 1024 + "KB");
    }
}
