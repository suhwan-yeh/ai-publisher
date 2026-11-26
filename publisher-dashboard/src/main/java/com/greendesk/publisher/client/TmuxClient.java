/*
 * [1] 역할
 *     tmux 명령을 실행해, 출근 화면(tmux 세션 publisher 의 team 창)에 있는 칸들의 목록과 각 칸의 화면 글자를 읽어 오는 클래스다.
 *     읽기만 한다. 키를 누르거나 화면을 바꾸지 않는다. 명령에는 고정된 인자만 넣고, 사용자가 입력한 값은 절대 넣지 않는다.
 *
 * [2] 받는 것 → 내보내는 것 (실제로 실행해서 얻은 값)
 *     실행하는 명령 1   tmux -u list-panes -t publisher:team -F "#{pane_id}\t#{pane_index}\t#{pane_title}"
 *       출력 예          %0	0	쭌 편집장 (사장님 말을 받는 칸)
 *                        %2	1	jihun
 *     실행하는 명령 2   tmux -u capture-pane -p -J -t %2 -S -80     (칸마다: 그 칸의 화면 글자 80줄)
 *     돌려주는 값       [Pane(id="%0", index=0, title="쭌 편집장 (사장님 말을 받는 칸)", lines=[…]), Pane(id="%2", index=1, title="jihun", lines=[…])]
 *     tmux 가 없거나 세션이 없으면  []  (빈 목록)
 *
 * [3] 앞뒤 파일
 *     service/OfficeService.java 의 readScreens()  →  (이 파일)  →  tmux 프로그램
 *     읽은 글자의 해석: service/PaneReading.java
 *
 * [4] 메서드 목록
 *     메서드        하는 일
 *     capture()     칸 목록을 읽고, 칸마다 화면 글자를 읽어 Pane 목록으로 돌려준다
 *     run(명령…)    명령 하나를 실행해 출력 줄 목록을 돌려준다 (실패하면 빈 목록)
 *     parseInt(글)  글자를 숫자로 (실패하면 -1)
 *
 * [5] 먼저 알 용어 (자세한 설명: docs/용어-풀이.md)
 *     @Component, @Value, record, ProcessBuilder(외부 프로그램 실행), try-catch
 *
 * [6] 읽는 순서
 *     Pane → 생성자 → capture() → run()
 *
 * [7] 다 읽고 확인
 *     - 칸 id 가 "%2" 모양이 아니면 그 줄은 왜 건너뛰는가? (안전: 예상한 모양의 값만 명령에 넣는다)
 *     - Windows 의 IntelliJ 에서 실행해 tmux 가 없으면 capture() 는 무엇을 돌려주는가?
 */
package com.greendesk.publisher.client;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.TimeUnit;

/**
 * 외부 연결 클라이언트: tmux 화면 읽기 (읽기 전용).
 *
 * 출근하면 tmux 세션(publisher)의 창(team)에 쭌과 직원 칸이 생긴다.
 * 여기서는 정해진 명령 두 가지만 고정된 인자로 실행한다. 사용자가 입력한 값은 절대 명령에 넣지 않는다.
 *   tmux list-panes   -t publisher:team -F ...   칸 목록
 *   tmux capture-pane -p -J -t %칸번호 -S -80    칸 화면 글자
 * tmux 가 없거나(예: Windows IntelliJ) 세션이 없으면 빈 목록을 돌려준다.
 */
// 스프링이 이 클래스의 객체를 하나 만들어 OfficeService 에 넣어 준다.
@Component
public class TmuxClient {

    /** 칸 하나: tmux 칸 id(%3 같은 모양), 순서, 제목, 화면 글자 */
    // 칸 하나의 정보.  id = tmux 칸 번호("%2"), index = 창 안의 순서(0 = 쭌), title = 칸 제목("jihun"), lines = 화면 글자 줄 목록
    public record Pane(String id, int index, String title, List<String> lines) {
    }

    private static final Logger log = LoggerFactory.getLogger(TmuxClient.class);
    private final String target;
    private volatile boolean warned;

    // @Value 로 application.yml 의 tmux 세션·창 이름을 받는다. 없으면 publisher, team.
    public TmuxClient(@Value("${publisher.tmux-session:publisher}") String session,
                      @Value("${publisher.tmux-window:team}") String window) {
        // 설정값도 안전한 글자만 허용
        // 설정 값도 영문·숫자·_ . - 만 허용한다. 명령에 엉뚱한 글자가 들어가지 않게 하려고.
        if (!session.matches("[A-Za-z0-9_.-]+") || !window.matches("[A-Za-z0-9_.-]+")) {
            throw new IllegalArgumentException("tmux 세션·창 이름은 영문·숫자만 쓸 수 있어요");
        }
        // 예) target = "publisher:team"
        this.target = session + ":" + window;
    }

    /** 팀 창의 모든 칸과 화면 글자. tmux 를 못 쓰면 빈 목록 */
    public List<Pane> capture() {
        // 칸 목록을 읽는다. -u = 한글이 깨지지 않게 UTF-8 로, -F = 출력 모양(칸 번호, 순서, 제목을 탭으로 구분).
        List<String> rows = run("tmux", "-u", "list-panes", "-t", target, "-F", "#{pane_id}\t#{pane_index}\t#{pane_title}");
        List<Pane> panes = new ArrayList<>();
        for (String row : rows) {
            // 한 줄을 탭 글자로 최대 3조각으로 나눈다.   예) "%2\t1\tjihun" → ["%2", "1", "jihun"]
            String[] c = row.split("\t", 3);
            // 조각이 3개가 아니거나 칸 번호가 "%숫자" 모양이 아니면 건너뛴다.
            if (c.length < 3 || !c[0].matches("%\\d+")) continue;
            // 그 칸의 화면 글자를 읽는다. -p = 화면에 출력, -J = 화면 폭 때문에 나뉜 줄을 이어 붙임, -S -80 = 80줄 위부터.
            List<String> lines = run("tmux", "-u", "capture-pane", "-p", "-J", "-t", c[0], "-S", "-80");
            panes.add(new Pane(c[0], parseInt(c[1]), c[2], lines));
        }
        return panes;
    }

    private List<String> run(String... cmd) {
        try {
            // ProcessBuilder: 외부 프로그램을 실행한다. 명령과 인자를 배열로 넘기므로 셸(bash)을 거치지 않는다.
            //   예) ["tmux", "-u", "list-panes", …]  → tmux 프로그램이 실행된다
            Process p = new ProcessBuilder(cmd).redirectErrorStream(false).start();
            // 프로그램이 출력한 내용을 모두 읽는다.
            byte[] out = p.getInputStream().readAllBytes();
            // 2초 안에 끝나지 않으면 강제로 끝내고 빈 목록을 돌려준다.
            if (!p.waitFor(2, TimeUnit.SECONDS)) {
                p.destroyForcibly();
                return List.of();
            }
            // 종료 코드가 0 이 아니면(실패, 예: 세션 없음) 빈 목록.
            if (p.exitValue() != 0) return List.of();
            // 출력 바이트를 UTF-8 글자로 바꾸고 줄바꿈으로 나눈다.
            return List.of(new String(out, StandardCharsets.UTF_8).split("\n", -1));
        // tmux 프로그램이 없으면(IOException) 한 번만 로그를 남기고 빈 목록을 돌려준다.
        } catch (IOException e) {
            if (!warned) {
                warned = true;
                log.info("tmux 를 쓸 수 없어요(설치 안 됨 또는 Windows). 사무실 화면은 대화 기록으로만 보여 줘요: {}", e.getMessage());
            }
            return List.of();
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            return List.of();
        }
    }

    private static int parseInt(String s) {
        try {
            return Integer.parseInt(s.trim());
        } catch (NumberFormatException e) {
            return -1;
        }
    }
}
