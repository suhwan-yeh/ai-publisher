/*
 * [1] 역할
 *     프로그램이 시작할 때 직원 명부(staff.yml)를 읽어 Names 에 등록하는 클래스다.
 *     명부 파일이 없거나 읽지 못하면 기본 4명(민준·지훈·서연·태양)으로 시작한다.
 *
 * [2] 받는 것 → 내보내는 것 (실제로 실행해서 얻은 값)
 *     받는 것     ~/my-publisher/staff.yml
 *                  lead:  { korean: 쭌, role: 편집장, color: "#f08a5d" }
 *                  staff: - { name: minjun, korean: 민준, role: 기획, agent: planner, team: book, color: "#5b8cff" } …
 *     내보내는 것  Names.register(쭌, [민준, 지훈, 서연, 태양, 테포])
 *     실제 로그   직원 명부 5명을 읽었어요: /root/my-publisher/staff.yml
 *
 * [3] 앞뒤 파일
 *     ~/my-publisher/staff.yml  →  (이 파일)  →  domain/Names.java
 *     시험: src/test/java/…/StaffRegistryTest.java (parse() 를 써서 CI 에서 명부를 검사)
 *
 * [4] 메서드 목록
 *     메서드          하는 일
 *     load()          시작할 때 한 번: 파일을 찾아 parse() 하고 Names 에 등록
 *     parse(파일)     YAML 을 읽어 쭌과 직원 목록을 만든다 (static: 테스트에서도 씀)
 *     str(Map, 키)    값을 글자로 꺼낸다 (없으면 null)
 *
 * [5] 먼저 알 용어 (자세한 설명: docs/용어-풀이.md)
 *     @Component, @PostConstruct, @Value, YAML, SnakeYAML(Yaml().load), 형 변환(캐스트)
 *
 * [6] 읽는 순서
 *     load() → parse() → str()
 *
 * [7] 다 읽고 확인
 *     - staff.yml 에 "name: 하늘" 처럼 한글 이름을 넣으면 어디에서 막히는가? (CI 의 StaffRegistryTest)
 *     - publisher.staff-file 설정을 주면 어떤 파일을 읽는가?
 */
package com.greendesk.publisher.config;

import com.greendesk.publisher.domain.Names;
import com.greendesk.publisher.domain.StaffMember;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;
import org.yaml.snakeyaml.Yaml;

import jakarta.annotation.PostConstruct;
import java.io.IOException;
import java.io.Reader;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;

/**
 * 직원 명부(staff.yml)를 읽어 Names 에 등록한다.
 * 찾는 곳: publisher.staff-file → 없으면 출판사 폴더/staff.yml → 없으면 기본 4명.
 */
@Component
public class StaffDirectory {

    private static final Logger log = LoggerFactory.getLogger(StaffDirectory.class);
    private final PublisherProperties props;
    private final String staffFile;

    public StaffDirectory(PublisherProperties props, @Value("${publisher.staff-file:}") String staffFile) {
        this.props = props;
        this.staffFile = staffFile;
    }

    // @PostConstruct : 스프링이 이 객체를 만들고 필요한 값을 다 넣은 직후에 이 메서드를 한 번 실행한다.
    //                  그래서 다른 클래스가 Names 를 쓰기 전에 명부가 등록된다.
    @PostConstruct
    public void load() {
        // 설정 publisher.staff-file 이 비어 있으면 출판사 폴더의 staff.yml.   예) /root/my-publisher/staff.yml
        Path f = staffFile == null || staffFile.isBlank() ? props.rootPath().resolve("staff.yml") : Path.of(staffFile);
        if (!Files.isRegularFile(f)) {
            log.info("직원 명부가 없어 기본 4명으로 시작해요: {}", f);
            return;
        }
        try {
            Parsed p = parse(f);
            // 읽은 명부로 Names 의 직원 정보를 바꾼다. 이후 화면의 이름·색·자리·점검 ① 기준이 명부를 따른다.
            Names.register(p.lead(), p.staff());
            log.info("직원 명부 {}명을 읽었어요: {}", p.staff().size(), f);
        } catch (IOException | RuntimeException e) {
            log.warn("직원 명부를 읽지 못해 기본 4명으로 시작해요 ({}): {}", f, e.getMessage());
        }
    }

    public record Parsed(StaffMember lead, List<StaffMember> staff) {
    }

    /** staff.yml 읽기 (CI 검사 테스트에서도 씀) */
    @SuppressWarnings("unchecked")
    public static Parsed parse(Path file) throws IOException {
        try (Reader r = Files.newBufferedReader(file, StandardCharsets.UTF_8)) {
            // SnakeYAML 라이브러리로 YAML 글자를 읽는다. 결과는 Map(이름 → 값)이다.
            //   예) root.get("lead") = {korean=쭌, role=편집장, color=#f08a5d}
            //       root.get("staff") = [ {name=minjun, …}, {name=jihun, …}, … ]
            Map<String, Object> root = new Yaml().load(r);
            // (Map<String, Object>) = 형 변환(캐스트). get 의 결과 자료형이 Object 라서, Map 으로 쓰겠다고 알려 준다.
            Map<String, Object> l = (Map<String, Object>) root.get("lead");
            StaffMember lead = l == null ? null : new StaffMember(Names.LEAD, str(l, "korean"), str(l, "role"), null, "lead", str(l, "color"));
            List<StaffMember> list = new ArrayList<>();
            for (Map<String, Object> s : (List<Map<String, Object>>) root.get("staff")) {
                list.add(new StaffMember(str(s, "name"), str(s, "korean"), str(s, "role"), str(s, "agent"), str(s, "team"), str(s, "color")));
            }
            return new Parsed(lead, list);
        }
    }

    private static String str(Map<String, Object> m, String k) {
        Object v = m.get(k);
        return v == null ? null : v.toString();
    }
}
