/*
 * [1] 역할
 *     tmux 칸 화면 글자를 사람이 알아볼 정보(이름·상태·하는 일)로 바꾸는 service/PaneReading.java 를 시험한다.
 *     fixture/panes/*.txt 는 실제 tmux capture-pane 으로 저장한 화면이다.
 *
 * [2] 받는 것 → 내보내는 것 (실제로 실행해서 얻은 값)
 *     jihun-working.txt → name "jihun", status WORKING, spinner "Razzmatazzing…"
 *     jihun-search.txt  → activity "Web Search(…" , spinner "Spelunking… (11s)"
 *     jihun-idle.txt    → status IDLE, activity 에 "더 할 일은 없습니다"
 *     lead-idle.txt     → name "team-lead", 팀 목록 {jihun=자료 조사, minjun=책 기획, seoyeon=집필 대기, taeyang=교정 대기}
 *     "Do you want to proceed?" 가 있는 화면 → status WAITING
 *
 * [3] 앞뒤 파일
 *     (이 파일)  →  service/PaneReading.java  ←  service/OfficeService.java (흐름 E-④)
 *
 * [4] 메서드 목록
 *     메서드                  확인하는 것
 *     working                 작업 중, 입력칸·상태줄은 모니터 글자에서 뺀다
 *     searching               마지막 ● 줄 = 하는 일
 *     idle                    대기, 마지막 한 말
 *     lead                    쭌 칸에서 팀원별 맡은 일 읽기
 *     waitingForPermission    허용 묻는 창 → WAITING (사무실에서 손 든 모양)
 *
 * [5] 먼저 알 용어 (자세한 설명: docs/용어-풀이.md)
 *     @Test, @DisplayName, Files.readAllLines, List.of, Map 비교(containsEntry)
 *
 * [6] 읽는 순서
 *     pane() → working() → waitingForPermission() → 나머지
 *
 * [7] 다 읽고 확인
 *     - 사무실 화면에서 손 든 모양이 나오기까지 이 시험의 결과는 어디를 거치는가? (PaneReading → OfficeService → JSON status "WAITING" → office.js → .s-WAITING)
 *     - Claude Code 화면 모양이 바뀌면 어느 시험이 먼저 실패할까?
 */
package com.greendesk.publisher;

import com.greendesk.publisher.service.PaneReading;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.util.List;
import java.util.Map;

import static org.assertj.core.api.Assertions.assertThat;

/** 실제 tmux 칸 화면(fixture/panes)을 사람이 알아볼 정보로 바꾸는지 */
class PaneReadingTest {

    static List<String> pane(String name) throws IOException {
        // 실제 tmux 화면을 저장한 글자 파일을 줄 목록으로 읽는다.
        return Files.readAllLines(FixturePaths.root().resolve("panes/" + name), StandardCharsets.UTF_8);
    }

    @Test
    @DisplayName("일하는 직원 칸: 칸 제목으로 이름을 알고, 작업 중으로 읽는다")
    void working() throws IOException {
        PaneReading r = PaneReading.read(pane("jihun-working.txt"), "jihun", false);
        assertThat(r.name()).isEqualTo("jihun");
        assertThat(r.status()).isEqualTo(PaneReading.Status.WORKING);
        assertThat(r.spinner()).isEqualTo("Razzmatazzing…");
        // 입력칸·상태줄은 모니터 글자에서 뺀다
        // 모니터에 보일 글자에서 Claude Code 의 입력칸(❯)과 아래 상태줄은 뺐어야 한다.
        assertThat(r.screen()).noneMatch(l -> l.contains("accept edits") || l.startsWith("❯"));
    }

    @Test
    @DisplayName("검색 중인 칸: 마지막 ● 줄이 하는 일, tmux 안내 문구는 빠진다")
    void searching() throws IOException {
        PaneReading r = PaneReading.read(pane("jihun-search.txt"), "jihun", false);
        assertThat(r.status()).isEqualTo(PaneReading.Status.WORKING);
        assertThat(r.activity()).startsWith("Web Search(");
        assertThat(r.spinner()).isEqualTo("Spelunking… (11s)");
        assertThat(r.screen()).noneMatch(l -> l.contains("focus-events"));
    }

    @Test
    @DisplayName("일을 마친 칸: 대기로 읽고, 마지막으로 한 말을 보여 준다")
    void idle() throws IOException {
        PaneReading r = PaneReading.read(pane("jihun-idle.txt"), "jihun", false);
        assertThat(r.status()).isEqualTo(PaneReading.Status.IDLE);
        assertThat(r.activity()).contains("더 할 일은 없습니다");
        assertThat(r.lastLines(14)).hasSizeLessThanOrEqualTo(14).isNotEmpty();
    }

    @Test
    @DisplayName("쭌 칸: 0번 칸이 쭌이고, 아래 팀 목록에서 직원별로 맡은 일을 읽는다")
    void lead() throws IOException {
        List<String> lines = pane("lead-idle.txt");
        PaneReading r = PaneReading.read(lines, "쭌 편집장 (사장님 말을 받는 칸)", true);
        assertThat(r.name()).isEqualTo("team-lead");
        Map<String, String> tasks = PaneReading.teamTasks(lines);
        assertThat(tasks).containsEntry("jihun", "자료 조사").containsEntry("minjun", "책 기획")
                .containsEntry("seoyeon", "집필 대기").containsEntry("taeyang", "교정 대기")
                .doesNotContainKey("main");
    }

    @Test
    @DisplayName("허용을 묻는 창이 떠 있으면 '허용 기다림'")
    void waitingForPermission() {
        List<String> lines = List.of(
                "● Bash(bash make-book.sh books/x)",
                "",
                " Bash command",
                "   rm -rf something",
                " Do you want to proceed?",
                " ❯ 1. Yes",
                "   2. No, and tell Claude what to do differently (esc)");
        // 허용을 묻는 창의 실제 모양을 List.of 로 적어 넣었다.
        assertThat(PaneReading.read(lines, null, true).status()).isEqualTo(PaneReading.Status.WAITING);
    }
}
