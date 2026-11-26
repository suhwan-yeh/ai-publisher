/*
 * [1] 역할
 *     직원 명부(publisher-kit/staff.yml)를 검사한다. 새 직원을 Pull Request 로 명부에 넣으면 GitHub Actions 가 이 시험을 실행한다.
 *     명부의 직원마다 이름 규칙, 팀, 색, 에이전트 파일(.claude/agents/이름.md), SendMessage 도구가 있는지 본다.
 *
 * [2] 받는 것 → 내보내는 것 (실제로 실행해서 얻은 값)
 *     받는 것 : ../publisher-kit/staff.yml, ../publisher-kit/.claude/agents/*.md
 *     확인하는 것 예) tepo: 영문 이름 "tepo"([a-z][a-z0-9]*), 한글 "테포", 팀 "ops", 색 "#3ec6e0", tepo.md 에 "name: tepo" 와 tools 줄의 SendMessage
 *     publisher-kit 폴더가 옆에 없으면 건너뛴다(assumeTrue)
 *
 * [3] 앞뒤 파일
 *     (이 파일)  →  config/StaffDirectory.java 의 parse()  →  publisher-kit/staff.yml
 *     .github/workflows 의 CI  →  ./gradlew test  →  (이 파일)
 *
 * [4] 메서드 목록
 *     메서드                        확인하는 것
 *     everyStaffHasAValidAgent      명부의 모든 직원이 규칙에 맞고 에이전트 파일이 있다
 *
 * [5] 먼저 알 용어 (자세한 설명: docs/용어-풀이.md)
 *     assumeTrue, assertThat(…).as("설명"), matches(정규식), isIn, Files.readString, lines().filter
 *
 * [6] 읽는 순서
 *     KIT → everyStaffHasAValidAgent()
 *
 * [7] 다 읽고 확인
 *     - 새 직원 이름을 "신입" 으로 적으면 어느 줄에서 실패하는가? (영문 이름 matches)
 *     - 에이전트 파일의 tools 에 SendMessage 가 없으면 왜 문제인가? (동료와 직접 의논할 수 없어 점검 ② 가 채워지지 않는다)
 */
package com.greendesk.publisher;

import com.greendesk.publisher.config.StaffDirectory;
import com.greendesk.publisher.domain.StaffMember;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.HashSet;
import java.util.Set;

import static org.assertj.core.api.Assertions.assertThat;
import static org.junit.jupiter.api.Assumptions.assumeTrue;

/**
 * "채용은 Pull Request 로" — 직원 명부(publisher-kit/staff.yml)를 CI 가 검사한다.
 * 새 직원을 명부에 넣었는데 에이전트 파일이 없거나, 이름이 한글이거나, 동료와 대화할 도구가 없으면 PR 이 빨간불.
 */
class StaffRegistryTest {

    // 시험은 publisher-dashboard 폴더에서 실행되므로 ".." 위로 한 칸 올라가 publisher-kit 을 찾는다.
    static final Path KIT = Path.of("..", "publisher-kit").toAbsolutePath().normalize();

    @Test
    @DisplayName("직원 명부의 모든 직원: 영문 이름·한글 이름·팀·색이 맞고, 에이전트 파일이 있고, SendMessage 도구를 가진다")
    void everyStaffHasAValidAgent() throws Exception {
        Path staffFile = KIT.resolve("staff.yml");
        // assumeTrue: 조건이 거짓이면 실패가 아니라 "건너뜀"으로 처리한다.
        assumeTrue(Files.isRegularFile(staffFile), "publisher-kit 이 옆에 없으면(관리 화면만 따로 연 경우) 건너뜀");
        StaffDirectory.Parsed p = StaffDirectory.parse(staffFile);
        assertThat(p.lead().korean()).isNotBlank();
        assertThat(p.staff()).isNotEmpty();
        Set<String> names = new HashSet<>();
        long book = 0;
        for (StaffMember s : p.staff()) {
            String who = s.korean() + "(" + s.name() + ")";
            // .as("…"): 실패할 때 보여 줄 설명.  예) "테포(tepo) 영문 이름"
            assertThat(s.name()).as(who + " 영문 이름").matches("[a-z][a-z0-9]*");
            assertThat(names.add(s.name())).as(who + " 이름이 겹침").isTrue();
            assertThat(s.korean()).as(who + " 한글 이름").isNotBlank();
            assertThat(s.role()).as(who + " 역할").isNotBlank();
            assertThat(s.team()).as(who + " 팀").isIn("book", "ops");
            assertThat(s.color()).as(who + " 색").matches("#[0-9a-fA-F]{6}");
            if ("book".equals(s.team())) book++;

            Path agent = KIT.resolve(".claude/agents/" + s.agent() + ".md");
            assertThat(agent).as(who + " 에이전트 파일").isRegularFile();
            String md = Files.readString(agent, StandardCharsets.UTF_8);
            assertThat(md).as(who + " 에이전트 이름").contains("name: " + s.agent());
            String tools = md.lines().filter(l -> l.startsWith("tools:")).findFirst().orElse("");
            assertThat(tools).as(who + " 동료와 대화하는 도구").contains("SendMessage");
        }
        assertThat(book).as("책 만드는 팀은 한 명 이상").isPositive();
    }
}
