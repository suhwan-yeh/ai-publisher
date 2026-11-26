# DB 표 설명 (`db/migration/V1__init.sql`)

서버(라이트세일 MySQL)에서 처음 표 일곱 개를 만드는 SQL 파일의 설명입니다.

## 이 설명이 SQL 파일 안에 없는 이유

다른 파일과 달리 `V1__init.sql`에는 줄마다 주석을 넣지 않았습니다.

- Flyway는 실행한 SQL 파일의 **검사값(checksum)** 을 `flyway_schema_history` 표에 적어 둡니다. 이 값은 주석까지 포함한 파일 내용으로 만듭니다.
- 다음에 켤 때 파일 내용이 한 글자라도 다르면 `FlywayValidateException`으로 **시작이 멈춥니다**.
- 이미 서버에 배포했다면 V1이 실행된 상태입니다. 그래서 V1에 주석 한 줄만 더해도 다음 배포가 실패합니다. 실제로 시험 DB에서 이렇게 멈추는 것을 확인했습니다.
- 그래서 규칙은 이렇습니다. **이미 실행한 마이그레이션 파일은 고치지 않고, 바꿀 것은 `V2__설명.sql`로 새로 만듭니다.** 이 규칙은 파일 맨 위 주석에도 적혀 있습니다.

## 1. 역할

- 빈 MySQL DB(`publisher`)에 표 일곱 개를 만듭니다.
- 서버 모드(`--spring.profiles.active=prod`)로 처음 켤 때 Flyway가 한 번만 실행합니다.
- 내 PC(H2)에서는 이 파일을 쓰지 않습니다. JPA가 엔티티를 보고 표를 만듭니다(`ddl-auto: update`).

## 2. 받는 것 → 내보내는 것

- 받는 것: 빈 DB
- 내보내는 것: 표 `book`, `book_file`, `book_order`, `book_session`, `chat_message`, `team_member`, `team_message`, 그리고 Flyway 기록 표 `flyway_schema_history`
- 실행 뒤 확인하는 SQL(`MySqlMigrationTest`): `select count(*) from flyway_schema_history where success = 1` → 1 이상

## 3. 앞뒤 파일

```
application-prod.yml (spring.flyway.enabled: true, ddl-auto: validate)
   → V1__init.sql (Flyway 가 실행)
   → JPA 가 domain/*.java 엔티티와 표가 맞는지 확인 (validate)
```

## 4. 표 목록

| 표 | 엔티티 | 고유(unique) 조건 | 저장되는 것 |
|---|---|---|---|
| `book` | `Book` | `folder` | 책 폴더 하나 = 한 행 (제목, 장르, 단계, 장 수, 글자 수) |
| `book_file` | `BookFile` | — (`book_id` → `book.id`) | 완성 파일(PDF·EPUB·HTML·표지)과 크기 |
| `book_order` | `BookOrder` | `chat_key` | 첫 화면에서 넣은 주문 |
| `book_session` | `BookSession` | `folder` + `team_name` | 어느 팀(쭌의 세션)이 어느 책을 맡았는지 |
| `chat_message` | `ChatMessage` | `unique_key` | 사장님 ↔ 쭌 대화 |
| `team_member` | `TeamMember` | `team_name` + `name` | 팀원과 마지막 활동 시각 |
| `team_message` | `TeamMessage` | `unique_key` | 팀원끼리 주고받은 메시지 |

## 5. 먼저 알 용어

| SQL | 뜻 | 엔티티 쪽 |
|---|---|---|
| `bigint not null auto_increment` | 번호. DB가 1, 2, 3 …을 정합니다 | `@Id @GeneratedValue(strategy = IDENTITY)` |
| `varchar(255)` | 255자까지의 글 | `String` |
| `longtext` | 아주 긴 글 | `@Lob String` |
| `enum ('ORDERED', …)` | 정해진 글자만 들어갑니다 | `@Enumerated(EnumType.STRING)` |
| `datetime(6)` | 날짜·시각, 소수점 아래 6자리(마이크로초)까지 | `Instant` |
| `primary key (id)` | 행을 구별하는 열 | `@Id` |
| `constraint … unique (…)` | 같은 값이 두 행에 있을 수 없습니다 | `@Column(unique = true)`, `@Table(uniqueConstraints = …)` |
| `foreign key (book_id) references book (id)` | `book_id`는 반드시 있는 `book.id`여야 합니다 | `@ManyToOne` |
| `engine=InnoDB default charset=utf8mb4` | 트랜잭션을 지원하는 저장 방식 / 한글·이모지(📘)까지 저장 | — |

`unique_key`의 실제 값은 이런 모양입니다.

| 메시지 종류 | 예 |
|---|---|
| 관리 화면에서 보낸 말 | `web:web-1762724793776-a1b2c3` |
| 텔레그램 등 채널로 온 말 | `ch:t1:2026-11-09T11:32:56.190Z` |
| 쭌의 답 | `toolu_01…` (도구 호출 번호) |

같은 기록을 다시 읽어도 두 번 저장되지 않습니다. `TranscriptScanner`가 먼저 `existsByUniqueKey`로 확인하고, 그래도 겹치면 DB의 unique 조건이 막습니다.

## 6. 읽는 순서

`book` → `book_file` → `chat_message` → 나머지

## 7. 다 읽고 확인

- 엔티티에 필드를 하나 더하고 `V2__…sql`을 만들지 않으면 서버에서 무슨 일이 생길까요? (`ddl-auto: validate`가 열이 없다고 시작을 멈춥니다)
- 표의 charset이 `utf8mb4`가 아니면 `MySqlMigrationTest`의 어느 확인이 실패할까요? (이모지 📕가 들어간 글 비교)
