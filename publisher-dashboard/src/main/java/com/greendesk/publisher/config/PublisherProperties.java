/*
 * [1] 역할
 *     application.yml 의 publisher.* 설정 값을 담는 클래스다. 폴더 경로를 계산하는 메서드도 가진다.
 *
 * [2] 받는 것 → 내보내는 것 (실제로 실행해서 얻은 값)
 *     application.yml
 *       publisher:
 *         root: ${PUBLISHER_ROOT:~/my-publisher}
 *         claude-projects: ${PUBLISHER_CLAUDE_PROJECTS:~/.claude/projects}
 *     자바 객체   PublisherProperties(root="~/my-publisher", claudeProjects="~/.claude/projects", transcriptsDir="", scanIntervalMs=10000)
 *     rootPath()        → /root/my-publisher
 *     booksPath()       → /root/my-publisher/books
 *     transcriptsPath() → /root/.claude/projects/-root-my-publisher
 *
 * [3] 앞뒤 파일
 *     application.yml  →  (이 파일)  →  service/*, scan/*, config/StaffDirectory.java
 *
 * [4] 필드와 메서드 목록
 *     필드·메서드          뜻
 *     root                출판사 폴더 (설정 글자)
 *     claudeProjects      Claude 대화 기록 폴더의 상위 폴더
 *     transcriptsDir      대화 기록 폴더를 직접 지정 (비우면 자동 계산)
 *     scanIntervalMs      다시 읽는 간격(밀리초)
 *     rootPath()          ~ 를 홈 폴더로 바꾼 출판사 폴더 경로
 *     booksPath()         출판사 폴더/books
 *     transcriptsPath()   대화 기록 폴더 (Claude Code 의 이름 규칙으로 계산)
 *     expand(글자)        "~/" 로 시작하면 홈 폴더 경로로 바꾼다
 *
 * [5] 먼저 알 용어 (자세한 설명: docs/용어-풀이.md)
 *     @ConfigurationProperties, record, Path, System.getProperty("user.home")
 *
 * [6] 읽는 순서
 *     필드 → rootPath() → transcriptsPath() → expand()
 *
 * [7] 다 읽고 확인
 *     - 환경 변수 PUBLISHER_ROOT=/data/pub 를 주고 실행하면 booksPath() 는 무엇인가?
 *     - 출판사 폴더가 /home/kim/my-publisher 이면 대화 기록 폴더 이름은 무엇인가? (-home-kim-my-publisher)
 */
package com.greendesk.publisher.config;

import org.springframework.boot.context.properties.ConfigurationProperties;

import java.nio.file.Path;
import java.nio.file.Paths;

/**
 * application.yml 의 publisher.* 설정.
 * root            : 출판사 폴더 (기본 ~/my-publisher)
 * claudeProjects  : Claude 대화 기록 폴더 (기본 ~/.claude/projects)
 * transcriptsDir  : 비워 두면 claudeProjects 아래에서 root 경로 이름으로 자동으로 찾음
 */
// @ConfigurationProperties(prefix = "publisher")
//   뜻     : 설정 파일에서 publisher. 으로 시작하는 값들을 이 record 의 같은 이름 필드에 넣는다.
//            설정 이름 claude-projects 는 필드 claudeProjects 에 들어간다 (줄표 이름 → 낙타 표기 이름).
@ConfigurationProperties(prefix = "publisher")
public record PublisherProperties(String root, String claudeProjects, String transcriptsDir, Long scanIntervalMs) {

    public Path rootPath() {
        return expand(root == null || root.isBlank() ? "~/my-publisher" : root);
    }

    public Path booksPath() {
        return rootPath().resolve("books");
    }

    public Path transcriptsPath() {
        if (transcriptsDir != null && !transcriptsDir.isBlank()) {
            return expand(transcriptsDir);
        }
        Path projects = expand(claudeProjects == null || claudeProjects.isBlank() ? "~/.claude/projects" : claudeProjects);
        // Claude Code는 프로젝트 경로의 영문·숫자가 아닌 글자를 '-'로 바꾼 이름의 폴더에 기록을 남긴다 (/root/my-publisher → -root-my-publisher)
        // 영문·숫자가 아닌 글자를 모두 - 로 바꾼다.   예) "/root/my-publisher" → "-root-my-publisher"
        String encoded = rootPath().toAbsolutePath().normalize().toString().replaceAll("[^A-Za-z0-9]", "-");
        return projects.resolve(encoded);
    }

    public long scanInterval() {
        return scanIntervalMs == null ? 10_000L : scanIntervalMs;
    }

    static Path expand(String p) {
        String s = p.trim();
        if (s.equals("~") || s.startsWith("~/")) {
            // System.getProperty("user.home") = 현재 사용자의 홈 폴더.   예) "~/my-publisher" → "/root/my-publisher"
            s = System.getProperty("user.home") + s.substring(1);
        }
        return Paths.get(s);
    }
}
