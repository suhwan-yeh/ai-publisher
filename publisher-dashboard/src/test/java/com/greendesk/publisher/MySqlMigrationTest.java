/*
 * [1] 역할
 *     서버와 같은 MySQL 8 에서 Flyway(V1__init.sql)가 표를 만들고, JPA 가 엔티티와 표가 맞는지 확인(validate)하고, 한글·이모지가 그대로 저장되는지 본다.
 *     환경변수 TEST_MYSQL_URL 이 있을 때만 실행된다. GitHub Actions CI 는 MySQL 을 띄워 실행하고, 내 PC 에서는 보통 건너뛴다.
 *
 * [2] 받는 것 → 내보내는 것 (실제로 실행해서 얻은 값)
 *     실행 예) TEST_MYSQL_URL=jdbc:mysql://127.0.0.1:3306/publisher_ci TEST_MYSQL_USER=publisher TEST_MYSQL_PASSWORD=… ./gradlew test
 *     확인하는 것
 *       select count(*) from flyway_schema_history where success = 1   → 1 이상
 *       책 20261109-sea-kitten 의 제목 "바다를 건너는 아기 고양이"
 *       "📕 한글과 이모지 저장 확인 …" 을 저장했다 읽으면 같은 글
 *
 * [3] 앞뒤 파일
 *     (이 파일)  →  db/migration/V1__init.sql (Flyway)  →  domain/*.java (validate)  →  service/ScanService.java
 *
 * [4] 메서드 목록
 *     메서드              확인하는 것
 *     mysql()             DB 주소·계정을 환경변수에서
 *     migrateAndStore     Flyway 적용 → 기록 읽어 저장 → 한글·이모지
 *
 * [5] 먼저 알 용어 (자세한 설명: docs/용어-풀이.md)
 *     @EnabledIfEnvironmentVariable, Flyway, ddl-auto: validate, JdbcTemplate, utf8mb4
 *
 * [6] 읽는 순서
 *     클래스 위 두 어노테이션 → mysql() → migrateAndStore()
 *
 * [7] 다 읽고 확인
 *     - 엔티티에 필드를 더하고 V2 SQL 을 만들지 않으면 이 시험은 어디서 실패하는가? (스프링 시작 때 validate)
 *     - 표의 charset 이 utf8mb4 가 아니면 어떤 줄이 실패할까? (이모지 📕 비교)
 */
package com.greendesk.publisher;

import com.greendesk.publisher.domain.ChatMessage;
import com.greendesk.publisher.repository.BookRepository;
import com.greendesk.publisher.repository.ChatMessageRepository;
import com.greendesk.publisher.service.ScanService;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.condition.EnabledIfEnvironmentVariable;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;

import java.time.Instant;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * 서버(라이트세일)와 같은 MySQL 8 에서:
 *  - Flyway 가 db/migration 의 SQL 로 표를 만들고
 *  - JPA 가 엔티티와 표가 맞는지 확인(validate)하고
 *  - 한글·이모지가 깨지지 않는지 본다.
 * TEST_MYSQL_URL 이 있을 때만 실행 (GitHub Actions CI 는 MySQL 서비스를 띄워 실행, 내 PC 에서는 보통 건너뜀).
 */
// 환경변수 TEST_MYSQL_URL 에 글자가 하나라도 있을 때만 이 클래스를 실행한다. 없으면 "건너뜀".
@EnabledIfEnvironmentVariable(named = "TEST_MYSQL_URL", matches = ".+")
@SpringBootTest(properties = {
        // 서버(prod)와 같게: JPA 는 표를 만들지 않고 확인만, 표는 Flyway 가 만든다.
        "spring.jpa.hibernate.ddl-auto=validate",
        "spring.flyway.enabled=true",
        "spring.flyway.clean-disabled=false",
        "publisher.scan-interval-ms=3600000"
})
class MySqlMigrationTest {

    @DynamicPropertySource
    static void mysql(DynamicPropertyRegistry r) {
        r.add("spring.datasource.url", () -> System.getenv("TEST_MYSQL_URL"));
        r.add("spring.datasource.username", () -> System.getenv("TEST_MYSQL_USER"));
        r.add("spring.datasource.password", () -> System.getenv("TEST_MYSQL_PASSWORD"));
        r.add("publisher.root", () -> FixturePaths.publisher().toString());
        r.add("publisher.transcripts-dir", () -> FixturePaths.transcripts().toString());
    }

    // JdbcTemplate: SQL 글자를 직접 실행하는 스프링 도구.
    @Autowired JdbcTemplate jdbc;
    @Autowired ScanService scans;
    @Autowired BookRepository books;
    @Autowired ChatMessageRepository chats;

    @Test
    @DisplayName("Flyway V1 적용 → 엔티티 검증 통과 → 실제 기록을 읽어 저장 → 한글·이모지 그대로")
    void migrateAndStore() {
        Integer applied = jdbc.queryForObject("select count(*) from flyway_schema_history where success = 1", Integer.class);
        assertThat(applied).isGreaterThanOrEqualTo(1);

        scans.scanNow();
        assertThat(books.findByFolder("20261109-sea-kitten")).get()
                .satisfies(b -> assertThat(b.getTitle()).isEqualTo("바다를 건너는 아기 고양이"));

        String text = "📕 한글과 이모지 저장 확인 " + Instant.now();
        ChatMessage saved = chats.save(new ChatMessage("mysql-test-" + System.nanoTime(), null, ChatMessage.Direction.FROM_BOSS, text, null, Instant.now()));
        assertThat(chats.findById(saved.getId())).get().extracting(ChatMessage::getText).isEqualTo(text);
    }
}
