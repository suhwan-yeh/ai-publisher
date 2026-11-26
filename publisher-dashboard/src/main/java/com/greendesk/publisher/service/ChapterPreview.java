/*
 * [1] 역할
 *     책 폴더의 원고 파일(manuscript/01.md …)을 읽어 장마다 제목, 앞부분 미리보기, 글자 수, 교정 판정 한 줄을 만든다.
 *
 * [2] 받는 것 → 내보내는 것 (실제로 실행해서 얻은 값)
 *     받는 것        책 폴더 경로    예) /root/my-publisher/books/20261109-dogwalk
 *     내보내는 것    [ChapterPreview(file="01.md", title="1장. 나가기 전에 알아 둘 것", preview="…", chars=1530, review="판정: 통과"), …]
 *
 * [3] 앞뒤 파일
 *     service/DashboardService.java 의 chapters()  →  (이 파일)  →  templates/book.html (장별 원고), service/OfficeService.java (회의실 화이트보드)
 *
 * [4] 필드와 메서드 목록
 *     필드·메서드     뜻
 *     file           원고 파일 이름                          예) "01.md"
 *     title          파일의 첫 # 줄 (# 기호는 뺀다)          예) "1장. 나가기 전에 알아 둘 것"
 *     preview        제목이 아닌 줄 4개를 이어 붙인 앞부분 (220자까지)
 *     chars          공백을 뺀 글자 수
 *     review         review/01.md 에서 "판정·통과·반려"가 들어간 첫 줄 (80자까지, 없으면 null)
 *     read(폴더)      위 값을 장마다 만들어 목록으로 돌려준다
 *
 * [5] 먼저 알 용어 (자세한 설명: docs/용어-풀이.md)
 *     record, static 메서드, Files.list·readString, try-with-resources, stream·filter·findFirst·limit·reduce, 정규식
 *
 * [6] 읽는 순서
 *     read() 한 메서드가 전부다. for 문 안을 위에서 아래로 읽는다.
 *
 * [7] 다 읽고 확인
 *     - manuscript 폴더가 없으면 read() 는 무엇을 돌려주는가?
 *     - 제목 줄의 "## 2장" 처럼 # 이 두 개여도 제목에서 # 이 지워지는 이유는 어느 정규식 때문인가?
 */
package com.greendesk.publisher.service;

import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.ArrayList;
import java.util.List;
import java.util.stream.Stream;

/** 장별 원고 미리보기와 교정 판정 한 줄 */
// record: 값만 담는 클래스. book.html 에서 ${c.title()} 처럼 꺼낸다.
public record ChapterPreview(String file, String title, String preview, int chars, String review) {

    // static 이고 public 이 없다: 같은 패키지(service)의 DashboardService 에서만 ChapterPreview.read(…) 로 호출한다.
    static List<ChapterPreview> read(Path bookDir) {
        List<ChapterPreview> out = new ArrayList<>();
        // 원고 폴더 경로.   예) /root/my-publisher/books/20261109-dogwalk/manuscript
        Path ms = bookDir.resolve("manuscript");
        // 원고 폴더가 아직 없으면(기획 단계) 빈 목록을 돌려준다.
        if (!Files.isDirectory(ms)) return out;
        // try-with-resources: 괄호 안에서 연 자원(폴더 목록)을 블록이 끝나면 자동으로 닫는다.
        // Files.list(ms) = 폴더 안의 파일 경로들.
        try (Stream<Path> s = Files.list(ms)) {
            // .md 로 끝나는 파일만, 이름 순서(01.md, 02.md, 03.md)로 하나씩 p 에 넣어 반복한다.
            for (Path p : s.filter(x -> x.toString().endsWith(".md")).sorted().toList()) {
                // 파일 전체를 UTF-8 글자로 읽는다. (한글이 깨지지 않게 문자 인코딩을 지정한다)
                String text = Files.readString(p, StandardCharsets.UTF_8);
                // (1) text.lines()                         한 줄씩 나눈다.
                // (2) .filter(l -> l.startsWith("#"))      # 로 시작하는 줄만 남긴다.
                // (3) .findFirst()                         첫 줄을 고른다.
                // (4) .orElse(파일 이름)                   없으면 파일 이름을 쓴다.
                // (5) .replaceFirst("^#+\\s*", "")         줄 맨 앞의 # 들과 뒤따르는 공백을 지운다.   예) "# 1장. 나가기 전에" → "1장. 나가기 전에"
                String title = text.lines().filter(l -> l.startsWith("#")).findFirst().orElse(p.getFileName().toString()).replaceFirst("^#+\\s*", "");
                // (1) 제목도 아니고 빈 줄도 아닌 줄만 남긴다.
                // (2) .limit(4)                            앞의 4줄만.
                // (3) .reduce("", (a, b) -> a + b.trim() + " ")   "" 에서 시작해 줄을 하나씩 공백으로 이어 붙인다.
                String body = text.lines().filter(l -> !l.startsWith("#") && !l.isBlank()).limit(4).reduce("", (a, b) -> a + b.trim() + " ");
                // 220자가 넘으면 앞 220자만 남기고 … 을 붙인다.
                if (body.length() > 220) body = body.substring(0, 220) + "…";
                // 같은 이름의 교정 파일.   예) …/review/01.md
                Path rv = bookDir.resolve("review").resolve(p.getFileName());
                String review = null;
                if (Files.isRegularFile(rv)) {
                    review = Files.readString(rv, StandardCharsets.UTF_8).lines()
                            .filter(l -> l.contains("판정") || l.contains("통과") || l.contains("반려"))
                            .findFirst().orElse("교정 의견 있음").replaceAll("[#*>]", "").trim();
                    if (review.length() > 80) review = review.substring(0, 80) + "…";
                }
                // text.replaceAll("\\s", "").length() = 공백·줄바꿈을 모두 지운 뒤의 글자 수.
                out.add(new ChapterPreview(p.getFileName().toString(), title, body.trim(), text.replaceAll("\\s", "").length(), review));
            }
        // 파일을 읽다가 오류가 나면 무시하고, 그때까지 만든 목록을 돌려준다. (미리보기는 없어도 화면이 열리도록)
        } catch (IOException ignored) {
        }
        return out;
    }
}
