/*
 * [1] 역할
 *     시험이 읽을 실제 기록(src/test/resources/fixture)의 경로를 알려 주는 도우미 클래스다.
 *
 * [2] 받는 것 → 내보내는 것 (실제로 실행해서 얻은 값)
 *     root()        → …/publisher-dashboard/build/resources/test/fixture
 *     publisher()   → …/fixture/my-publisher       (books/20261109-sea-kitten 이 들어 있다)
 *     transcripts() → …/fixture/transcripts        (*.jsonl 7개)
 *
 * [3] 앞뒤 파일
 *     DashboardIntegrationTest, PaneReadingTest, MySqlMigrationTest  →  (이 파일)
 *
 * [4] 메서드 목록
 *     메서드          돌려주는 것
 *     root()          fixture 폴더
 *     publisher()     출판사 폴더 (publisher.root 로 쓴다)
 *     transcripts()   대화 기록 폴더 (publisher.transcripts-dir 로 쓴다)
 *
 * [5] 먼저 알 용어 (자세한 설명: docs/용어-풀이.md)
 *     getResource, URI → Path, private 생성자
 *
 * [6] 읽는 순서
 *     root() → publisher() → transcripts()
 *
 * [7] 다 읽고 확인
 *     - src/test/resources 의 파일은 시험할 때 어디로 복사되는가? (build/resources/test)
 *     - getResource("/fixture") 가 null 이면 어떤 예외가 나는가?
 */
package com.greendesk.publisher;

import java.net.URISyntaxException;
import java.nio.file.Path;
import java.nio.file.Paths;

/** 테스트용 실제 기록(줄인 것): src/test/resources/fixture */
public final class FixturePaths {
    private FixturePaths() {
    }

    public static Path root() {
        try {
            // (1) getResource("/fixture")  시험 classpath 의 fixture 폴더 주소(URL).  src/test/resources/fixture 가 build/resources/test/fixture 로 복사돼 있다.
            // (2) .toURI() → Paths.get(…)   파일 경로 Path 로 바꾼다.
            return Paths.get(FixturePaths.class.getResource("/fixture").toURI());
        } catch (URISyntaxException e) {
            throw new IllegalStateException(e);
        }
    }

    public static Path publisher() {
        return root().resolve("my-publisher");
    }

    public static Path transcripts() {
        return root().resolve("transcripts");
    }
}
