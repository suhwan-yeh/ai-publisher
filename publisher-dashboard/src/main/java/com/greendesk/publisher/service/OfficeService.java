/*
 * [1] 역할
 *     사무실 화면과 회의실 화면에 필요한 값을 만드는 서비스 클래스다.
 *     두 곳에서 정보를 모은다: (1) tmux 칸의 화면 글자 (TmuxClient → PaneReading), (2) DB 에 저장된 직원·메시지 기록.
 *     tmux 를 읽을 수 없으면(예: Windows 의 IntelliJ 에서 실행) DB 기록만으로 상태를 정한다.
 *
 * [2] 받는 것 → 내보내는 것 (실제로 실행해서 얻은 값)
 *     office(0) → 돌려주는 값 OfficeResponse   (tmux 없이 실행했을 때의 실제 값)
 *       source="기록", teamName="session-2d8e941e", agents 6명,
 *       agents[0] = {name:"team-lead", status:"IDLE", statusLabel:"대기", screen:[], lastActive:"2026-11-09T21:02:42.256Z", sent:0}
 *       messages[0] = {id:153, from:"tepo", fromKorean:"테포", to:"team-lead", category:"보고", text:"[보고] 준비 부족: …"}
 *     status() → OfficeStatusResponse(tmuxAvailable=false, leadWaitingPermission=false, working=[])
 *
 * [3] 앞뒤 파일
 *     api/OfficeApiController.java  →  (이 파일)
 *     (이 파일)  →  client/TmuxClient.java, service/PaneReading.java, service/DashboardService.java, service/ScanService.java,
 *                  repository/TeamMessageRepository, TeamMemberRepository, ChatMessageRepository
 *
 * [4] 메서드 목록
 *     메서드                  하는 일                                                    흐름 번호
 *     office(after)           사무실 전체: 직원별 상태·화면 글자 + 새 직원 메시지 + 최근 책     흐름 E-③~⑥
 *     staff()                 직원 명부 목록
 *     screen(name)            한 사람의 tmux 화면 전체 (없으면 404)
 *     status()                쭌이 허용 질문에서 멈춰 있는지, 누가 작업 중인지
 *     meeting(bookId, after)  회의실: 직원 메시지 + 화이트보드에 쓸 책 정보
 *     currentTeam()           가장 최근에 활동한 팀(쭌의 Claude 세션) 이름
 *     leadLastActive(team)    쭌의 마지막 활동 시각
 *     recentTeamMessages(…)   팀의 직원 메시지 중 after 번보다 새 것
 *     readScreens()           tmux 칸을 모두 읽어 사람 이름별로 정리
 *
 * [5] 먼저 알 용어 (자세한 설명: docs/용어-풀이.md)
 *     @Service, Map·HashMap·LinkedHashMap·LinkedHashSet, Optional, Duration, enum, 클래스 안의 클래스(Screens)
 *
 * [6] 읽는 순서
 *     office() → readScreens() → currentTeam() → recentTeamMessages() → meeting() → 나머지
 *
 * [7] 다 읽고 확인
 *     - tmux 가 실행 중인데 어떤 직원의 칸이 없으면 그 직원의 상태는 무엇이 되는가?
 *     - tmux 가 없을 때, 마지막 활동이 30초 전인 직원의 상태는 무엇이 되는가? (ACTIVE = 60초)
 */
package com.greendesk.publisher.service;

import com.greendesk.publisher.client.TmuxClient;
import com.greendesk.publisher.domain.ChatMessage;
import com.greendesk.publisher.domain.Names;
import com.greendesk.publisher.domain.TeamMember;
import com.greendesk.publisher.domain.TeamMessage;
import com.greendesk.publisher.dto.*;
import com.greendesk.publisher.repository.ChatMessageRepository;
import com.greendesk.publisher.repository.TeamMemberRepository;
import com.greendesk.publisher.repository.TeamMessageRepository;
import org.springframework.stereotype.Service;

import java.time.Duration;
import java.time.Instant;
import java.util.*;

/**
 * 사무실·회의실 화면에 필요한 "지금 모습"을 만든다.
 *  - tmux 칸 화면(TmuxClient → PaneReading)으로 누가 무엇을 하는지
 *  - 대화 기록 DB(TeamMessage·TeamMember)로 누가 누구에게 말했는지
 * tmux 를 못 읽으면(예: Windows IntelliJ) 대화 기록만으로 상태를 짐작한다.
 */
// 스프링이 객체를 하나 만들어 OfficeApiController 에 넣어 주는 서비스 클래스.
@Service
public class OfficeService {

    /** 이 시간 안에 활동했으면 '작업 중'으로 본다 (tmux 없을 때) */
    // tmux 를 읽지 못할 때, 마지막 활동이 60초 안이면 "작업 중"으로 본다.
    static final Duration ACTIVE = Duration.ofSeconds(60);
    /** 이 시간 안에 대화가 있었으면 '회의 중' */
    // 회의실에서 마지막 직원 메시지가 2분 안이면 "회의 중", 아니면 "회의 쉬는 중".
    static final Duration LIVE = Duration.ofMinutes(2);
    // 사무실 책상 모니터에 보여 줄 줄 수.
    private static final int SCREEN_LINES = 14;

    // 아래 여섯 필드는 생성자에서 스프링이 넣어 준다.
    //   tmux          tmux 명령을 실행해 칸의 화면 글자를 읽는다
    //   teamMessages  team_message 표 (직원끼리 주고받은 메시지)
    //   members       team_member 표 (직원과 마지막 활동 시각)
    //   chats         chat_message 표 (사장님과 쭌의 대화)
    //   dashboard     책 목록·장 목록을 가져올 때 쓴다
    //   scans         대화 기록 파일을 다시 읽게 한다
    private final TmuxClient tmux;
    private final TeamMessageRepository teamMessages;
    private final TeamMemberRepository members;
    private final ChatMessageRepository chats;
    private final DashboardService dashboard;
    private final ScanService scans;

    public OfficeService(TmuxClient tmux, TeamMessageRepository teamMessages, TeamMemberRepository members,
                         ChatMessageRepository chats, DashboardService dashboard, ScanService scans) {
        this.tmux = tmux;
        this.teamMessages = teamMessages;
        this.members = members;
        this.chats = chats;
        this.dashboard = dashboard;
        this.scans = scans;
    }

    /** 사무실 전체. afterMessageId 보다 새 직원 메시지만 담는다 (0이면 최근 30개) */
    // ────────────────────────────────────────────────────────────────────────────
    // [흐름 E-③] 사무실 화면 데이터 만들기 — OfficeApiController.office() 가 2초마다 호출한다
    // ────────────────────────────────────────────────────────────────────────────
    // ▶ 받는 값: afterMessageId   예) 0 (화면을 처음 열 때), 152 (그 뒤: 화면이 가진 마지막 직원 메시지 번호)
    // ▶ 돌려주는 값: OfficeResponse
    public OfficeResponse office(long afterMessageId) {
        // [흐름 F] 마지막으로 읽은 지 2초가 지났으면 대화 기록 파일을 다시 읽어 DB 를 갱신한다.
        scans.scanIfStale(2000);
        // 가장 최근에 활동한 팀의 이름.   예) "session-2d8e941e"  (쭌의 Claude 세션 번호 앞 8자리)
        String team = currentTeam();
        // [흐름 E-④] tmux 칸을 모두 읽어 사람 이름별로 정리한다. (아래 readScreens() 메서드)
        //   screens.available = tmux 를 읽었는가      screens.byName = {"team-lead": PaneReading, "jihun": PaneReading, …}
        //   screens.tasks     = 쭌 칸의 팀 목록에서 읽은 "직원 → 맡은 일"     예) {"jihun": "자료 조사"}
        Screens screens = readScreens();
        // Map = "열쇠 → 값" 짝을 담는 자료형. 여기서는 직원 영문 이름 → TeamMember 엔티티.
        Map<String, TeamMember> memberByName = new HashMap<>();
        // [흐름 E-⑤] 이 팀의 직원 기록을 DB 에서 가져와 이름별로 Map 에 넣는다.
        //   SQL: select … from team_member tm1_0 where tm1_0.team_name=?
        //   .forEach(m -> …) : 목록의 원소마다 괄호 안의 동작을 실행한다.
        if (team != null) members.findByTeamName(team).forEach(m -> memberByName.put(Names.canonical(m.getName()), m));

        // 자리: 기본 5자리 + 화면·기록에서 처음 보는 사람(예: 신입)
        // 화면에 책상을 놓을 사람의 이름 목록. LinkedHashSet = 같은 값은 한 번만 담고, 넣은 순서를 기억하는 모음.
        //   (1) 직원 명부 순서로 먼저 넣는다          예) [team-lead, minjun, jihun, seoyeon, taeyang, tepo]
        //   (2) tmux 화면에만 있는 사람을 덧붙인다
        //   (3) DB 기록에만 있는 사람을 덧붙인다     → 명부에 없는 사람도 책상이 생긴다
        LinkedHashSet<String> names = new LinkedHashSet<>(Names.seats());
        names.addAll(screens.byName.keySet());
        names.addAll(memberByName.keySet());

        Instant now = Instant.now();
        List<AgentStatusResponse> agents = new ArrayList<>();
        // [흐름 E-⑥] 사람마다 상태를 정하고 AgentStatusResponse 를 하나씩 만든다.
        for (String name : names) {
            // 이 사람의 tmux 화면 해석 결과. 칸이 없으면 null.
            PaneReading r = screens.byName.get(name);
            // 마지막 활동 시각을 정한다.
            //   쭌이면 → leadLastActive(team)
            //   아니면 → (1) memberByName.get(name)         직원 기록 (없으면 null)
            //            (2) Optional.ofNullable(…)         null 일 수 있는 값을 Optional 에 담는다
            //            (3) .map(TeamMember::getLastActive) 값이 있으면 그 직원의 마지막 활동 시각을 꺼낸다
            //            (4) .orElse(null)                  없으면 null
            Instant last = Names.isLead(name) ? leadLastActive(team) : Optional.ofNullable(memberByName.get(name)).map(TeamMember::getLastActive).orElse(null);
            PaneReading.Status status;
            // 상태 정하기 (위에서부터 차례로 검사하고 처음 맞는 조건에서 끝난다)
            //   1) tmux 칸이 있으면 → 화면 글자로 판단한 상태 (WORKING · WAITING · IDLE)
            if (r != null) status = r.status();
            //   2) tmux 는 읽었는데 이 사람의 칸이 없으면 → OFFLINE (자리 비움)
            else if (screens.available) status = PaneReading.Status.OFFLINE; // tmux 는 있는데 칸이 없음 = 자리에 없음
            //   3) tmux 를 못 읽었고, 마지막 활동이 60초 안이면 → WORKING
            //      Duration.between(last, now) = 두 시각 사이의 길이.  .compareTo(ACTIVE) < 0 = ACTIVE(60초)보다 짧다
            else if (last != null && Duration.between(last, now).compareTo(ACTIVE) < 0) status = PaneReading.Status.WORKING;
            //   4) 활동 기록은 있지만 60초가 지났으면 → IDLE (대기)
            else if (last != null) status = PaneReading.Status.IDLE;
            //   5) 활동 기록이 없으면 → OFFLINE
            else status = PaneReading.Status.OFFLINE;
            // 이 사람이 보낸 직원 메시지 수.  SQL: select count(tm1_0.id) from team_message tm1_0 where tm1_0.team_name=? and tm1_0.from_name=?
            long sent = team == null ? 0 : teamMessages.countByTeamNameAndFromName(team, name);
            // 책상 하나의 값을 만들어 목록에 넣는다. 괄호 안의 값 순서는 AgentStatusResponse 의 필드 순서와 같다.
            //   status.name()  = enum 상수의 이름      예) "IDLE"
            //   status.label() = 한글 표시             예) "대기"
            //   r == null ? null : r.activity()        칸이 없으면 null, 있으면 화면에서 읽은 작업 줄
            //   r.lastLines(14)                        화면의 마지막 14줄 (칸이 없으면 빈 목록 List.of())
            agents.add(new AgentStatusResponse(name, Names.korean(name), Names.role(name), Names.team(name), status.name(), status.label(),
                    r == null ? null : r.activity(), r == null ? null : r.spinner(), screens.tasks.get(name),
                    r == null ? List.of() : r.lastLines(SCREEN_LINES), last, sent));
        }

        // 이 팀의 직원 메시지 중 afterMessageId 보다 새 것 (처음 열 때는 최근 30개).   봉투 애니메이션에 쓰인다.
        List<TeamMessageResponse> msgs = recentTeamMessages(team, afterMessageId, 30);
        // (1) dashboard.allBooks()                 책 목록 (최신 책이 먼저)
        // (2) .stream().findFirst()                첫 번째(가장 최근) 책
        // (3) .map(BookSummaryResponse::from)      있으면 응답용 객체로 바꾼다
        // (4) .orElse(null)                        책이 하나도 없으면 null
        BookSummaryResponse book = dashboard.allBooks().stream().findFirst().map(BookSummaryResponse::from).orElse(null);
        // 쭌의 칸이 있고 그 상태가 WAITING 이면 true. 칸이 없으면 false.
        boolean leadWaiting = Optional.ofNullable(screens.byName.get("team-lead")).map(r -> r.status() == PaneReading.Status.WAITING).orElse(false);
        // [흐름 E-⑥] 모은 값을 OfficeResponse 하나로 묶어 돌려준다. → OfficeApiController 가 JSON 으로 응답한다 [흐름 E-⑦]
        return new OfficeResponse(screens.available ? "tmux" : "기록", team, book, agents, msgs, leadWaiting, now);
    }

    /** 직원 명부 (쭌 먼저) */
    public List<StaffResponse> staff() {
        // 직원 명부(Names 에 등록된 사람)를 응답용 객체 목록으로 바꾼다.
        return Names.all().stream().map(StaffResponse::from).toList();
    }

    /** 한 사람의 tmux 칸 화면 전체 (확대 보기). 칸이 없으면 404 */
    public ScreenResponse screen(String name) {
        // 주소로 받은 이름을 하나의 표기로 맞춘다.   예) "JIHUN" → "jihun", "minjun-2" → "minjun"
        String key = Names.canonical(name);
        PaneReading r = readScreens().byName.get(key);
        // 그 사람의 tmux 칸이 없으면 404. 문장 예) "지훈의 화면이 지금은 없어요. …"
        if (r == null) throw new NotFoundException(Names.korean(key) + "의 화면이 지금은 없어요. 아직 출근 전이거나 일을 마치고 나갔어요.");
        return new ScreenResponse(key, Names.korean(key), r.status().name(), r.status().label(), r.screen());
    }

    /** 가벼운 알림용: 쭌이 허용을 기다리는지, 누가 일하는지 */
    public OfficeStatusResponse status() {
        Screens s = readScreens();
        // s.byName 의 "이름 → 화면 해석" 짝 중에서 상태가 WORKING 인 사람만 골라 한글 이름 목록으로 만든다.
        //   entrySet() = Map 의 짝(열쇠와 값)들     e.getKey() = 이름, e.getValue() = PaneReading
        List<String> working = s.byName.entrySet().stream()
                .filter(e -> e.getValue().status() == PaneReading.Status.WORKING).map(e -> Names.korean(e.getKey())).toList();
        boolean waiting = Optional.ofNullable(s.byName.get("team-lead")).map(r -> r.status() == PaneReading.Status.WAITING).orElse(false);
        return new OfficeStatusResponse(s.available, waiting, working);
    }

    /**
     * 회의실. bookId 가 있으면 그 책의 회의 전체(다시 보기용), 없으면 지금 팀의 최근 회의.
     */
    // ────────────────────────────────────────────────────────────────────────────
    // 회의실 데이터 — OfficeApiController.meeting() 이 3초마다 호출한다
    // ────────────────────────────────────────────────────────────────────────────
    // ▶ 받는 값: bookId (null 이면 실시간 모드), afterMessageId
    // ▶ 돌려주는 값: MeetingResponse
    public MeetingResponse meeting(Long bookId, long afterMessageId) {
        scans.scanIfStale(2000);
        BookView v;
        List<TeamMessageResponse> msgs;
        String team;
        // 다시 보기 모드: 그 책을 만드는 동안의 직원 메시지 전체를 돌려준다.
        if (bookId != null) {
            v = dashboard.bookOrThrow(bookId);
            msgs = v.teamMessages().stream().filter(m -> m.getId() > afterMessageId).map(TeamMessageResponse::from).toList();
            team = v.teamMessages().isEmpty() ? null : v.teamMessages().get(v.teamMessages().size() - 1).getTeamName();
        // 실시간 모드: 지금 팀의 최근 메시지(처음엔 200개까지)를 돌려준다.
        } else {
            team = currentTeam();
            v = dashboard.allBooks().stream().findFirst().orElse(null);
            msgs = recentTeamMessages(team, afterMessageId, 200);
        }
        Instant lastAt = team == null ? null : teamMessages.findTop200ByTeamNameOrderByIdDesc(team).stream()
                .map(TeamMessage::getAt).filter(Objects::nonNull).findFirst().orElse(null);
        // 마지막 메시지가 2분 안이면 true("회의 중").
        boolean live = lastAt != null && Duration.between(lastAt, Instant.now()).compareTo(LIVE) < 0;
        // 화이트보드에 적을 장 제목 목록.   예) ["1장. 나가기 전에 알아 둘 것", "2장. 첫 10분 산책", …]
        List<String> chapters = v == null ? List.of() : dashboard.chapters(v).stream().map(ChapterPreview::title).toList();
        // 사장님이 최근에 보낸 말 5개 (최신 것부터).
        // SQL: select … from chat_message cm1_0 where cm1_0.direction=? order by cm1_0.at desc fetch first ? rows only
        List<ChatMessageResponse> notes = new ArrayList<>(chats.findTop5ByDirectionOrderByAtDesc(ChatMessage.Direction.FROM_BOSS)
                .stream().map(ChatMessageResponse::from).toList());
        // 오래된 것부터 보이도록 순서를 뒤집는다.
        Collections.reverse(notes);
        return new MeetingResponse(team, v == null ? null : v.book().getId(), v == null ? null : v.book().displayTitle(),
                v == null ? null : v.book().getStage().getLabel(), chapters, live, msgs, notes);
    }

    /** 가장 최근에 움직인 팀(쭌의 세션) */
    // 가장 최근에 움직인 팀의 이름을 정한다. (public 이 없다 = 같은 패키지에서만 호출)
    // 직원 기록의 마지막 활동 시각과 직원 메시지의 마지막 시각 중 더 최근 쪽의 팀을 고른다.
    String currentTeam() {
        TeamMember m = members.findAllByOrderByLastActiveDesc().stream().filter(x -> x.getLastActive() != null).findFirst().orElse(null);
        TeamMessage t = teamMessages.findTopByOrderByAtDesc().orElse(null);
        if (m == null) return t == null ? null : t.getTeamName();
        if (t == null || t.getAt() == null) return m.getTeamName();
        return m.getLastActive().isAfter(t.getAt()) ? m.getTeamName() : t.getTeamName();
    }

    // 쭌의 마지막 활동 시각 = (쭌이 직원에게 보낸 마지막 메시지 시각) 과 (쭌이 사장님께 보낸 마지막 메시지 시각) 중 더 최근.
    // 쭌은 team_member 표에 기록되지 않으므로(직원만 기록) 메시지 시각으로 대신 정한다.
    private Instant leadLastActive(String team) {
        Instant a = team == null ? null : teamMessages.findTop200ByTeamNameOrderByIdDesc(team).stream()
                .filter(x -> Names.isLead(x.getFromName())).map(TeamMessage::getAt).filter(Objects::nonNull).findFirst().orElse(null);
        Instant b = chats.findTop200ByOrderByAtDescIdDesc().stream()
                .filter(c -> c.getDirection() == ChatMessage.Direction.TO_BOSS).map(ChatMessage::getAt).filter(Objects::nonNull).findFirst().orElse(null);
        if (a == null) return b;
        if (b == null) return a;
        return a.isAfter(b) ? a : b;
    }

    // 팀의 직원 메시지 중 after 번보다 새 것. after 가 0 이면 마지막 limitWhenFirst 개만.
    private List<TeamMessageResponse> recentTeamMessages(String team, long after, int limitWhenFirst) {
        if (team == null) return List.of();
        List<TeamMessage> list = new ArrayList<>(teamMessages.findTop200ByTeamNameOrderByIdDesc(team));
        Collections.reverse(list);
        if (after > 0) list.removeIf(m -> m.getId() <= after);
        // subList(시작, 끝) = 목록의 일부. 끝에서 limitWhenFirst 개만 남긴다.   예) 원소 50개, limit 30 → 20번째부터 49번째까지
        else if (list.size() > limitWhenFirst) list = list.subList(list.size() - limitWhenFirst, list.size());
        return list.stream().map(TeamMessageResponse::from).toList();
    }

    /** tmux 칸들을 읽어 이름별로 정리 */
    // [흐름 E-④] tmux 칸을 모두 읽고, 칸마다 PaneReading.read() 로 해석해 이름별로 정리한다.
    private Screens readScreens() {
        // tmux 명령으로 칸 목록과 각 칸의 화면 글자를 가져온다. tmux 가 없거나 세션이 없으면 빈 목록.
        //   실제로 실행되는 명령: tmux -u list-panes -t publisher:team -F "#{pane_id}\t#{pane_index}\t#{pane_title}"
        //                        tmux -u capture-pane -p -J -t %3 -S -80   (칸마다)
        List<TmuxClient.Pane> panes = tmux.capture();
        Screens s = new Screens();
        // 칸이 하나라도 있으면 tmux 를 읽은 것으로 본다.
        s.available = !panes.isEmpty();
        for (TmuxClient.Pane p : panes) {
            // 칸 하나의 화면 글자를 해석한다. 0번 칸은 쭌의 칸이다.
            //   예) p.title() = "jihun" → r.name() = "jihun", r.status() = WORKING, r.activity() = "Web Search(…)"
            PaneReading r = PaneReading.read(p.lines(), p.title(), p.index() == 0);
            if (r.name() != null) s.byName.put(Names.canonical(r.name()), r);
            // 쭌의 칸 아래쪽 팀 목록("◯ jihun 자료 조사 11s")에서 직원별 맡은 일을 읽는다.
            if (p.index() == 0) s.tasks.putAll(PaneReading.teamTasks(p.lines()));
        }
        return s;
    }

    // 이 클래스 안에서만 쓰는 작은 클래스. readScreens() 의 결과 세 가지를 함께 담는다.
    //   available : tmux 를 읽었는가
    //   byName    : 이름 → PaneReading    (LinkedHashMap: 넣은 순서를 기억하는 Map)
    //   tasks     : 이름 → 맡은 일
    private static final class Screens {
        boolean available;
        final Map<String, PaneReading> byName = new LinkedHashMap<>();
        final Map<String, String> tasks = new HashMap<>();
    }
}
