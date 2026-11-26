/*
 * [1] 역할
 *     설정 값(config/PublisherProperties.java)에서 폴더 경로를 바르게 만드는지 시험한다.
 *
 * [2] 받는 것 → 내보내는 것 (실제로 실행해서 얻은 값)
 *     root "/home/student/my-publisher", claude-projects "/home/student/.claude/projects"
 *       → transcriptsPath() = /home/student/.claude/projects/-home-student-my-publisher   (Claude Code 가 폴더 이름의 / 를 - 로 바꾼 규칙)
 *       → booksPath()       = /home/student/my-publisher/books
 *     root "~/my-publisher" → rootPath() = (홈 폴더)/my-publisher,  scanInterval() = 10000
 *
 * [3] 앞뒤 파일
 *     (이 파일)  →  config/PublisherProperties.java
 *
 * [4] 메서드 목록
 *     메서드                              확인하는 것
 *     transcriptsFolderFollowsClaudeNaming 기록 폴더 이름 규칙
 *     tildeIsHome                         ~ 를 홈 폴더로, 간격 기본값 10초
 *
 * [5] 먼저 알 용어 (자세한 설명: docs/용어-풀이.md)
 *     @Test, 레코드 생성자 직접 부르기, System.getProperty("user.home")
 *
 * [6] 읽는 순서
 *     transcriptsFolderFollowsClaudeNaming() → tildeIsHome()
 *
 * [7] 다 읽고 확인
 *     - Windows 에서 IntelliJ 로 켜면 이 규칙이 왜 맞지 않을 수 있는가? (리눅스 쪽 경로와 Windows 경로가 다르다. README 의 경로 설정)
 *     - 10_000L 의 _ 는 무슨 뜻인가? (숫자를 읽기 쉽게 끊은 것. 10000 과 같다)
 */
package com.greendesk.publisher;

import com.greendesk.publisher.config.PublisherProperties;
import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;

class PublisherPropertiesTest {

    @Test
    void transcriptsFolderFollowsClaudeNaming() {
        // 스프링 없이 설정 객체를 직접 만든다. 인자 순서: root, claude-projects, transcripts-dir, scan-interval-ms
        var p = new PublisherProperties("/home/student/my-publisher", "/home/student/.claude/projects", "", null);
        assertThat(p.transcriptsPath().toString()).isEqualTo("/home/student/.claude/projects/-home-student-my-publisher");
        assertThat(p.booksPath().toString()).isEqualTo("/home/student/my-publisher/books");
    }

    @Test
    void tildeIsHome() {
        var p = new PublisherProperties("~/my-publisher", null, null, null);
        assertThat(p.rootPath().toString()).isEqualTo(System.getProperty("user.home") + "/my-publisher");
        assertThat(p.scanInterval()).isEqualTo(10_000L);
    }
}
