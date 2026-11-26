# 1인 AI 출판사 관리 화면 (Spring Boot + JPA)

1인 AI 출판사의 **주문 화면 + 기록 보관 + 점검 화면 + 실시간 사무실·회의실**입니다.

```
브라우저(사장님) ⇄ 이 관리 화면 :8080 ⇄ fakechat :8787 ⇄ 쭌 편집장(Claude Code) ⇄ 직원 4명(tmux 칸)
                     └ H2 DB: 주문·대화·책·직원 메시지
(선택) 휴대폰 텔레그램 ⇄ 쭌
```

- **주문·대화** (`/`, `/chat`): 사장님 말을 공식 채널 플러그인 `fakechat`(PC 안 127.0.0.1:8787)에 `POST /upload`로 보내면 쭌에게 전달됩니다.
  쭌의 답장(`reply` 도구)은 Claude 대화 기록에 남고, 이 화면이 읽어 대화방에 보여 줍니다. 첨부 파일(PDF·EPUB)은 내려받기 버튼이 됩니다.
- **기록 보관**: 주문(`BookOrder`), 대화(`ChatMessage`), 책(`Book`), 직원 메시지(`TeamMessage`)를 H2 파일 DB에 저장합니다.
- **점검**: 아래 네 가지를 책마다 보여 줍니다. 책 폴더·대화 기록은 읽기만 하고 고치지 않아요.

| 점검 | 무엇을 보나 |
|---|---|
| ① 팀원 생성 | 민준·지훈·서연·태양 4명이 자동으로 생겼는지 |
| ② 팀원끼리 메시지 | 쭌을 거치지 않고 직원끼리 직접 의논했는지 (SendMessage) |
| ③ 보고 | 직원 → 쭌 `[보고]`, 쭌 → 사장님 `[제안]`·`[최종 보고]` |
| ④ 파일 도착 | 동의한 뒤 PDF·EPUB이 사장님께 갔는지 |

## 실행하기 (셋 중 하나)

### A. 출근하면 자동 (권장)
`출근` 하면 tmux의 `dashboard` 창에서 자동으로 켜져요. 브라우저에서 **http://localhost:8080**.

### B. 명령 한 줄 (우분투 창)
```bash
java -jar ~/my-publisher/dashboard/publisher-dashboard.jar
```

### C. IntelliJ IDEA로 열기
1. IntelliJ → **File → Open** → 이 `publisher-dashboard` 폴더 선택 → **Open as Project** (Gradle 프로젝트로 자동 인식)
   - 가장 쉬운 방법: Windows 탐색기 주소창에 `\\wsl.localhost\Ubuntu\home\우분투이름\ai-publisher\publisher-dashboard` 를 열어 그 폴더를 고르세요.
     IntelliJ가 WSL 안의 프로젝트로 열어서 경로를 바꿀 필요가 없어요.
2. 오른쪽 위 실행 목록에서 **“관리화면 실행”** ▶ (JDK 21 필요: File → Project Structure → SDK → 21)
3. 브라우저에서 **http://localhost:8080**

실행 목록에는 **“테스트 전체”**(실제 시험 기록으로 4가지 점검 확인), **“실행 파일 만들기 (bootJar)”**도 들어 있어요.

#### Windows 쪽 IntelliJ에서 프로젝트를 다른 곳(C 드라이브 등)에 복사해 열었다면
`.run/관리화면 실행.run.xml` 안의 주석을 풀거나, 실행 설정 → Environment variables 에 아래를 넣으세요.
```
PUBLISHER_ROOT=\\wsl.localhost\Ubuntu\home\우분투이름\my-publisher
PUBLISHER_CLAUDE_PROJECTS=\\wsl.localhost\Ubuntu\home\우분투이름\.claude\projects
```

## 설정 (application.yml / 환경변수)
| 환경변수 | 기본값 | 뜻 |
|---|---|---|
| `PUBLISHER_ROOT` | `~/my-publisher` | 출판사 폴더 (`books/` 가 들어 있는 곳) |
| `PUBLISHER_CLAUDE_PROJECTS` | `~/.claude/projects` | Claude Code 대화 기록 폴더 |
| `PUBLISHER_TRANSCRIPTS_DIR` | (자동) | 대화 기록 폴더를 직접 지정 |
| `PUBLISHER_DB` | `~/.publisher-dashboard/db` | H2 데이터베이스 파일 |
| `PUBLISHER_BRIDGE` | `http://127.0.0.1:8787` | 쭌과 연결하는 fakechat 주소 |
| `PUBLISHER_STAFF_FILE` | 출판사 폴더/staff.yml | 직원 명부 |
| `PORT` | `8080` | 웹 포트 |
| (서버) `PUBLISHER_DB_URL/USER/PASSWORD`, `BOSS_USERNAME/PASSWORD` | — | `prod` 프로필에서 MySQL·로그인 |

## 코드 읽는 법 (처음 배우는 사람용)
모든 소스 파일(Java·템플릿·JS·CSS·설정·시험·테포 스크립트) 맨 위에 같은 순서의 설명 7가지가 있습니다.
`[1] 역할` → `[2] 받는 것 → 내보내는 것` → `[3] 앞뒤 파일` → `[4] 메서드 목록` → `[5] 먼저 알 용어` → `[6] 읽는 순서` → `[7] 다 읽고 확인`

1. [docs/요청-흐름-따라가기.md](docs/요청-흐름-따라가기.md)에서 흐름 A~F 그림을 봅니다.
2. IntelliJ에서 **Ctrl + Shift + F** → `흐름 A-` 를 검색해 ①②③… 순서로 파일을 엽니다.
3. 모르는 낱말은 [docs/용어-풀이.md](docs/용어-풀이.md)에서 찾습니다. DB 표는 [docs/DB-표-설명.md](docs/DB-표-설명.md)를 봅니다.

## 구조 (자세한 설명: [docs/구조-설명.md](docs/구조-설명.md))
```
controller/  화면용 @Controller → Thymeleaf      api/  @RestController → JSON(DTO)
service/     업무 규칙                            dto/  요청·응답 record
repository/  Spring Data JPA                      client/ FakechatClient · TmuxClient
domain/      JPA 엔티티                           scan/ 책 폴더·대화 기록 읽기
```
- 화면: `/` 책 목록 · `/office` 사무실 · `/meeting` 회의실 · `/chat` 대화 · `/books/{id}` · `/team`
- API: `/api/chat` · `/api/books` · `/api/office` · `/api/office/status` · `/api/office/screen/{name}` · `/api/meeting`
- 상태코드: 201(보냄) · 400(검사 실패) · 404(없음) · 503(쭌 출근 전), 오류 몸통은 `ErrorResponse{status, code, message, timestamp}`
- 화면의 비동기 요청은 fetch API만 사용 (`static/js/chatpanel.js`, `office.js`, `meeting.js`)
- 테스트 27개 (MySQL 시험 1개는 `TEST_MYSQL_URL` 이 있을 때만): 화면·API·상태코드, 관리 화면 → 쭌 연결(가짜 fakechat 서버), tmux 화면 해석, 서버 로그인·CSRF, 직원 명부(채용 PR) 검사, MySQL Flyway
- 서버 배포(라이트세일·GitHub Actions): [docs/배포-설명.md](docs/배포-설명.md)

## 빌드
```bash
./gradlew test      # 테스트
./gradlew bootJar   # build/libs/publisher-dashboard.jar
```
