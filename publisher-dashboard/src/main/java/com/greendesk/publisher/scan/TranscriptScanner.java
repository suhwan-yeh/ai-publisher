/*
 * [1] 역할
 *     Claude Code 가 남기는 대화 기록 파일(*.jsonl)을 읽어 DB 에 넣는다.
 *     jsonl = 한 줄에 JSON 하나씩 적힌 글자 파일. Claude Code 는 대화가 진행될 때마다 파일 끝에 줄을 덧붙인다.
 *     한 줄에서 찾는 것 네 가지:
 *       (1) 사장님 → 쭌      : <channel source=...> 로 감싼 사용자 메시지          → chat_message (FROM_BOSS)
 *       (2) 쭌 → 사장님      : 이름이 __reply 로 끝나는 도구 호출                  → chat_message (TO_BOSS)
 *       (3) 팀원끼리 메시지   : SendMessage 도구 호출                               → team_message
 *       (4) 팀원 출석·책 연결 : agentName 이 있는 줄, 도구 입력의 books/폴더/ 경로   → team_member, book_session
 *     이미 읽은 줄 수를 파일마다 기억해 두고, 다음에는 새로 붙은 줄만 읽는다.
 *
 * [2] 받는 것 → 내보내는 것 (실제로 실행해서 얻은 값)
 *     받는 것 (테스트 자료 fixture/transcripts/*.jsonl 의 실제 줄, 길어서 줄임)
 *       사장님 말  {"type":"user","message":{"content":"<channel source=\"plugin:fakechat:fakechat\" chat_id=\"web\" message_id=\"t1\" user=\"web\" ts=\"2026-11-09T11:32:56.190Z\">\n우리 딸이 좋아할 만한, 바다를 건너는 아기 …</channel>"},…}
 *       쭌의 답    {"type":"assistant","message":{"content":[{"type":"tool_use","name":"mcp__plugin_fakechat_fakechat__reply","input":{"text":"접수했습니다. 팀을 꾸려 기획을 시작합니다.","reply_to":"t1"}}]},…}
 *       팀원 대화  {"type":"assistant","agentName":"seoyeon",…,"content":[{"type":"tool_use","name":"SendMessage","input":{"to":"jihoon","message":"…"}}]}
 *     내보내는 것 (실제 SQL)
 *       insert into chat_message (at,attachment_paths,attachments,channel,direction,team_name,text,unique_key,id) values (?,?,?,?,?,?,?,?,default)
 *       insert into team_message (at,from_name,kind,team_name,text,to_name,unique_key,id) values (?,?,?,?,?,?,?,default)
 *       insert into team_member (first_seen,last_active,name,role,team_name,id) values (?,?,?,?,?,default)
 *       insert into book_session (folder,team_name,id) values (?,?,default)
 *       돌려주는 값: 새로 저장한 건수.  예) 처음 실행 383
 *
 * [3] 앞뒤 파일
 *     service/ScanService.java 의 scanNow()  →  (이 파일)  →  repository/ChatMessageRepository.java, TeamMessageRepository.java,
 *                                                              TeamMemberRepository.java, BookSessionRepository.java
 *     기록 위치: config/PublisherProperties.java 의 transcriptsPath()     이름 정리: domain/Names.java
 *     관리 화면에서 보낸 말과 겹치지 않게 하는 규칙: client/FakechatClient.java 의 ID_PREFIX, chatKey()
 *
 * [4] 메서드 목록
 *     메서드                              하는 일                                                    흐름 번호
 *     scan()                              기록 폴더 아래 모든 *.jsonl 에 scanFile() 을 부른다              흐름 F-④
 *     scanFile(파일)                       새로 붙은 줄만 JSON 으로 읽어 handle() 에 넘긴다                  흐름 F-④
 *     handle(줄, …)                        줄 하나에서 누가·어느 팀·어떤 종류인지 가린다                     흐름 F-④
 *     touchMember(팀, 이름, 시각)          팀원의 마지막 활동 시각을 고친다
 *     teamMessage(…)                      SendMessage → team_message 한 행
 *     leadReply(…)                        __reply 도구 → chat_message (TO_BOSS) 한 행
 *     bossMessages(글, …)                  <channel …> 마다 chat_message (FROM_BOSS) 한 행
 *     linkBook(팀, 입력)                   books/폴더/ 경로를 보면 book_session 한 행
 *     subagentName / subagentTeam         파일 이름·위치로 팀원 이름과 팀을 알아낸다     예) "seoyeon", "session-ad6f13d3"
 *     text / parseTime                    JSON 값 꺼내기, 시각 글자를 Instant 로 바꾸기
 *
 * [5] 먼저 알 용어 (자세한 설명: docs/용어-풀이.md)
 *     @Component, @Transactional, synchronized, Map·HashMap, BufferedReader, Jackson(ObjectMapper·JsonNode), 정규식(Pattern·Matcher·group), Optional, 삼항 연산자(a ? b : c)
 *
 * [6] 읽는 순서
 *     scan() → scanFile() → handle() → bossMessages() → leadReply() → teamMessage() → 나머지
 *
 * [7] 다 읽고 확인
 *     - 관리 화면에서 보낸 말(message_id 가 "web-" 로 시작)이 기록에 다시 나오면 chat_message 에 두 번 저장되는가? (아니다. bossMessages() 의 if 블록)
 *     - 10초 뒤 같은 파일을 다시 읽을 때, 이미 읽은 100줄은 다시 JSON 으로 바꾸는가? (아니다. scanFile() 의 lineNo <= done)
 */
package com.greendesk.publisher.scan;

import com.greendesk.publisher.client.FakechatClient;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.greendesk.publisher.config.PublisherProperties;
import com.greendesk.publisher.domain.*;
import com.greendesk.publisher.repository.BookSessionRepository;
import com.greendesk.publisher.repository.ChatMessageRepository;
import com.greendesk.publisher.repository.TeamMemberRepository;
import com.greendesk.publisher.repository.TeamMessageRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.io.BufferedReader;
import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.time.Instant;
import java.util.*;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import java.util.stream.Stream;

/**
 * Claude Code 대화 기록(jsonl)을 읽는다.
 * - 팀원 기록: agentName(칸 나눔 모드) 또는 subagents/agent-a이름-*.jsonl(한 화면 모드)
 * - 팀원끼리 메시지: SendMessage 도구 호출
 * - 사장님 → 쭌: <channel source=...> 메시지
 * - 쭌 → 사장님: 이름이 __reply 로 끝나는 도구 호출 (텔레그램/fakechat)
 * 파일이 커져도 새로 붙은 줄만 읽는다.
 */
// @Component
//   뜻     : 스프링이 이 클래스의 객체를 하나 만들어 관리한다. 객체가 하나뿐이므로 아래 readLines 기억도 프로그램이 켜져 있는 동안 유지된다.
@Component
public class TranscriptScanner {

    private static final Logger log = LoggerFactory.getLogger(TranscriptScanner.class);
    // CHANNEL: <channel 속성들>본문</channel> 을 찾는 정규식.
    //   group(1) = 속성 부분   예) source="plugin:fakechat:fakechat" chat_id="web" message_id="t1" user="web" ts="2026-11-09T11:32:56.190Z"
    //   group(2) = 본문        예) "\n우리 딸이 좋아할 만한, 바다를 건너는 아기 …"
    //   (.*?) 의 ? = 가장 짧게 맞춘다. 메시지가 두 개 있으면 따로 찾는다.   DOTALL = 점(.)이 줄바꿈에도 맞는다.
    private static final Pattern CHANNEL = Pattern.compile("<channel\\s+([^>]*)>(.*?)</channel>", Pattern.DOTALL);
    // ATTR: 이름="값" 하나를 찾는 정규식.  group(1)=이름, group(2)=값.   예) message_id="t1" → ("message_id", "t1")
    private static final Pattern ATTR = Pattern.compile("(\\w+)=\"([^\"]*)\"");
    // BOOK_PATH: "books/폴더이름/" 을 찾는 정규식.  예) ".../books/20261109-dogwalk/plan/order.md" → group(1)="20261109-dogwalk"
    private static final Pattern BOOK_PATH = Pattern.compile("books/([A-Za-z0-9._-]+)/");
    // SUBAGENT_FILE: 한 화면 모드의 팀원 기록 파일 이름.  예) "agent-aseoyeon-1a2b3c.jsonl" → group(1)="seoyeon"
    private static final Pattern SUBAGENT_FILE = Pattern.compile("agent-a([a-z0-9]+)-[0-9a-f]+\\.jsonl");

    private final PublisherProperties props;
    private final TeamMessageRepository teamMessages;
    private final ChatMessageRepository chats;
    private final TeamMemberRepository members;
    private final BookSessionRepository bookSessions;
    // ObjectMapper(Jackson 라이브러리): JSON 글자 ↔ 자바 객체를 바꾼다. 여기서는 글자를 JsonNode(JSON 나무 구조)로 읽는다.
    private final ObjectMapper json = new ObjectMapper();
    /** 파일별로 이미 읽은 줄 수 */
    // readLines: 파일 경로 → 이미 읽은 줄 수.   예) {…/ad6f13d3-….jsonl=176, …/18ecadb0-….jsonl=13}
    // 메모리에만 있으므로 프로그램을 다시 켜면 처음부터 다시 읽는다. 그래도 아래 existsByUniqueKey 검사 때문에 같은 메시지가 두 번 저장되지 않는다.
    private final Map<Path, Long> readLines = new HashMap<>();

    // 생성자 주입: 스프링이 Repository 네 개와 설정 객체를 만들어 넘긴다.
    public TranscriptScanner(PublisherProperties props, TeamMessageRepository teamMessages,
                             ChatMessageRepository chats, TeamMemberRepository members,
                             BookSessionRepository bookSessions) {
        this.props = props;
        this.teamMessages = teamMessages;
        this.chats = chats;
        this.members = members;
        this.bookSessions = bookSessions;
    }

    // [흐름 F-④]
    // @Transactional: 파일 수백 줄을 읽으며 생기는 insert/update 를 하나의 트랜잭션으로 묶는다. 중간에 예외가 나면 모두 되돌린다.
    @Transactional
    public synchronized int scan() {
        // dir 예) /root/.claude/projects/-root-my-publisher   (쭌이 일하는 폴더 이름으로 Claude Code 가 만든 기록 폴더)
        Path dir = props.transcriptsPath();
        if (!Files.isDirectory(dir)) return 0;
        int added = 0;
        // Files.walk: 하위 폴더까지 모두 본다. 한 화면 모드의 팀원 기록은 …/세션번호/subagents/ 아래에 있기 때문이다.
        try (Stream<Path> s = Files.walk(dir)) {
            // 확장자가 .jsonl 인 파일만, 이름순으로.
            for (Path f : s.filter(p -> p.toString().endsWith(".jsonl")).sorted().toList()) {
                added += scanFile(f);
            }
        } catch (IOException e) {
            log.warn("대화 기록을 읽지 못했어요: {}", e.getMessage());
        }
        return added;
    }

    int scanFile(Path f) {
        // done: 지난번까지 읽은 줄 수. 처음 보는 파일이면 0.   예) 176
        long done = readLines.getOrDefault(f, 0L);
        long lineNo = 0;
        int added = 0;
        // 파일 이름으로 정해지는 팀원 이름. 쭌의 기록 파일이면 null.
        String fileAgent = subagentName(f);
        String fileTeam = subagentTeam(f);
        // BufferedReader: 파일을 한 줄씩 읽는다. 큰 파일도 한꺼번에 메모리에 올리지 않는다.
        try (BufferedReader r = Files.newBufferedReader(f, StandardCharsets.UTF_8)) {
            String line;
            // (1) r.readLine()  다음 줄을 읽어 line 에 넣는다. 파일 끝이면 null.
            // (2) != null       끝이 아니면 반복한다.
            while ((line = r.readLine()) != null) {
                lineNo++;
                // 이미 읽은 줄과 빈 줄은 건너뛴다.  예) done=176 이면 1~176번 줄은 건너뛰고 177번 줄부터 처리한다.
                if (lineNo <= done || line.isBlank()) continue;
                JsonNode e;
                try {
                    // 줄 글자 → JsonNode.   예) e.path("type").asText() = "assistant"
                    e = json.readTree(line);
                } catch (IOException bad) {
                    // JSON 이 아닌 줄 = Claude Code 가 아직 쓰고 있어 끝이 잘린 마지막 줄. 줄 번호를 하나 되돌리고 멈춘다. 다음 10초 뒤 이 줄부터 다시 읽는다.
                    lineNo--; // 아직 쓰는 중인 마지막 줄 → 다음에 다시 읽기
                    break;
                }
                // [흐름 F-④] 줄 하나 처리. 저장한 건수를 더한다.
                added += handle(e, fileAgent, fileTeam);
            }
        } catch (IOException e) {
            log.debug("읽기 실패 {}: {}", f, e.getMessage());
        }
        // 이번에 읽은 마지막 줄 번호를 기억한다.
        readLines.put(f, lineNo);
        return added;
    }

    private int handle(JsonNode e, String fileAgent, String fileTeam) {
        // e.path("timestamp") : "timestamp" 값. 없으면 빈 노드(MissingNode)를 준다(get() 과 달리 null 이 아니다).
        // .asText(null)       : 글자로 꺼낸다. 값이 없으면 null.
        // 예) "2026-11-09T11:32:56.190Z" → Instant 2026-11-09T11:32:56.190Z
        Instant at = parseTime(e.path("timestamp").asText(null));
        // agent: 이 줄을 쓴 팀원 이름. 칸 나눔 모드에서는 줄마다 agentName 이 적혀 있다.  예) "seoyeon"   쭌의 줄이면 null
        String agent = text(e, "agentName");
        if (agent == null) agent = fileAgent;
        // team: 팀 이름. 없으면 파일 위치로, 그래도 없으면 세션 번호로 정한다.
        String team = text(e, "teamName");
        if (team == null) team = fileTeam;
        if (team == null && e.hasNonNull("sessionId")) {
            String sid = e.get("sessionId").asText();
            // 세션 번호 앞 8글자.  예) sessionId="ad6f13d3-a46d-41df-…" → team="session-ad6f13d3"
            team = "session-" + sid.substring(0, Math.min(8, sid.length()));
        }
        // 삼항 연산자 조건 ? 참일 때 : 거짓일 때
        // agent 가 없으면 쭌("team-lead"), 있으면 이름을 한 가지 모양으로 맞춘다.  예) "jihoon" → "jihun", "minjun-2" → "minjun"
        String me = agent == null ? "team-lead" : Names.canonical(agent);

        // 팀원의 줄이면 출석 기록. 사무실 화면의 "자리에 있음" 표시가 이 시각으로 정해진다.
        if (agent != null && at != null) touchMember(team, me, at);

        int added = 0;
        // content: 메시지 본문. 사용자 줄이면 글자, 어시스턴트 줄이면 배열 [{type:"text",…}, {type:"tool_use",…}].
        JsonNode content = e.path("message").path("content");
        String type = e.path("type").asText();

        // 쭌이 받은 사용자 메시지 = 채널로 들어온 사장님 말이 있을 수 있다. ("user".equals(type) 은 type 이 null 이어도 예외가 나지 않는 비교 방식)
        if ("user".equals(type) && agent == null) {
            // content 가 글자면 그대로, 배열이면 JSON 글자로 바꿔 <channel 을 찾는다.
            String all = content.isTextual() ? content.asText() : content.toString();
            if (all.contains("<channel")) added += bossMessages(all, at, team);
        }
        // 어시스턴트(쭌 또는 팀원)가 한 말과 도구 호출.
        if ("assistant".equals(type) && content.isArray()) {
            for (JsonNode c : content) {
                // 도구 호출(tool_use)만 본다. 그냥 글(text)은 건너뛴다.
                if (!"tool_use".equals(c.path("type").asText())) continue;
                String name = c.path("name").asText();
                // 도구 호출 고유 번호. DB 의 unique_key 로 써서 같은 호출을 두 번 저장하지 않는다.  예) "toolu_01…"
                String id = c.path("id").asText(UUID.randomUUID().toString());
                JsonNode input = c.path("input");
                // 도구 입력에 책 폴더 경로가 있으면 이 팀이 그 책을 맡은 것으로 기록한다.
                linkBook(team, input.toString());
                // 팀원끼리 메시지.
                if ("SendMessage".equals(name)) added += teamMessage(id, team, me, input, at);
                // 쭌이 사장님에게 답한 것. 도구 이름 예) "mcp__plugin_fakechat_fakechat__reply"(관리 화면), "mcp__plugin_telegram_telegram__reply"(텔레그램)
                else if (name.endsWith("__reply") && agent == null) added += leadReply(id, name, input, at, team);
            }
        }
        return added;
    }

    private void touchMember(String team, String name, Instant at) {
        // 쭌(편집장)은 팀원 표에 넣지 않는다.
        if (Names.isLead(name)) return;
        // (1) findByTeamNameAndName  SQL: select … from team_member tm1_0 where tm1_0.team_name=? and tm1_0.name=?
        // (2) .orElseGet(…)          없으면 새 팀원.  역할 예) Names.role("seoyeon") = "집필"
        TeamMember m = members.findByTeamNameAndName(team, name)
                .orElseGet(() -> new TeamMember(team, name, Names.role(name), at));
        // last_active 를 이 줄의 시각으로 고친다 → SQL: update team_member set first_seen=?,last_active=?,… where id=?
        m.touch(at);
        members.save(m);
    }

    private int teamMessage(String id, String team, String from, JsonNode input, Instant at) {
        // SQL: select tm1_0.id from team_message tm1_0 where tm1_0.unique_key=? fetch first ? rows only   이미 있으면 저장하지 않는다.
        if (teamMessages.existsByUniqueKey(id)) return 0;
        // 받는 사람. "to" 가 없으면 "recipient", 그것도 없으면 "?".   예) input={"to":"jihoon",…} → to="jihun" (Names.canonical 이 철자를 맞춘다)
        String to = Names.canonical(input.path("to").asText(input.path("recipient").asText("?")));
        // 메시지 본문은 "message" 에 있고, 옛 형식은 "content" 에 있다.
        JsonNode msg = input.has("message") ? input.get("message") : input.path("content");
        TeamMessage.Kind kind;
        String text;
        // 본문이 글자가 아니라 객체면 제어 메시지다.  예) {"type":"shutdown_request","reason":"작업 끝"} → text="shutdown_request — 작업 끝"
        if (msg.isObject()) {
            text = msg.path("type").asText("") + (msg.has("reason") ? " — " + msg.get("reason").asText() : "");
            kind = TeamMessage.Kind.CONTROL;
        } else {
            text = msg.asText("");
            // "[보고]" 가 들어 있거나 팀원이 쭌에게 보낸 것이면 REPORT(보고), 아니면 TALK(팀원끼리 의논).
            // 사무실 화면에서 REPORT 는 쭌에게 가는 봉투, TALK 는 팀원 사이의 봉투로 그려진다.
            kind = (text.contains("[보고]") || (Names.isLead(to) && !Names.isLead(from))) ? TeamMessage.Kind.REPORT : TeamMessage.Kind.TALK;
        }
        // SQL: insert into team_message (at,from_name,kind,team_name,text,to_name,unique_key,id) values (?,?,?,?,?,?,?,default)
        teamMessages.save(new TeamMessage(id, team, from, to, text, kind, at));
        return 1;
    }

    private int leadReply(String id, String toolName, JsonNode input, Instant at, String team) {
        // 같은 답을 이미 저장했으면 0.
        if (chats.existsByUniqueKey(id)) return 0;
        List<String> files = new ArrayList<>();
        List<String> paths = new ArrayList<>();
        // 쭌이 파일을 붙여 보냈으면 files 배열에 경로가 있다.
        // 예) ["/root/my-publisher/books/20261109-dogwalk/dist/book.pdf"] → paths=[그 경로], files=["book.pdf"]
        input.path("files").forEach(f -> {
            paths.add(f.asText());
            files.add(Path.of(f.asText()).getFileName().toString());
        });
        // 도구 이름으로 어느 통로로 답했는지 정한다.  "…fakechat…" → "web", "…telegram…" → "telegram"
        String channel = toolName.contains("fakechat") ? "web" : toolName.contains("telegram") ? "telegram" : null;
        // (1) new ChatMessage(…, TO_BOSS, 답 글, "book.pdf", 시각)   쭌 → 사장님 메시지 객체
        // (2) .withChannel(channel)                                 "web" 또는 "telegram"
        // (3) .withAttachmentPaths(paths)                           내려받기 버튼이 쓸 실제 경로
        // (4) chats.save(…)   SQL: insert into chat_message (at,attachment_paths,attachments,channel,direction,team_name,text,unique_key,id) values (…)
        // 대화방 화면은 3초마다 폴링(흐름 B′)하므로 이 행이 저장되면 곧 말풍선으로 나타난다.
        chats.save(new ChatMessage(id, team, ChatMessage.Direction.TO_BOSS, input.path("text").asText(""), String.join(", ", files), at)
                .withChannel(channel).withAttachmentPaths(paths));
        return 1;
    }

    private int bossMessages(String all, Instant fallback, String team) {
        int n = 0;
        // content 를 JSON 글자로 바꾼 경우 따옴표가 \" , 줄바꿈이 \n 으로 적혀 있다. 정규식을 맞추기 전에 원래 글자로 되돌린다.
        Matcher m = CHANNEL.matcher(all.replace("\\\"", "\"").replace("\\n", "\n"));
        // <channel …>…</channel> 이 한 줄에 여러 개 있을 수 있어 하나씩 처리한다.
        while (m.find()) {
            Map<String, String> attrs = new HashMap<>();
            Matcher a = ATTR.matcher(m.group(1));
            // 속성들을 Map 으로 모은다.
            // 예) attrs = {source=plugin:fakechat:fakechat, chat_id=web, message_id=t1, user=web, ts=2026-11-09T11:32:56.190Z}
            while (a.find()) attrs.put(a.group(1), a.group(2));
            String messageId = attrs.getOrDefault("message_id", "");
            // 관리 화면에서 보낸 메시지는 보낼 때 이미 저장했으니 세션만 이어 붙인다
            // message_id 가 "web-" 로 시작 = 관리 화면에서 보낸 말. ChatService.send() 가 보낼 때 이미 chat_message 에 저장했다(흐름 B-④).
            // 그래서 새로 저장하지 않고, 팀 이름이 비어 있으면 채우기만 한다.
            // 없으면: 관리 화면에서 보낸 말풍선이 대화방에 두 번 보인다.
            if (messageId.startsWith(FakechatClient.ID_PREFIX)) {
                // 예) messageId="web-1762724793776-a1b2c3" → unique_key "web:web-1762724793776-a1b2c3" 로 찾는다.
                Optional<ChatMessage> sent = chats.findByUniqueKey(FakechatClient.chatKey(messageId));
                if (sent.isPresent()) {
                    if (sent.get().getTeamName() == null) {
                        sent.get().assignTeam(team);
                        chats.save(sent.get());
                    }
                    continue;
                }
            }
            // 텔레그램 등 다른 통로로 온 말의 고유 키.  예) "ch:t1:2026-11-09T11:32:56.190Z"
            String key = "ch:" + messageId + ":" + attrs.getOrDefault("ts", "");
            if (chats.existsByUniqueKey(key)) continue;
            // ts 속성의 시각, 없으면 줄의 timestamp.
            Instant at = Optional.ofNullable(parseTime(attrs.get("ts"))).orElse(fallback);
            String source = attrs.getOrDefault("source", "");
            String channel = source.contains("fakechat") ? "web" : source.contains("telegram") ? "telegram" : null;
            // 사장님 → 쭌 메시지로 저장한다. m.group(2).trim() = 본문 앞뒤 공백·줄바꿈을 지운 글.
            // 예) "우리 딸이 좋아할 만한, 바다를 건너는 아기 …"
            chats.save(new ChatMessage(key, team, ChatMessage.Direction.FROM_BOSS, m.group(2).trim(), null, at).withChannel(channel));
            n++;
        }
        return n;
    }

    /** 도구 입력에 books/폴더/ 경로가 나오면 그 팀이 그 책을 다룬 것으로 기록 */
    private void linkBook(String team, String inputJson) {
        if (team == null) return;
        Matcher m = BOOK_PATH.matcher(inputJson);
        Set<String> seen = new HashSet<>();
        while (m.find()) {
            String folder = m.group(1);
            // (1) seen.add(folder)                 이 줄에서 처음 본 폴더면 true (같은 경로가 여러 번 나와도 한 번만 검사)
            // (2) existsByFolderAndTeamName(…)     SQL: select bs1_0.id from book_session bs1_0 where bs1_0.folder=? and bs1_0.team_name=? fetch first ? rows only
            // 둘 다 맞으면 insert into book_session (folder,team_name,id) values (?,?,default)
            if (seen.add(folder) && !bookSessions.existsByFolderAndTeamName(folder, team)) {
                bookSessions.save(new BookSession(folder, team));
            }
        }
    }

    static String subagentName(Path f) {
        Matcher m = SUBAGENT_FILE.matcher(f.getFileName().toString());
        // matches(): 파일 이름 전체가 규칙에 맞아야 true (find 는 일부만 맞아도 true).
        return m.matches() ? m.group(1) : null;
    }

    static String subagentTeam(Path f) {
        Path parent = f.getParent();
        // 경로 예) …/-root-my-publisher/ad6f13d3-a46d-41df-9085-89fd02accc37/subagents/agent-aseoyeon-1a2b3c.jsonl
        //   parent              = …/subagents
        //   parent.getParent()  = …/ad6f13d3-a46d-41df-9085-89fd02accc37  → 팀 "session-ad6f13d3"
        if (parent != null && parent.getFileName().toString().equals("subagents") && parent.getParent() != null) {
            String sid = parent.getParent().getFileName().toString();
            return "session-" + sid.substring(0, Math.min(8, sid.length()));
        }
        return null;
    }

    private static String text(JsonNode e, String field) {
        JsonNode v = e.get(field);
        // 값이 없거나, JSON null 이거나, 빈 글자면 null. 아니면 글자.
        return v == null || v.isNull() || v.asText().isBlank() ? null : v.asText();
    }

    static Instant parseTime(String s) {
        if (s == null || s.isBlank()) return null;
        try {
            // Instant.parse: ISO-8601 글자를 시각으로.  예) "2026-11-09T11:32:56.190Z" → 2026-11-09T11:32:56.190Z   모양이 틀리면 예외 → null
            return Instant.parse(s);
        } catch (Exception e) {
            return null;
        }
    }
}
