/*
 * [1] 역할
 *     books/ 아래 책 폴더 하나하나를 읽어 DB 의 book 표, book_file 표를 최신 상태로 맞춘다.
 *     폴더 안의 파일은 읽기만 하고 고치지 않는다. 폴더에 무엇이 있는지 보고 책의 단계(Stage)를 정한다.
 *
 * [2] 받는 것 → 내보내는 것 (실제로 실행해서 얻은 값)
 *     받는 것 (실제 폴더 /root/my-publisher/books/20261109-dogwalk):
 *       plan/order.md  plan/proposal.md  plan/title.txt
 *       manuscript/01.md 02.md 03.md     review/01.md 02.md 03.md
 *       design/cover.svg (1506바이트)     dist/book.pdf (389934)  book.epub (8560)  book.html (13337)
 *       plan/title.txt 의 두 줄:  "꼬리 살랑, 첫 산책" / "떨리는 마음도 괜찮아요, 천천히 함께 걷는 초보 보호자의 첫 산책 안내서"
 *       plan/order.md 안의 한 줄: "- 장르: 실용서 (주제에 맞춰 편집장이 정함)"
 *     내보내는 것 (DB 에 저장되어 GET /api/books 로 보이는 값):
 *       {"id":3,"folder":"20261109-dogwalk","title":"꼬리 살랑, 첫 산책","genre":"실용서","stage":"전자책 완성","chapters":3,"chars":2934,…}
 *     실제 SQL
 *       처음 본 폴더  insert into book (chapter_count,char_count,created_at,folder,genre,stage,subtitle,title,updated_at,id) values (?,?,?,?,?,?,?,?,?,default)
 *       이미 있는 책  update book set chapter_count=?,char_count=?,created_at=?,folder=?,genre=?,stage=?,subtitle=?,title=?,updated_at=? where id=?
 *       완성 파일     insert into book_file (book_id,kind,size,id) values (?,?,?,default)
 *
 * [3] 앞뒤 파일
 *     service/ScanService.java 의 scanNow()  →  (이 파일)  →  repository/BookRepository.java
 *     폴더 위치: config/PublisherProperties.java 의 booksPath()     단계 이름: domain/Stage.java     파일 종류: domain/BookFile.java
 *
 * [4] 메서드 목록
 *     메서드                         하는 일                                                  흐름 번호
 *     scan()                         books/ 아래 폴더마다 update() 를 부른다. 돌려줌: 폴더 수 예) 5   흐름 F-③
 *     update(폴더)                    한 권을 읽어 Book 객체를 채우고 저장한다                       흐름 F-③
 *     stageOf(폴더, 장 수, 책)         있는 파일을 보고 단계를 정한다            예) Stage.DONE
 *     findGenre(폴더)                 order.md / proposal.md 에서 "장르: …" 를 찾는다   예) "실용서"
 *     timeRange(폴더)                 가장 오래된·최근 파일 시각 [시작, 마지막]
 *     list(폴더, 확장자)               확장자가 맞는 파일 목록 (이름이 _ 로 시작하면 뺀다)
 *     readLines(파일)                 빈 줄을 뺀 줄 목록
 *     strip(글)                       "제목: " 같은 앞머리를 지운다
 *
 * [5] 먼저 알 용어 (자세한 설명: docs/용어-풀이.md)
 *     @Component, @Transactional, synchronized, Path·Files(java.nio), try-with-resources, Stream, Optional, 정규식(Pattern·Matcher), 람다, 메서드 참조(::)
 *
 * [6] 읽는 순서
 *     scan() → update() → stageOf() → 나머지 작은 메서드
 *
 * [7] 다 읽고 확인
 *     - design/cover.svg 만 있고 dist/ 가 비어 있으면 단계는 무엇인가? (Stage.COVER "표지 완료")
 *     - 책 폴더에서 dist/book.pdf 를 지우고 10초 기다리면 book_file 표에서 무슨 일이 생기는가?
 */
package com.greendesk.publisher.scan;

import com.greendesk.publisher.config.PublisherProperties;
import com.greendesk.publisher.domain.Book;
import com.greendesk.publisher.domain.BookFile;
import com.greendesk.publisher.domain.Stage;
import com.greendesk.publisher.repository.BookRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.time.Instant;
import java.util.List;
import java.util.Optional;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import java.util.stream.Stream;

/** books/ 폴더를 읽어 Book 엔티티를 최신 상태로 맞춘다 (파일은 읽기만 함) */
// @Component
//   뜻     : 스프링이 이 클래스의 객체를 하나 만들어 관리한다. ScanService 생성자에 자동으로 넘어간다.
@Component
public class BookScanner {

    private static final Logger log = LoggerFactory.getLogger(BookScanner.class);
    // GENRE: "장르" 다음의 글자를 찾는 정규식(글자 모양 규칙).
    //   장르\s*        "장르" 뒤에 공백이 0개 이상
    //   [:：은는]?      ":" 또는 전각 "：" 또는 "은"/"는" 이 있거나 없다
    //   \s*            공백 0개 이상
    //   ([^\n,.(/]{1,20})  줄바꿈·쉼표·마침표·괄호·슬래시가 아닌 글자 1~20개 → 이 부분이 group(1)
    // 예) "- 장르: 실용서 (주제에 맞춰 편집장이 정함)" → group(1) = "실용서 "  (뒤 공백은 trim() 으로 지운다)
    private static final Pattern GENRE = Pattern.compile("장르\\s*[:：은는]?\\s*([^\\n,.(/]{1,20})");

    // props: application.yml 의 publisher.* 설정. booksPath() 로 책 폴더 위치를 얻는다.  예) /root/my-publisher/books
    private final PublisherProperties props;
    // books: book 표를 다루는 Repository.
    private final BookRepository books;

    public BookScanner(PublisherProperties props, BookRepository books) {
        this.props = props;
        this.books = books;
    }

    // [흐름 F-③]
    // @Transactional
    //   뜻     : 메서드 안의 DB 작업을 하나로 묶는다. 끝까지 성공하면 한꺼번에 반영(commit)하고, 예외로 끝나면 모두 되돌린다(rollback).
    //   결과   : 책 다섯 권을 저장하는 SQL 이 한 번의 트랜잭션 안에서 실행된다.
    @Transactional
    // synchronized: 두 스레드가 동시에 이 메서드에 들어오지 못하게 한다.
    //   first() 와 tick() 이 겹쳐 실행돼도 같은 책을 두 번 insert 하지 않는다.
    public synchronized int scan() {
        // root 예) /root/my-publisher/books   (Path: 파일·폴더 경로를 나타내는 자바 자료형)
        Path root = props.booksPath();
        // 책 폴더가 아직 없으면(출판사를 처음 설치한 직후) 아무것도 하지 않고 0 을 돌려준다.
        if (!Files.isDirectory(root)) return 0;
        int n = 0;
        // try ( … ) : try-with-resources. 괄호 안에서 연 것을 블록이 끝날 때 자동으로 닫는다.
        // Files.list(root): root 바로 아래 항목들(파일·폴더)을 Stream 으로 준다. 하위 폴더 안까지는 들어가지 않는다.
        try (Stream<Path> dirs = Files.list(root)) {
            // (1) .filter(Files::isDirectory)  폴더만 남긴다. Files::isDirectory 는 p -> Files.isDirectory(p) 를 줄여 쓴 메서드 참조다.
            // (2) .sorted()                    이름순으로 정렬한다.
            // (3) .toList()                    List<Path> 로 모은다.
            // 예) [.../20261109-commutepoems, .../20261109-dinosaur, .../20261109-dogwalk, .../20261109-houseplants, .../20261109-rainyday]
            for (Path dir : dirs.filter(Files::isDirectory).sorted().toList()) {
                update(dir);
                n++;
            }
        } catch (IOException e) {
            // 읽기 실패는 로그만 남기고 넘어간다. 다음 10초 뒤에 다시 시도된다.
            log.warn("책 폴더를 읽지 못했어요: {}", e.getMessage());
        }
        return n;
    }

    // [흐름 F-③] 책 한 권 읽기
    void update(Path dir) throws IOException {
        // 경로의 마지막 이름만 꺼낸다.  예) dir=/root/my-publisher/books/20261109-dogwalk → folder="20261109-dogwalk"
        String folder = dir.getFileName().toString();
        // (1) books.findByFolder(folder)       SQL: select … from book b1_0 where b1_0.folder=?   결과: Optional<Book>
        // (2) .orElseGet(() -> new Book(folder)) DB 에 없으면(처음 본 폴더) 새 Book 객체를 만든다. 이때 id 는 null 이다.
        // 결과: 이미 있으면 DB 에서 읽은 객체(id=3), 없으면 새 객체.
        // 아래 books.save(book) 가 id 가 null 이면 insert, 있으면 update 를 실행한다.
        Book book = books.findByFolder(folder).orElseGet(() -> new Book(folder));

        // dir.resolve("plan/title.txt") = 폴더 경로 뒤에 붙인 경로.  예) .../20261109-dogwalk/plan/title.txt
        // title 예) ["꼬리 살랑, 첫 산책", "떨리는 마음도 괜찮아요, 천천히 함께 걷는 초보 보호자의 첫 산책 안내서"]
        List<String> title = readLines(dir.resolve("plan/title.txt"));
        // 첫 줄 = 제목.  title.txt 가 아직 없으면 제목을 바꾸지 않는다(새 Book 은 폴더 이름이 제목). 예) 20261109-dinosaur
        if (!title.isEmpty()) book.setTitle(strip(title.get(0)));
        // 둘째 줄 = 부제.
        if (title.size() > 1) book.setSubtitle(strip(title.get(1)));
        // 장르를 찾으면 그 값, 못 찾으면 원래 값을 그대로 둔다.  예) "실용서"
        book.setGenre(findGenre(dir).orElse(book.getGenre()));

        // chapters 예) [.../manuscript/01.md, 02.md, 03.md]  → 3개
        List<Path> chapters = list(dir.resolve("manuscript"), ".md");
        book.setChapterCount(chapters.size());
        // chars: 원고 글자 수 합계 (공백·줄바꿈은 세지 않는다).  예) 2934
        int chars = 0;
        // (1) Files.readString(c, UTF_8)  파일 전체를 글자열로 읽는다.
        // (2) .replaceAll("\\s", "")      공백·탭·줄바꿈을 모두 지운다. (\\s = 공백 문자 하나)
        // (3) .length()                   남은 글자 수
        // (4) chars +=                    합계에 더한다.
        for (Path c : chapters) chars += Files.readString(c, StandardCharsets.UTF_8).replaceAll("\\s", "").length();
        book.setCharCount(chars);

        // 완성 파일
        // BookFile.Kind.values() = [PDF, EPUB, HTML, COVER]. 종류마다 파일이 있는지 본다.
        //   PDF → dist/book.pdf   EPUB → dist/book.epub   HTML → dist/book.html   COVER → design/cover.svg
        for (BookFile.Kind kind : BookFile.Kind.values()) {
            Path f = dir.resolve(kind.getRelativePath());
            // 이미 DB 에 저장된 파일 기록 중 이 종류(kind)인 것을 찾는다. 없으면 Optional.empty().
            Optional<BookFile> existing = book.getFiles().stream().filter(x -> x.getKind() == kind).findFirst();
            if (Files.isRegularFile(f)) {
                // 파일 크기(바이트).  예) dist/book.pdf → 389934
                long size = Files.size(f);
                // 기록이 있으면 크기만 고친다 → update book_file …
                if (existing.isPresent()) existing.get().setSize(size);
                // 기록이 없으면 목록에 새로 넣는다 → 저장할 때 SQL: insert into book_file (book_id,kind,size,id) values (?,?,?,default)
                else book.getFiles().add(new BookFile(book, kind, size));
            } else {
                // 파일이 없어졌는데 기록이 남아 있으면 목록에서 뺀다 → 저장할 때 delete from book_file … (Book 의 orphanRemoval)
                existing.ifPresent(book.getFiles()::remove);
            }
        }

        // 단계를 정한다.  예) 20261109-dogwalk → Stage.DONE ("전자책 완성")
        book.setStage(stageOf(dir, chapters.size(), book));
        // range[0] = 폴더 안 가장 오래된 파일 시각, range[1] = 가장 최근 파일 시각.  예) range[0]=2026-11-09T20:21:43Z (plan/order.md)
        Instant[] range = timeRange(dir);
        book.setCreatedAt(range[0]);
        book.setUpdatedAt(range[1]);
        // JpaRepository.save()
        //   받는 것: Book 객체
        //   결과   : id 가 null 이면 insert into book …, 있으면 update book set … where id=?
        books.save(book);
    }

    // 위에서부터 차례로 검사해 처음 맞는 단계를 돌려준다. 뒤 단계부터 검사하는 이유: 완성된 책에도 기획서·원고가 남아 있기 때문.
    //   PDF 또는 EPUB 있음          → DONE      "전자책 완성"
    //   design/cover.svg 있음       → COVER     "표지 완료"
    //   review/*.md 가 하나라도 있음 → REVIEWING "교정 중"
    //   manuscript/*.md 가 있음     → WRITING   "집필 중"
    //   plan/proposal.md 있음       → PLANNED   "기획 완료"
    //   그 외                       → ORDERED   "주문 접수"
    static Stage stageOf(Path dir, int chapters, Book book) {
        if (book.hasFile(BookFile.Kind.PDF) || book.hasFile(BookFile.Kind.EPUB)) return Stage.DONE;
        if (book.hasFile(BookFile.Kind.COVER)) return Stage.COVER;
        if (!list(dir.resolve("review"), ".md").isEmpty()) return Stage.REVIEWING;
        if (chapters > 0) return Stage.WRITING;
        if (Files.exists(dir.resolve("plan/proposal.md"))) return Stage.PLANNED;
        return Stage.ORDERED;
    }

    private Optional<String> findGenre(Path dir) throws IOException {
        // order.md 를 먼저, 없거나 장르가 없으면 proposal.md 를 본다.
        for (String f : List.of("plan/order.md", "plan/proposal.md")) {
            Path p = dir.resolve(f);
            // continue: 이 파일은 건너뛰고 다음 파일로 간다. (isRegularFile = 폴더가 아닌 보통 파일인가)
            if (!Files.isRegularFile(p)) continue;
            // 파일 전체 글자에 GENRE 정규식을 맞춰 볼 준비를 한다.
            Matcher m = GENRE.matcher(Files.readString(p, StandardCharsets.UTF_8));
            // (1) m.find()            규칙에 맞는 부분을 찾으면 true
            // (2) m.group(1)          괄호로 묶은 부분.  예) "실용서 "
            // (3) .replace("*", "")   마크다운 굵은 글씨 표시 ** 를 지운다.  예) "**동화**" → "동화"
            // (4) .trim()             앞뒤 공백을 지운다. → "실용서"
            if (m.find()) return Optional.of(m.group(1).replace("*", "").trim());
        }
        return Optional.empty();
    }

    private static Instant[] timeRange(Path dir) throws IOException {
        Instant min = null, max = null;
        // Files.walk(dir): 폴더 안의 모든 항목을 하위 폴더까지 차례로 준다. (Files.list 는 한 단계만)
        try (Stream<Path> s = Files.walk(dir)) {
            for (Path p : s.filter(Files::isRegularFile).toList()) {
                // 파일의 마지막 수정 시각.  예) plan/order.md → 2026-11-09T20:21:43.871543205Z
                Instant t = Files.getLastModifiedTime(p).toInstant();
                if (min == null || t.isBefore(min)) min = t;
                if (max == null || t.isAfter(max)) max = t;
            }
        }
        // 폴더가 비어 있어 min·max 가 null 이면 폴더 자체의 시각을 쓴다.
        Instant dirTime = Files.getLastModifiedTime(dir).toInstant();
        return new Instant[]{min == null ? dirTime : min, max == null ? dirTime : max};
    }

    static List<Path> list(Path dir, String ext) {
        if (!Files.isDirectory(dir)) return List.of();
        try (Stream<Path> s = Files.list(dir)) {
            // (1) endsWith(ext)          확장자가 맞는 것만.  예) ext=".md"
            // (2) !startsWith("_")       이름이 _ 로 시작하는 파일(팀원이 쓰는 메모 파일)은 뺀다.
            // (3) .sorted().toList()     이름순 목록.  예) [01.md, 02.md, 03.md]
            return s.filter(p -> p.getFileName().toString().endsWith(ext) && !p.getFileName().toString().startsWith("_")).sorted().toList();
        } catch (IOException e) {
            return List.of();
        }
    }

    private static List<String> readLines(Path p) throws IOException {
        if (!Files.isRegularFile(p)) return List.of();
        // (1) readAllLines        줄 목록으로 읽는다.
        // (2) .map(String::trim)  줄마다 앞뒤 공백을 지운다.
        // (3) .filter(…)          빈 줄을 뺀다.
        return Files.readAllLines(p, StandardCharsets.UTF_8).stream().map(String::trim).filter(s -> !s.isEmpty()).toList();
    }

    private static String strip(String s) {
        // 줄 맨 앞의 "제목:", "부제:", "저자:" 를 지운다.  예) "제목: 꼬리 살랑, 첫 산책" → "꼬리 살랑, 첫 산책"
        // 앞머리가 없으면 그대로 돌려준다.  예) "꼬리 살랑, 첫 산책" → "꼬리 살랑, 첫 산책"
        return s.replaceFirst("^(제목|부제|저자)\\s*[:：]\\s*", "");
    }
}
