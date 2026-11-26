/*
 * [1] 역할
 *     tmux 칸의 화면 글자(여러 줄)를 읽어 다음 값을 알아내는 클래스다.
 *       누구의 칸인가 / 지금 상태(작업 중·허용 기다림·대기) / 마지막으로 한 작업 / 진행 문구 / 모니터에 보여 줄 줄들
 *     입력과 출력만 있고 DB·네트워크를 쓰지 않는 함수라서, 실제 화면 글자를 저장해 둔 파일로 단위 테스트를 한다(PaneReadingTest).
 *
 * [2] 받는 것 → 내보내는 것 (실제로 실행해서 얻은 값)
 *     받는 것 (실제 지훈 칸의 마지막 몇 줄)
 *       ● Web Search("영유아 실내 놀이 안전 …")
 *         ⎿  Found 9 results for "…"
 *       ✻ Spelunking… (11s · ↓ 312 tokens)
 *       ────────────────────────
 *       ❯
 *       ────────────────────────
 *         ⏵⏵ accept edits on (shift+tab to cycle) · esc to interrupt
 *     내보내는 것
 *       PaneReading(name="jihun", status=WORKING, activity="Web Search(\"영유아 실내 놀이 안전 …\")", spinner="Spelunking… (11s)", screen=[입력칸 위의 줄들])
 *
 * [3] 앞뒤 파일
 *     client/TmuxClient.java (화면 글자를 읽어 옴)  →  service/OfficeService.java 의 readScreens()  →  (이 파일)
 *     시험: src/test/java/…/PaneReadingTest.java, src/test/resources/fixture/panes/*.txt
 *
 * [4] 메서드 목록
 *     메서드·값            하는 일
 *     Status (enum)        WORKING(작업 중) · WAITING(허용 기다림) · IDLE(대기) · OFFLINE(자리 비움)
 *     read(줄들, 제목, 0번칸)  화면 글자를 해석해 PaneReading 을 만든다
 *     teamTasks(쭌 칸 줄들)   쭌 칸의 팀 목록에서 "직원 → 맡은 일" 을 읽는다
 *     lastLines(n)          모니터용 마지막 n 줄
 *     isBorder(줄)          ──── 로 된 입력칸 테두리 줄인가
 *     stripRight(글자)       오른쪽 끝의 공백을 지운다
 *
 * [5] 먼저 알 용어 (자세한 설명: docs/용어-풀이.md)
 *     record, enum, 정규식(Pattern·Matcher), List.subList, static 메서드
 *
 * [6] 읽는 순서
 *     Status → 정규식 네 개 → read() → teamTasks() → 나머지
 *
 * [7] 다 읽고 확인
 *     - 화면 아래쪽에 "Do you want to proceed?" 가 있으면 상태는 무엇이 되는가?
 *     - 진행 문구도 없고 "esc to interrupt" 도 없으면 상태는 무엇이 되는가?
 */
package com.greendesk.publisher.service;

import java.util.ArrayList;
import java.util.List;
import java.util.Locale;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

/**
 * tmux 칸 화면 글자를 사람이 알아볼 정보로 바꾼다 (순수 함수, 단위 테스트 대상).
 *  - 누구의 칸인가 : 입력칸 테두리의 "@jihun" 표시, 또는 0번 칸 = 쭌
 *  - 지금 상태      : 작업 중 / 허용 기다림 / 대기
 *  - 하는 일        : 마지막 "●" 줄 (도구 사용·말한 내용)
 *  - 모니터 글자    : 입력칸·상태줄을 뺀 마지막 내용 줄들
 */
// record: 해석 결과 다섯 가지를 담는다.
public record PaneReading(String name, Status status, String activity, String spinner, List<String> screen) {

    // enum = 정해진 값 몇 개 중 하나만 가질 수 있는 자료형. 괄호 안 글자는 각 값의 한글 표시(label)다.
    public enum Status {
        WORKING("작업 중"), WAITING("허용 기다림"), IDLE("대기"), OFFLINE("자리 비움");
        private final String label;
        Status(String label) { this.label = label; }
        public String label() { return label; }
    }

    /** 입력칸 테두리 오른쪽의 이름 표시: "──── @jihun ─" */
    // 정규식(Pattern) = 글자의 모양을 나타내는 식. 화면 줄에서 원하는 부분을 찾을 때 쓴다.
    // AT_NAME : 입력칸 테두리의 "──── @jihun ─" 에서 jihun 을 찾는다. ( ) 로 감싼 부분이 group(1) 로 꺼내진다.
    private static final Pattern AT_NAME = Pattern.compile("─+\\s@([A-Za-z][A-Za-z0-9_-]*)\\s─");
    /** 작업 중 표시: "✻ Baking… (25s · ↓ 2.4k tokens)" 또는 상태줄의 "esc to interrupt" */
    // SPINNER : "✻ Spelunking… (11s · ↓ 312 tokens)" 같은 작업 중 표시를 찾는다.
    //   group(1) = "Spelunking…"   group(2) = "11s" (괄호 부분이 없으면 null)
    private static final Pattern SPINNER = Pattern.compile("^\\s*\\S\\s+([A-Z][A-Za-z-]+…)(?:\\s*\\((\\d+m \\d+s|\\d+[smh]))?");
    // PERMISSION : Claude Code 가 허용을 묻는 화면("Do you want to proceed?", "❯ 1. Yes")을 찾는다. CASE_INSENSITIVE = 대소문자 구분 안 함.
    private static final Pattern PERMISSION = Pattern.compile(
            "Do you want to (proceed|make this edit|create|run|allow)|❯\\s*1\\.\\s*Yes|Allow .* to |requires approval", Pattern.CASE_INSENSITIVE);

    /** 쭌 칸 아래쪽 팀 목록: "◯ jihun    자료 조사      11s" */
    // TEAM_ROW : 쭌 칸 아래쪽 팀 목록 한 줄 "◯ jihun    자료 조사      11s" 에서
    //   group(1) = "jihun", group(2) = "자료 조사" 를 꺼낸다. 맨 뒤의 시간("11s", "1m 57s")은 빼고 읽는다.
    private static final Pattern TEAM_ROW = Pattern.compile("^\\s*[◯●○◉]\\s+([a-z][a-z0-9_-]*)\\s+(.+?)(?:\\s{2,}\\d[\\dhms ]*)?\\s*$");

    /**
     * @param raw       capture-pane 결과 줄
     * @param paneTitle tmux 칸 제목 (직원 칸은 영문 이름이 들어 있음)
     * @param firstPane 0번 칸(쭌)인가
     */
    // ▶ 받는 값: raw = 화면 줄 목록, paneTitle = 칸 제목(예: "jihun"), firstPane = 0번 칸인가
    // ▶ 돌려주는 값: PaneReading
    public static PaneReading read(List<String> raw, String paneTitle, boolean firstPane) {
        List<String> lines = new ArrayList<>();
        for (String l : raw) {
            // continue = 이번 줄은 건너뛰고 다음 줄로 간다.
            if (l.contains("focus-events")) continue; // tmux 안내 문구는 화면 내용이 아님
            lines.add(stripRight(l));
        }
        int end = lines.size();
        // 맨 아래의 빈 줄들을 세지 않도록 끝 위치를 위로 올린다.
        while (end > 0 && lines.get(end - 1).isBlank()) end--;
        List<String> all = lines.subList(0, end);

        // 누구의 칸인가 정하기
        //   1) 0번 칸이면 쭌("team-lead")
        String name = firstPane ? "team-lead" : null;
        //   2) 칸 제목이 영문 이름 모양이면 그 이름 (Claude Code 가 직원 칸 제목을 직원 이름으로 정한다)
        if (name == null && paneTitle != null && paneTitle.trim().matches("[A-Za-z][A-Za-z0-9_-]*")) {
            name = paneTitle.trim().toLowerCase(Locale.ROOT);
        }
        //   3) 그래도 모르면 아래 줄부터 위로 올라가며 "@이름" 표시를 찾는다
        for (int i = all.size() - 1; i >= 0 && name == null; i--) {
            Matcher m = AT_NAME.matcher(all.get(i));
            if (m.find()) name = m.group(1).toLowerCase(Locale.ROOT);
        }

        // 아래쪽 입력칸·상태줄 시작 위치: 마지막 "────" 테두리 두 줄 중 위쪽
        // 입력칸 찾기: 아래에서 위로 14줄 안에서 테두리(────) 줄 두 개를 찾는다. 위쪽 테두리부터 아래는 입력칸·상태줄이라 모니터에 보여 주지 않는다.
        int boxTop = all.size();
        int borders = 0;
        for (int i = all.size() - 1; i >= Math.max(0, all.size() - 14); i--) {
            if (isBorder(all.get(i))) {
                borders++;
                boxTop = i;
                if (borders == 2) break;
            }
        }
        // 입력칸 위의 내용 줄들.
        List<String> content = all.subList(0, boxTop);
        // 아래쪽 16줄을 한 글자로 이어 붙인다. 상태(허용 질문, esc to interrupt)를 찾을 때 쓴다.
        String tail = String.join("\n", all.subList(Math.max(0, all.size() - 16), all.size()));

        String spinner = null;
        for (int i = content.size() - 1; i >= Math.max(0, content.size() - 8); i--) {
            Matcher m = SPINNER.matcher(content.get(i));
            if (m.find()) {
                spinner = m.group(2) == null ? m.group(1) : m.group(1) + " (" + m.group(2) + ")";
                break;
            }
        }
        Status status;
        // 상태 정하기
        //   1) 허용 질문이 보이면 WAITING
        if (PERMISSION.matcher(tail).find()) status = Status.WAITING;
        //   2) 진행 문구가 있거나 "esc to interrupt"(작업 중에만 보이는 안내)가 있으면 WORKING
        else if (spinner != null || tail.contains("esc to interrupt")) status = Status.WORKING;
        //   3) 아니면 IDLE
        else status = Status.IDLE;

        String activity = null;
        for (int i = content.size() - 1; i >= 0; i--) {
            String l = content.get(i).trim();
            // ● 로 시작하는 줄 = Claude Code 가 도구를 쓰거나 말한 줄. 아래에서 가장 가까운 것을 "마지막 작업"으로 쓴다.
            if (l.startsWith("●")) {
                activity = l.substring(1).trim();
                break;
            }
        }

        List<String> screen = new ArrayList<>();
        for (String l : content) {
            if (screen.isEmpty() && l.isBlank()) continue;
            screen.add(l);
        }
        // 빈 줄이 여러 개 이어지면 하나로
        List<String> compact = new ArrayList<>();
        for (String l : screen) {
            if (l.isBlank() && !compact.isEmpty() && compact.get(compact.size() - 1).isBlank()) continue;
            compact.add(l);
        }
        while (!compact.isEmpty() && compact.get(compact.size() - 1).isBlank()) compact.remove(compact.size() - 1);
        return new PaneReading(name, status, activity, spinner, compact);
    }

    /** 쭌 칸의 팀 목록에서 직원별 지금 맡은 일 (이름 → 일) */
    // ▶ 받는 값: 쭌 칸의 줄들   ▶ 돌려주는 값: Map   예) {"jihun":"자료 조사","minjun":"책 기획","seoyeon":"집필 대기","taeyang":"교정 대기"}
    public static java.util.Map<String, String> teamTasks(List<String> leadRaw) {
        java.util.Map<String, String> out = new java.util.LinkedHashMap<>();
        for (String l : leadRaw) {
            Matcher m = TEAM_ROW.matcher(stripRight(l));
            // "● main" 줄(쭌 자신)은 빼고 넣는다.
            if (m.matches() && !m.group(1).equals("main")) out.put(m.group(1), m.group(2).trim());
        }
        return out;
    }

    /** 마지막 n 줄 */
    public List<String> lastLines(int n) {
        return screen.subList(Math.max(0, screen.size() - n), screen.size());
    }

    private static boolean isBorder(String l) {
        String t = l.trim();
        // 20자 이상이고, 60% 이상이 ─ 글자이면 테두리 줄로 본다.
        return t.length() >= 20 && t.chars().filter(c -> c == '─').count() >= t.length() * 0.6;
    }

    private static String stripRight(String s) {
        int e = s.length();
        while (e > 0 && Character.isWhitespace(s.charAt(e - 1))) e--;
        return s.substring(0, e);
    }
}
