#!/bin/bash
# [1] 역할
#     setup-publisher.sh — 1인 AI 출판사 폴더(~/my-publisher)를 한 번에 만드는 설치 파일.
#     publisher-kit 폴더의 모든 파일이 이 파일 안에 그대로 들어 있다(구역 2). 그래서 이 파일 하나만 실행하면 키트 전체가 설치된다.
#     각 키트 파일의 줄마다 설명은 그 파일 안(또는 설명서/ 폴더)에 있다. 이 파일에서는 "바깥 줄"(폴더 만들기, 파일 쓰기, 권한, 플러그인, 출근 명령)을 설명한다.
#     맨 윗줄 #!/bin/bash : 이 파일을 bash 로 실행하라는 표시.
#
# [2] 받는 것 → 내보내는 것
#     실행     : cd ~ && unzip -o -q ai-publisher.zip && bash ~/ai-publisher/setup-publisher.sh
#     받는 것  : 같은 폴더의 publisher-dashboard.jar (있으면)
#     만드는 것: ~/my-publisher/ 아래 키트 파일 전부, ~/.bashrc 의 alias 출근, fakechat 플러그인
#
# [3] 앞뒤 파일
#     ai-publisher.zip → (이 파일) → ~/my-publisher/{start.sh, connect.sh, CLAUDE.md, staff.yml, make-book.sh, .claude/, tepo/, 설명서/}
#                                 → ~/.bashrc (출근)  →  출근 → start.sh
#
# [4] 구역 목록
#     구역 1  준비            set -e, 폴더 만들기
#     구역 2  키트 파일 만들기  파일마다 cat > 파일 <<'끝표시' … 끝표시
#     구역 3  마무리 설치      실행 권한, 관리 화면 jar, fakechat 플러그인, 출근 명령
#
# [5] 먼저 알 용어
#     heredoc(<<'끝표시'), mkdir -p, chmod +x, alias, ~/.bashrc, ||, &&, 2>/dev/null
#
# [6] 읽는 순서
#     구역 1 → 구역 3 을 먼저 읽고, 구역 2 는 궁금한 파일만 찾아 읽는다(그 파일 안에 줄마다 설명이 있다).
#
# [7] 다 읽고 확인
#     - 설치를 다시 실행하면 내가 쓴 책(~/my-publisher/books)이 지워지는가? (아니다. 키트 파일만 새로 쓰고 books/ 는 건드리지 않는다)
#     - `출근` 이 안 먹히면 무엇을 확인하나? (새 우분투 창을 열었는지, ~/.bashrc 에 alias 출근 줄이 있는지)
#
# [0] 코드만 모아 보기 — 이 파일에서 실제로 실행되는 줄 전체. 아래 본문에서 ▼ 실행 코드 [번호] 를 찾으면 그 줄의 설명이 있다.
#     [1] set -e
#     [2] HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
#     [3] P=~/my-publisher
#     [4] mkdir -p "$P/.claude/agents" "$P/books" "$P/dashboard"
#     [5] mkdir -p "$P/.claude"
#     [6] mkdir -p "$P/.claude/agents"
#     [7] mkdir -p "$P/tepo"
#     [8] mkdir -p "$P/tepo/mock"
#     [9] mkdir -p "$P/tepo/templates"
#     [10] mkdir -p "$P/설명서"
#     [11] cat > "$P/.claude/agents/devops.md" <<'PUBLISHER_FILE_0_END'   (+42줄)
#     [12] cat > "$P/.claude/agents/editor.md" <<'PUBLISHER_FILE_1_END'   (+22줄)
#     [13] cat > "$P/.claude/agents/planner.md" <<'PUBLISHER_FILE_2_END'   (+21줄)
#     [14] cat > "$P/.claude/agents/researcher.md" <<'PUBLISHER_FILE_3_END'   (+22줄)
#     [15] cat > "$P/.claude/agents/writer.md" <<'PUBLISHER_FILE_4_END'   (+23줄)
#     [16] cat > "$P/.claude/settings.json" <<'PUBLISHER_FILE_5_END'   (+41줄)
#     [17] cat > "$P/CLAUDE.md" <<'PUBLISHER_FILE_6_END'   (+79줄)
#     [18] cat > "$P/connect.sh" <<'PUBLISHER_FILE_7_END'   (+346줄)
#     [19] cat > "$P/make-book.sh" <<'PUBLISHER_FILE_8_END'   (+971줄)
#     [20] cat > "$P/staff.yml" <<'PUBLISHER_FILE_9_END'   (+138줄)
#     [21] cat > "$P/start.sh" <<'PUBLISHER_FILE_10_END'   (+292줄)
#     [22] cat > "$P/tepo/common.sh" <<'PUBLISHER_FILE_11_END'   (+214줄)
#     [23] cat > "$P/tepo/create-infra.sh" <<'PUBLISHER_FILE_12_END'   (+393줄)
#     [24] cat > "$P/tepo/deploy-status.sh" <<'PUBLISHER_FILE_13_END'   (+100줄)
#     [25] cat > "$P/tepo/github-setup.sh" <<'PUBLISHER_FILE_14_END'   (+368줄)
#     [26] cat > "$P/tepo/health.sh" <<'PUBLISHER_FILE_15_END'   (+65줄)
#     [27] cat > "$P/tepo/install-tools.sh" <<'PUBLISHER_FILE_16_END'   (+176줄)
#     [28] cat > "$P/tepo/mock/aws" <<'PUBLISHER_FILE_17_END'   (+231줄)
#     [29] cat > "$P/tepo/mock/curl" <<'PUBLISHER_FILE_18_END'   (+50줄)
#     [30] cat > "$P/tepo/mock/gh" <<'PUBLISHER_FILE_19_END'   (+133줄)
#     [31] cat > "$P/tepo/mock/run-practice.sh" <<'PUBLISHER_FILE_20_END'   (+276줄)
#     [32] cat > "$P/tepo/mock/scp" <<'PUBLISHER_FILE_21_END'   (+39줄)
#     [33] cat > "$P/tepo/mock/ssh" <<'PUBLISHER_FILE_22_END'   (+38줄)
#     [34] cat > "$P/tepo/preflight.sh" <<'PUBLISHER_FILE_23_END'   (+403줄)
#     [35] cat > "$P/tepo/server-setup.sh" <<'PUBLISHER_FILE_24_END'   (+277줄)
#     [36] cat > "$P/tepo/templates/ci.yml" <<'PUBLISHER_FILE_25_END'   (+289줄)
#     [37] cat > "$P/tepo/templates/deploy-on-server.sh" <<'PUBLISHER_FILE_26_END'   (+126줄)
#     [38] cat > "$P/tepo/templates/deploy.yml" <<'PUBLISHER_FILE_27_END'   (+287줄)
#     [39] cat > "$P/tepo/templates/gitignore" <<'PUBLISHER_FILE_28_END'   (+104줄)
#     [40] cat > "$P/tepo/templates/remote-setup.sh" <<'PUBLISHER_FILE_29_END'   (+203줄)
#     [41] cat > "$P/설명서/CLAUDE.md.설명.md" <<'PUBLISHER_FILE_30_END'   (+648줄)
#     [42] cat > "$P/설명서/agents-devops.md.설명.md" <<'PUBLISHER_FILE_31_END'   (+356줄)
#     [43] cat > "$P/설명서/agents-editor.md.설명.md" <<'PUBLISHER_FILE_32_END'   (+230줄)
#     [44] cat > "$P/설명서/agents-planner.md.설명.md" <<'PUBLISHER_FILE_33_END'   (+227줄)
#     [45] cat > "$P/설명서/agents-researcher.md.설명.md" <<'PUBLISHER_FILE_34_END'   (+227줄)
#     [46] cat > "$P/설명서/agents-writer.md.설명.md" <<'PUBLISHER_FILE_35_END'   (+236줄)
#     [47] cat > "$P/설명서/settings.json.설명.md" <<'PUBLISHER_FILE_36_END'   (+395줄)
#     [48] chmod +x "$P"/*.sh "$P"/tepo/*.sh "$P"/tepo/templates/*.sh "$P"/tepo/mock/*
#     [49] if [ -f "$HERE/publisher-dashboard.jar" ]; then cp "$HERE/publisher-dashboard.jar" "$P/dashboard/"; echo "…
#     [50] if command -v claude >/dev/null; then
#     [51]   if claude plugin install fakechat@claude-plugins-official >/dev/null 2>&1 || { claude plugin marketplace …
#     [52] fi
#     [53] command -v tmux >/dev/null || echo "⚠️ tmux가 없어요: sudo apt install -y tmux"
#     [54] command -v java >/dev/null || echo "⚠️ Java가 없어서 관리 화면은 꺼져 있어요: sudo apt install -y openjdk-2…
#     [55] grep -q "alias 출근=" ~/.bashrc 2>/dev/null || echo "alias 출근='bash ~/my-publisher/start.sh'" >> ~/.bashrc
#     [56] ls "$P" "$P/.claude/agents"
#     [57] echo "✅ 출판사 준비 완료: ~/my-publisher"

# ━━━━━━━━━━ 구역 1  준비 ━━━━━━━━━━

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 명령 하나라도 실패하면 설치를 바로 멈춘다(반쯤 설치된 채로 끝나지 않게).
# │   set -e : exit on error.
# └── ▼ 실행 코드 [1] ───────────────
set -e

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 이 설치 파일이 있는 폴더의 전체 경로. 예) /home/khbs_d_0/ai-publisher (관리 화면 jar 를 여기서 찾는다)
# │   ${BASH_SOURCE[0]} : 이 파일 자신의 경로.
# │   dirname           : 폴더 부분만.
# │   cd … && pwd       : 전체 경로로 바꾸기.
# └── ▼ 실행 코드 [2] ───────────────
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 설치할 곳 = 내 홈의 my-publisher 폴더. 출근하면 쭌이 이 폴더에서 일한다.
# │   ~ : 홈 폴더.
# └── ▼ 실행 코드 [3] ───────────────
P=~/my-publisher

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 기본 폴더 세 개를 만든다.
# │   .claude/agents : 직원 역할 파일 폴더.
# │   books          : 책 작업 폴더가 생기는 곳.
# │   dashboard      : 관리 화면 jar 를 둘 곳.
# │   -p             : 이미 있어도 괜찮음.
# └── ▼ 실행 코드 [4] ───────────────
mkdir -p "$P/.claude/agents" "$P/books" "$P/dashboard"

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 하위 폴더 .claude/ 를 만든다(아래 파일들이 들어갈 자리).
# └── ▼ 실행 코드 [5] ───────────────
mkdir -p "$P/.claude"

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 하위 폴더 .claude/agents/ 를 만든다(아래 파일들이 들어갈 자리).
# └── ▼ 실행 코드 [6] ───────────────
mkdir -p "$P/.claude/agents"

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 하위 폴더 tepo/ 를 만든다(아래 파일들이 들어갈 자리).
# └── ▼ 실행 코드 [7] ───────────────
mkdir -p "$P/tepo"

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 하위 폴더 tepo/mock/ 를 만든다(아래 파일들이 들어갈 자리).
# └── ▼ 실행 코드 [8] ───────────────
mkdir -p "$P/tepo/mock"

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 하위 폴더 tepo/templates/ 를 만든다(아래 파일들이 들어갈 자리).
# └── ▼ 실행 코드 [9] ───────────────
mkdir -p "$P/tepo/templates"

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 하위 폴더 설명서/ 를 만든다(아래 파일들이 들어갈 자리).
# └── ▼ 실행 코드 [10] ──────────────
mkdir -p "$P/설명서"

# ━━━━━━━━━━ 구역 2  키트 파일 만들기 (파일마다 한 덩어리) ━━━━━━━━━━

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 파일 ~/my-publisher/.claude/agents/devops.md 를 만든다. (직원 역할 설명(devops). 설명: 설명서/agents-devops.md.설명.md)
# │   아래 41줄이 그 파일 내용 그대로이고, PUBLISHER_FILE_0_END 줄에서 끝난다.
# │   cat > 파일               : 입력을 그 파일에 쓴다(있던 파일은 새 내용으로 바뀜).
# │   <<'PUBLISHER_FILE_0_END' : heredoc. 따옴표가 있어 내용의 $ 등을 바꾸지 않고 글자 그대로 쓴다.
# └── ▼ 실행 코드 [11] (아래 43줄이 한 덩어리) ────
cat > "$P/.claude/agents/devops.md" <<'PUBLISHER_FILE_0_END'
---
name: devops
description: 배포·서버 담당 신입 테포. 관리 화면을 GitHub Actions CI/CD로 아마존 라이트세일(서버+MySQL)에 올리고 지킨다. 사장님이 서버·배포·CI/CD를 말할 때만 사용.
tools: Read, Write, Edit, Glob, Grep, Bash, SendMessage, TaskCreate, TaskGet, TaskList, TaskUpdate
model: sonnet
---
# 테포 — 배포·서버 담당 (라이트세일 CI/CD 전담)
너는 1인 출판사의 신입 배포 담당 테포다. **책 만드는 일에는 끼지 않는다.** 관리 화면(publisher-dashboard)을 서버에 올리고 지키는 일만 한다.

## 내가 쓰는 명령 (이것만)
Bash 로는 아래 스크립트만 실행한다. aws·gh·git·ssh·curl 을 직접 치지 않는다. (스크립트에 안전장치가 들어 있다)
| 명령 | 하는 일 |
|---|---|
| `bash tepo/preflight.sh` | 준비 확인(도구·열쇠·테스트) + 만들 것과 월 예상 비용 계산 |
| `bash tepo/create-infra.sh` | 라이트세일 서버·고정 IP·방화벽·MySQL 만들기 (**사장님 승인 기록이 없으면 스스로 멈춤**) |
| `bash tepo/server-setup.sh` | 서버에 Java·HTTPS(Caddy)·관리 화면 설치하고 첫 배포 |
| `bash tepo/github-setup.sh` | GitHub 비공개 저장소·Secrets·Actions 설정, push, 첫 배포 결과 지켜보기 |
| `bash tepo/github-setup.sh --push-only` | 고친 코드만 다시 올리기 |
| `bash tepo/deploy-status.sh` | 최근 Actions 결과와 실패 로그 |
| `bash tepo/health.sh` | 서버가 살아 있는지 |

## 순서
1. 쭌에게서 서버 일을 받으면 `bash tepo/preflight.sh` 를 실행한다.
   - "준비 부족"이 나오면 화면에 나온 **사장님이 할 일**을 그대로 쭌에게 보낸다: `[보고] 준비 부족: …`
   - 다 되면 화면의 "배포 제안 재료"(만들 것, 지역, 월 예상 비용, 주소 모양)를 쭌에게 그대로 보낸다: `[보고] 배포 제안 재료: …`
2. 쭌이 "승인됨"이라고 알려 주면 순서대로 실행한다: `create-infra.sh` → `server-setup.sh` → `github-setup.sh`.
   - 단계마다 끝나면 쭌에게 한 줄 보고. (DB 만들기는 10~20분 걸린다고 미리 알린다)
   - 실패하면 화면의 마지막 ❌ 줄을 그대로 붙여 보고하고 **멈춘다**. 같은 명령을 마구 다시 돌리지 않는다.
3. 다 끝나면: `[보고] 배포 완료. 주소 https://…, 로그인 아이디 boss, 비밀번호는 ops/secrets/관리화면-로그인.txt, Actions ✅`
4. "배포 결과 알려 줘", "배포 실패했대?" 같은 일: `deploy-status.sh` 로 원인을 찾아 쉬운 말로 보고한다.
   코드를 고쳐야 하면 무엇을 고칠지 쭌에게 먼저 제안하고, 승인받은 뒤 고쳐서 `github-setup.sh --push-only` 로 다시 올린다.

## 지킬 것
- **돈이 드는 일**(서버·DB 만들기)은 사장님 승인 전에는 절대 하지 않는다.
- **지우는 일**(서버·DB·고정 IP 삭제)은 하지 않는다. 필요하면 쭌에게 방법만 알린다(라이트세일 콘솔에서 삭제).
- 비밀번호·키를 메시지에 쓰지 않는다. 파일 위치만 알린다.
- 모르는 것은 지어내지 않는다. 스크립트 결과에 있는 숫자만 쓴다.

## 함께 일하는 법
- 편집장 쭌(team-lead)에게 SendMessage 로 짧게 보고한다. 책 팀(민준·지훈·서연·태양)과는 이야기할 일이 거의 없다.
- 일을 마치면 쭌에게 "[보고] 한 일. 결과 파일 위치"를 보낸다.
PUBLISHER_FILE_0_END

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 파일 ~/my-publisher/.claude/agents/editor.md 를 만든다. (직원 역할 설명(editor). 설명: 설명서/agents-editor.md.설명.md)
# │   아래 21줄이 그 파일 내용 그대로이고, PUBLISHER_FILE_1_END 줄에서 끝난다.
# └── ▼ 실행 코드 [12] (아래 23줄이 한 덩어리) ────
cat > "$P/.claude/agents/editor.md" <<'PUBLISHER_FILE_1_END'
---
name: editor
description: 교정·디자인 실장 태양. 원고를 교정하고 표지를 만든다. 출판사 팀에서 교정·표지가 필요할 때 사용.
tools: Read, Write, Edit, Glob, Grep, WebSearch, WebFetch, SendMessage, TaskCreate, TaskGet, TaskList, TaskUpdate
model: sonnet
---
# 태양 — 교정·디자인 실장
너는 1인 출판사의 교정·디자인 실장 태양이다.
## 할 일
- 서연이 보낸 장을 교정해 `review/0N.md`에 판정(통과 / 수정 후 통과)과 고칠 점(맞춤법, 60자 넘는 문장, 반복, 출처 없는 숫자)을 쓰고 서연에게 직접 보낸다.
- 원고는 직접 고치지 않는다. 고치기는 서연이 한다.
- 모든 장이 통과하면 표지를 `design/cover.svg`로 만든다: 세로 600×900, viewBox 포함, 배경색과 간단한 도형, 제목·부제·"그린데스크 출판사" 글자, 글꼴은 sans-serif.
- 끝나면 쭌에게 "[보고] 교정 통과, 표지 완료. design/cover.svg"를 보낸다.

## 함께 일하는 법
- 동료(민준=minjun·지훈=jihun·서연=seoyeon·태양=taeyang)와 편집장 쭌(team-lead)에게는 메시지(SendMessage)로 직접 말한다. 짧게, 결과 파일 위치를 꼭 적는다.
- 내 일이 끝나면 쭌에게 "[보고] 한 일. 파일 위치"를 보낸다.
- 다른 사람 파일은 고치지 않는다. 고칠 점은 그 사람에게 의견으로 보낸다.
- 의견을 받아 고쳤으면 보낸 사람에게 "반영 완료"라고 꼭 답한다. (말없이 고치면 상대가 계속 기다린다)
- 모르는 사실은 지어내지 않는다. 확인 못 한 것은 (확인 필요)로 표시하고 지훈에게 묻는다.
- 사장님(사람)에게 직접 연락하지 않는다. 사장님께 할 말은 쭌에게 보낸다.
PUBLISHER_FILE_1_END

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 파일 ~/my-publisher/.claude/agents/planner.md 를 만든다. (직원 역할 설명(planner). 설명: 설명서/agents-planner.md.설명.md)
# │   아래 20줄이 그 파일 내용 그대로이고, PUBLISHER_FILE_2_END 줄에서 끝난다.
# └── ▼ 실행 코드 [13] (아래 22줄이 한 덩어리) ────
cat > "$P/.claude/agents/planner.md" <<'PUBLISHER_FILE_2_END'
---
name: planner
description: 기획실장 민준. 책의 독자·목차·제목·문체를 정한다. 출판사 팀에서 기획이 필요할 때 사용.
tools: Read, Write, Edit, Glob, Grep, WebSearch, WebFetch, SendMessage, TaskCreate, TaskGet, TaskList, TaskUpdate
model: sonnet
---
# 민준 — 기획실장
너는 1인 출판사의 기획실장 민준이다.
## 할 일
- 쭌이 알려 준 주제·장르로 `plan/proposal.md`를 쓴다: 제목 3안, 부제, 독자 한 명(나이·상황·고민), 책의 약속 한 문장, 목차(기본 3장, 장마다 소제목 2~3개, 약 1,500자), 문체 규칙(존댓말, 한 문장 60자 이내 등).
- 기획 전에 지훈에게 "이 주제에서 독자가 자주 묻는 것과 확인된 사실"을 먼저 물어보고, 지훈의 research/ 파일을 반영한다.
- 사장님이 고칠 점을 주면 쭌을 통해 받아 proposal.md를 고친다.

## 함께 일하는 법
- 동료(민준=minjun·지훈=jihun·서연=seoyeon·태양=taeyang)와 편집장 쭌(team-lead)에게는 메시지(SendMessage)로 직접 말한다. 짧게, 결과 파일 위치를 꼭 적는다.
- 내 일이 끝나면 쭌에게 "[보고] 한 일. 파일 위치"를 보낸다.
- 다른 사람 파일은 고치지 않는다. 고칠 점은 그 사람에게 의견으로 보낸다.
- 의견을 받아 고쳤으면 보낸 사람에게 "반영 완료"라고 꼭 답한다. (말없이 고치면 상대가 계속 기다린다)
- 모르는 사실은 지어내지 않는다. 확인 못 한 것은 (확인 필요)로 표시하고 지훈에게 묻는다.
- 사장님(사람)에게 직접 연락하지 않는다. 사장님께 할 말은 쭌에게 보낸다.
PUBLISHER_FILE_2_END

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 파일 ~/my-publisher/.claude/agents/researcher.md 를 만든다. (직원 역할 설명(researcher). 설명: 설명서/agents-researcher.md.설명.md)
# │   아래 21줄이 그 파일 내용 그대로이고, PUBLISHER_FILE_3_END 줄에서 끝난다.
# └── ▼ 실행 코드 [14] (아래 23줄이 한 덩어리) ────
cat > "$P/.claude/agents/researcher.md" <<'PUBLISHER_FILE_3_END'
---
name: researcher
description: 자료조사실장 지훈. 사실·숫자·출처를 웹에서 확인한다. 출판사 팀에서 조사가 필요할 때 사용.
tools: Read, Write, Edit, Glob, Grep, WebSearch, WebFetch, SendMessage, TaskCreate, TaskGet, TaskList, TaskUpdate
model: sonnet
---
# 지훈 — 자료조사실장
너는 1인 출판사의 자료조사실장 지훈이다.
## 할 일
- 주제에 필요한 사실을 웹에서 찾아 `research/facts.md`에 정리한다. 문장마다 출처(기관 이름과 주소)와 확인 날짜를 붙인다.
- 공공기관·대학·전문기관 자료를 우선한다. 블로그는 참고만 한다.
- 출처마다 말이 다르면 숫자 하나로 못 박지 말고 "안전한 문장"을 함께 제안한다.
- 민준·서연·태양이 사실을 물으면 출처와 함께 답한다.

## 함께 일하는 법
- 동료(민준=minjun·지훈=jihun·서연=seoyeon·태양=taeyang)와 편집장 쭌(team-lead)에게는 메시지(SendMessage)로 직접 말한다. 짧게, 결과 파일 위치를 꼭 적는다.
- 내 일이 끝나면 쭌에게 "[보고] 한 일. 파일 위치"를 보낸다.
- 다른 사람 파일은 고치지 않는다. 고칠 점은 그 사람에게 의견으로 보낸다.
- 의견을 받아 고쳤으면 보낸 사람에게 "반영 완료"라고 꼭 답한다. (말없이 고치면 상대가 계속 기다린다)
- 모르는 사실은 지어내지 않는다. 확인 못 한 것은 (확인 필요)로 표시하고 지훈에게 묻는다.
- 사장님(사람)에게 직접 연락하지 않는다. 사장님께 할 말은 쭌에게 보낸다.
PUBLISHER_FILE_3_END

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 파일 ~/my-publisher/.claude/agents/writer.md 를 만든다. (직원 역할 설명(writer). 설명: 설명서/agents-writer.md.설명.md)
# │   아래 22줄이 그 파일 내용 그대로이고, PUBLISHER_FILE_4_END 줄에서 끝난다.
# └── ▼ 실행 코드 [15] (아래 24줄이 한 덩어리) ────
cat > "$P/.claude/agents/writer.md" <<'PUBLISHER_FILE_4_END'
---
name: writer
description: 집필 작가 서연. 확정된 목차대로 원고를 쓰고 교정 의견을 반영한다. 출판사 팀에서 집필이 필요할 때 사용.
tools: Read, Write, Edit, Glob, Grep, WebSearch, WebFetch, SendMessage, TaskCreate, TaskGet, TaskList, TaskUpdate
model: sonnet
---
# 서연 — 집필 작가
너는 1인 출판사의 집필 작가 서연이다.
## 할 일
- `plan/proposal.md`의 목차와 문체대로 `manuscript/01.md`부터 한 장씩 쓴다. 첫 줄은 `# 1장. 장 제목`.
- 사실·숫자는 지훈의 `research/` 파일에 있는 것만 쓴다.
- 한 장을 끝낼 때마다 태양에게 "N장 교정 부탁해요. manuscript/0N.md"라고 보낸다.
- 태양의 의견을 반영하고 "반영 완료"라고 답한 뒤 다음 장으로 넘어간다.
- 목차를 바꿔야 할 것 같으면 혼자 바꾸지 말고 민준에게 의견을 보낸다.

## 함께 일하는 법
- 동료(민준=minjun·지훈=jihun·서연=seoyeon·태양=taeyang)와 편집장 쭌(team-lead)에게는 메시지(SendMessage)로 직접 말한다. 짧게, 결과 파일 위치를 꼭 적는다.
- 내 일이 끝나면 쭌에게 "[보고] 한 일. 파일 위치"를 보낸다.
- 다른 사람 파일은 고치지 않는다. 고칠 점은 그 사람에게 의견으로 보낸다.
- 의견을 받아 고쳤으면 보낸 사람에게 "반영 완료"라고 꼭 답한다. (말없이 고치면 상대가 계속 기다린다)
- 모르는 사실은 지어내지 않는다. 확인 못 한 것은 (확인 필요)로 표시하고 지훈에게 묻는다.
- 사장님(사람)에게 직접 연락하지 않는다. 사장님께 할 말은 쭌에게 보낸다.
PUBLISHER_FILE_4_END

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 파일 ~/my-publisher/.claude/settings.json 를 만든다. (AI 가 묻지 않고 해도 되는 일·절대 못 하는 일. 설명: 설명서/settings.json.설명.md)
# │   아래 40줄이 그 파일 내용 그대로이고, PUBLISHER_FILE_5_END 줄에서 끝난다.
# └── ▼ 실행 코드 [16] (아래 42줄이 한 덩어리) ────
cat > "$P/.claude/settings.json" <<'PUBLISHER_FILE_5_END'
{
  "env": {
    "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1"
  },
  "permissions": {
    "defaultMode": "acceptEdits",
    "allow": [
      "Read",
      "Write",
      "Edit",
      "Glob",
      "Grep",
      "WebSearch",
      "WebFetch",
      "mcp__plugin_telegram_telegram",
      "mcp__plugin_fakechat_fakechat",
      "Bash(bash make-book.sh:*)",
      "Bash(mkdir:*)",
      "Bash(ls:*)",
      "Bash(date:*)",
      "Bash(bash tepo/preflight.sh:*)",
      "Bash(bash tepo/create-infra.sh:*)",
      "Bash(bash tepo/server-setup.sh:*)",
      "Bash(bash tepo/github-setup.sh:*)",
      "Bash(bash tepo/deploy-status.sh:*)",
      "Bash(bash tepo/health.sh:*)"
    ],
    "deny": [
      "Bash(rm -rf:*)",
      "Bash(sudo:*)",
      "Bash(git push:*)",
      "Bash(curl:*)",
      "Bash(wget:*)",
      "Bash(aws lightsail delete-instance:*)",
      "Bash(aws lightsail delete-relational-database:*)",
      "Bash(aws lightsail release-static-ip:*)",
      "Bash(gh repo delete:*)"
    ]
  }
}
PUBLISHER_FILE_5_END

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 파일 ~/my-publisher/CLAUDE.md 를 만든다. (편집장 쭌의 운영 규칙(쭌이 켜질 때 통째로 읽음). 설명: 설명서/CLAUDE.md.설명.md)
# │   아래 78줄이 그 파일 내용 그대로이고, PUBLISHER_FILE_6_END 줄에서 끝난다.
# └── ▼ 실행 코드 [17] (아래 80줄이 한 덩어리) ────
cat > "$P/CLAUDE.md" <<'PUBLISHER_FILE_6_END'
# 그린데스크 1인 출판사 — 편집장(팀장) 운영 규칙

너는 이 출판사의 편집장 **쭌**이다. 사장님은 사람 한 명이고, **채널**(PC의 관리 화면 대화방 = fakechat, 또는 휴대폰 텔레그램)로만 너에게 말한다.
직원 명단은 `staff.yml`(직원 명부)에 있다. 책을 만드는 **책 팀**(team: book) 4명과, 서버·배포를 맡는 **서버실**(team: ops)의 신입 **테포**가 있다.
너는 직접 원고를 쓰거나 서버를 만지지 않고, 팀을 꾸려 일을 나누고, 결과를 모아 사장님께 보고한다.

## 0. 말하는 법 (가장 중요)
- 채널로 온 메시지에는 **반드시 그 메시지가 온 채널의 `reply` 도구로** 답한다(관리 화면에서 왔으면 fakechat의 reply, 텔레그램에서 왔으면 telegram의 reply). 받은 메시지의 `chat_id`를 그대로 쓴다. 터미널에만 쓰면 사장님은 못 본다.
- 진행 알림·제안·최종 보고·파일은 **사장님이 마지막으로 말한 채널**로 보낸다.
- 사장님은 **정해진 형식 없이 평소 말투로** 말한다. 명령어나 양식을 요구하지 않는다. 사장님께 "○○라고 입력하세요" 같은 형식을 가르치지 않는다.
- 사장님께 보내는 글은 짧게(5줄 안팎), 쉬운 말로, 존댓말로 쓴다. 전문 용어를 쓰지 않는다.
- 결정할 것이 있으면 맨 끝에 **"이대로 괜찮으시면 편하게 답해 주세요. 바꾸고 싶은 점은 그대로 말씀하시면 됩니다."** 한 줄을 붙인다.

## 1. 사장님 말 알아듣기
- 사장님 말에서 **책을 만들자는 뜻**이 보이면(예: "요즘 홈트 많이 하잖아, 초보용 책 하나 만들어 봐", "고양이 나오는 짧은 동화 써 줘") 주문으로 받는다.
  - 주제와 장르(실용서, 에세이, 동화, 소설, 자기계발 등)를 말에서 알아낸다. 장르를 말하지 않았으면 주제에 가장 어울리는 장르를 네가 정하고, 제안할 때 "장르는 ○○로 잡았어요"라고 알려 준다.
  - 독자, 분량, 분위기 같은 바람이 섞여 있으면 기억해서 기획에 반영한다.
- **동의하는 말**은 모두 수락으로 본다: "좋아요", "그렇게 해", "진행해", "ㅇㅋ", "오케이", "괜찮네", "보내 줘", "👍" 등. 고르는 말("2번이 좋네", "두 번째 제목으로")은 그 선택을 반영한 수락이다.
- **거부하는 말**("거부할게요", "이건 별로야, 하지 마", "멈춰")은 수락이 아니다. 진행 중인 작업을 멈추게 하고(팀원에게 알림), 무엇이 마음에 들지 않는지 한 줄로 묻는다. 새 지시가 올 때까지 다음 단계로 가지 않는다.
- **고쳐 달라는 말**("목차에 겨울 얘기도 넣어", "제목이 좀 딱딱해")이 있으면 수락이 아니다. 고친 뒤 다시 제안한다.
- 뜻이 애매하면 짐작해서 진행하지 말고, 한 줄로 되묻는다(예: "1번 제목으로 원고를 시작할까요?").
- **서버·배포 이야기**(예: "관리 화면을 서버에 올려 줘", "라이트세일에 배포해", "CI/CD 설정해", "배포 실패했대?", "서버 살아 있어?")는 책 주문이 아니다. 7장 순서대로 **테포만** 부른다. 책 팀은 부르지 않는다.
- 책과 상관없는 질문이나 인사에는 짧게 답한다. 진행 중인 책이 있으면 상황을 한 줄 덧붙인다.

## 2. 주문 받기
1. **다른 일보다 먼저** `reply`로 "접수했습니다. 팀을 꾸려 기획을 시작합니다."라고 답한다.
2. **이전 책의 팀원이 아직 남아 있으면 먼저 모두 종료를 요청하고**, 종료된 뒤에 새 팀을 꾸린다. (남아 있으면 새 팀원 이름에 `-2`가 붙어 같은 이름을 못 쓴다)
3. 이 책의 작업 폴더 이름을 정한다: `books/날짜-짧은영문이름` (예: `books/20261109-houseplants`). 날짜는 메시지의 시각(ts)에서 읽는다.
   폴더를 따로 만들지 않는다. 파일을 Write로 쓰면 폴더는 자동으로 생긴다. 하위 폴더는 `plan/ research/ manuscript/ review/ design/`를 쓴다.
   알아낸 주제·장르·사장님의 바람은 `plan/order.md`에 적어 둔다.
4. **에이전트 팀**을 만든다. `staff.yml`에서 team이 book인 직원 전부(지금은 아래 4명)를 **영문 이름**(팀원 이름은 영문만 가능)과 에이전트 타입(agent)으로 띄우고, 각자에게 작업 폴더 경로와 `plan/order.md` 내용을 알려 준다. 사장님께 말할 때는 한글 이름을 쓴다.
   - **minjun** = 민준 (에이전트 타입 `planner`): 기획
   - **jihun** = 지훈 (에이전트 타입 `researcher`): 자료 조사
   - **seoyeon** = 서연 (에이전트 타입 `writer`): 집필
   - **taeyang** = 태양 (에이전트 타입 `editor`): 교정·표지
5. 팀원들이 **서로 직접 메시지로 의논**하게 한다. 너는 지켜보다가 막히면 조정한다.

## 3. 기획 → 사장님 동의 ①
- 지훈이 먼저 조사하고, 민준이 지훈과 의논해 `plan/proposal.md`를 쓴다.
  - 제목 3안, 부제, 독자 한 명, 책의 약속 한 문장, 목차(기본 **3장**, 장마다 약 1,500자), 장르에 맞는 문체
  - 동화·소설처럼 이야기 책이면 조사 대신 인물·배경·줄거리를 정하고, 지훈은 배경 사실(동물 습성, 장소 등)만 확인한다.
- 다 되면 사장님께 `reply`로 **[제안]**을 보낸다: 장르, 제목 3안(번호), 목차, 분량. 끝에 0번의 마무리 한 줄.
- 사장님이 동의하면 확정한 제목·부제·저자를 `plan/title.txt`에 3줄로 쓴다(1줄 제목, 2줄 부제, 3줄 "그린데스크 출판사"). 제목을 고르지 않고 동의만 했으면 1번 제목으로 하고 그렇게 알린다.
- 사장님이 고칠 점을 말하면 민준에게 고치게 하고 다시 [제안]한다.

## 4. 원고·교정·표지 (사장님 동의 없이 팀이 알아서)
- 서연이 `manuscript/01.md, 02.md, 03.md`를 쓴다. 각 파일 첫 줄은 `# 1장. 장 제목` 모양.
- 장 하나가 끝날 때마다 서연이 태양에게 직접 알리고, 태양이 교정해 `review/0N.md`에 의견을 쓰고 서연에게 직접 보낸다. 서연은 반영하고 "반영 완료"라고 태양에게 답한다.
- 사실·숫자는 지훈의 `research/` 출처만 쓴다. 확인 못 한 내용은 쓰지 않거나 "(확인 필요)"로 표시하고 지훈에게 묻는다.
- 태양은 원고가 끝나면 표지를 `design/cover.svg`로 만든다(세로 600×900, 제목·부제·출판사 이름, 고딕 글꼴).
- 장이 끝날 때마다 사장님께 한 줄로 진행 상황을 `reply`한다(예: "📘 2장까지 썼어요. 3장 진행 중입니다.").
- 작업 중에 사장님이 새 바람을 말하면(예: "말투 좀 더 친근하게") 팀에 전달해 반영하고, 반영했다고 한 줄로 답한다.

## 5. 최종 보고 → 사장님 동의 ② → 책 보내기
- 최종본에 "(확인 필요)"가 남아 있으면 그 문장을 빼거나 안전한 문장으로 바꾼다.
- 사장님께 **[최종 보고]**를 보낸다: 제목, 장별 한 줄 요약, 글자 수. 끝에 "괜찮으시면 편하게 답해 주세요. 책을 묶어 PDF·EPUB으로 보내 드립니다."
- 사장님이 동의하면 Bash로 **정확히 이 모양 한 줄만** 실행한다: `bash make-book.sh books/작업폴더이름` (앞뒤에 cd, &&, 파이프를 붙이지 않는다)
- 만들어진 파일을 `reply`의 `files`에 **절대 경로**로 넣어 보낸다. PDF 한 번, EPUB 한 번 따로 보낸다.
  - PDF가 없으면(제본기가 "PDF 건너뜀"이라고 하면) HTML 파일을 보내고 "휴대폰이나 PC에서 열어 인쇄 → PDF로 저장하세요"라고 안내한다.
- 다 보내면 팀원들에게 종료를 요청한다.

## 6. 지킬 것
- Bash 명령은 제본기 한 줄 외에는 쓰지 않는다. (서버 명령은 테포만 쓴다) 파일 읽기·찾기·쓰기는 Read, Glob, Grep, Write, Edit 도구로 한다. (그래야 사장님이 없을 때 확인 창에서 멈추지 않는다)
- 모르는 사실은 지어내지 않는다.
- 직원들이 5분 넘게 조용하면 누가 무엇을 기다리는지 확인하고 다시 일을 맡긴다.
- 사장님이 진행 상황을 물으면(어떤 말투든) 지금 단계와 다음 할 일을 3줄로 답한다.
- 책 작업 폴더 밖의 파일은 지우거나 고치지 않는다. (예외: 7장의 `ops/approved.txt` 쓰기)

## 7. 서버 배포 (신입 테포 · 라이트세일 CI/CD 전담)
1. 서버·배포 이야기가 오면 **먼저** `reply`로 "접수했습니다. 서버 담당 테포에게 배포 준비를 맡겼습니다."라고 답한다.
2. 팀원 **tepo** = 테포 (에이전트 타입 `devops`) **한 명만** 띄운다. 책 팀이 일하는 중이어도 함께 띄워도 된다. 테포에게 사장님 말 원문을 전한다.
3. 테포가 `[보고] 준비 부족`을 보내면, 사장님께 할 일을 쉬운 말로 알린다. (예: "AWS 열쇠가 아직 없어요. 자습서 10-1을 따라 우분투 창에서 aws configure를 해 주세요.") 사장님이 "다 했어"라고 하면 테포에게 다시 확인하게 한다.
4. 테포가 `[보고] 배포 제안 재료`를 보내면 사장님께 **[배포 제안]**을 보낸다: 만들 것(서버 1대·MySQL DB 1개·고정 IP), 지역, **월 예상 비용(테포가 준 숫자 그대로)**, 완성 후 주소 모양, 걸리는 시간(약 20~30분). 끝에 0번의 마무리 한 줄.
5. 사장님이 **동의**하면 Write 도구로 `ops/approved.txt`에 두 줄을 쓴다: 1줄 지금 시각, 2줄 사장님 말 원문. 그다음 테포에게 "승인됨, 진행해"라고 보낸다. (이 파일이 없으면 테포의 스크립트가 서버를 만들지 않는다)
   - 사장님이 **거부**하거나 고칠 점을 말하면 승인 파일을 쓰지 않고, 테포에게 멈추라고 알린다.
6. 테포의 단계 보고마다 사장님께 한 줄로 알린다(예: "🛠 서버를 만들었어요. 지금 데이터베이스를 준비하는 중이에요(10~20분).").
7. 테포가 `[보고] 배포 완료`를 보내면 사장님께 **[배포 보고]**: 주소, 로그인 아이디, 비밀번호가 적힌 파일 위치(`ops/secrets/관리화면-로그인.txt` — 비밀번호를 채팅에 쓰지 않는다), 앞으로는 IntelliJ에서 고쳐서 push하면 자동 배포된다는 것, 쓰지 않을 때는 라이트세일에서 지워야 요금이 멈춘다는 것.
8. 끝나면 테포에게 종료를 요청한다.
PUBLISHER_FILE_6_END

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 파일 ~/my-publisher/connect.sh 를 만든다. (출근 도우미. 관리 화면 ↔ 쭌 연결(fakechat)이 켜졌는지 확인하고, 안 켜졌으면 다시 연결한다.)
# │   아래 345줄이 그 파일 내용 그대로이고, PUBLISHER_FILE_7_END 줄에서 끝난다.
# └── ▼ 실행 코드 [18] (아래 347줄이 한 덩어리) ────
cat > "$P/connect.sh" <<'PUBLISHER_FILE_7_END'
#!/bin/bash
# [1] 역할
#     connect.sh — 출근 도우미. 관리 화면 ↔ 쭌 연결(fakechat)이 켜졌는지 확인하고, 안 켜졌으면 다시 연결한다.
#     Claude Code 일부 버전에서는 처음 켤 때 fakechat 연결이 안 켜지는 일이 있다.
#     그때 사람이 하던 일(쭌 칸에서 /mcp → fakechat 고르기 → Reconnect)을 이 파일이 대신 눌러 준다.
#     start.sh 가 출근할 때 뒤에서 한 번 실행한다. 화면에는 아무것도 찍지 않고, 기록은 ~/my-publisher/.connect.log 에 남긴다.
#     맨 윗줄 #!/bin/bash : "쉬뱅(shebang)". 이 파일을 /bin/bash 프로그램으로 실행하라는 표시.
#       #! 는 파일 맨 처음에만 쓰며, 뒤에 적힌 프로그램(위치)으로 이 파일을 실행한다.
#
# [2] 받는 것 → 내보내는 것
#     받는 것    : 첫 번째 값 = 쭌 칸 위치(예: publisher:team.0), 환경변수 FAKECHAT_PORT(없으면 8787)
#                  tmux 쭌 칸 화면에 찍힌 글자(capture-pane 으로 읽음)
#     내보내는 것: 쭌 칸에 누르는 키(Escape, /mcp, ↓, Enter)
#                  기록 파일 ~/my-publisher/.connect.log  예) 09:01:12 출근 확인 시작 / 09:01:40 연결됨 (자동)
#                  끝 상태: 연결되면 0, 세 번 시도해도 안 되면 1 + tmux 아래쪽에 안내 글
#
# [3] 앞뒤 파일
#     start.sh  →  (이 파일, 뒤에서 실행)  →  fakechat 플러그인 (http://127.0.0.1:8787 이 대답하면 연결된 것)
#                                         →  관리 화면 대화방이 이 연결로 쭌과 이야기한다
#
# [4] 구역 목록
#     구역 1  변수와 작은 함수   PANE, PORT, LOG, up, screen, say
#     구역 2  처음 켤 때 기다림   최대 120번 × 2초, 저절로 연결되면 끝
#     구역 3  메뉴에서 fakechat 고르기 함수   on_fakechat, pick_fakechat
#     구역 4  직접 다시 연결     /mcp → fakechat → Reconnect, 최대 3번
#     구역 5  마무리             메뉴 닫기, 결과 기록
#
# [5] 먼저 알 용어
#     함수 이름() { … }, $1, ${값:-기본값}, curl, tmux capture-pane / send-keys, grep -q, |(파이프), for … do … done,
#     && / ||, exit 0 / exit 1, continue, break, return
#
# [6] 읽는 순서
#     구역 1(도구 준비) → 구역 2(기다림) → 구역 3(함수만 정의, 실행은 구역 4에서) → 구역 4 → 구역 5
#
# [7] 다 읽고 확인
#     - 처음부터 연결이 잘 되면 이 파일은 어디서 끝나는가? (구역 2 의 up && { say "연결됨 (자동)"; exit 0; })
#     - /mcp 메뉴에 claude.ai 커넥터가 섞여 있어도 엉뚱한 항목을 열지 않는 이유는? (on_fakechat 이 커서 줄에 fakechat 이 있는지 보고 나서만 Enter)
#
# [0] 코드만 모아 보기 — 이 파일에서 실제로 실행되는 줄 전체. 아래 본문에서 ▼ 실행 코드 [번호] 를 찾으면 그 줄의 설명이 있다.
#     [1] PANE="${1:-publisher:team.0}"
#     [2] PORT="${FAKECHAT_PORT:-8787}"
#     [3] LOG=~/my-publisher/.connect.log
#     [4] up() { curl -s -o /dev/null --max-time 2 "http://127.0.0.1:$PORT/"; }
#     [5] screen() { tmux capture-pane -p -t "$PANE" 2>/dev/null; }
#     [6] say() { echo "$(date +%H:%M:%S) $*" >> "$LOG"; }
#     [7] say "출근 확인 시작"
#     [8] for i in $(seq 1 120); do
#     [9]   up && { say "연결됨 (자동)"; exit 0; }
#     [10]   if screen | grep -q "trust this folder"; then sleep 2; continue; fi
#     [11]   screen | grep -q "accept edits\|for shortcuts" && [ "$i" -ge 10 ] && break
#     [12]   sleep 2
#     [13] done
#     [14] on_fakechat() { screen | grep -qE '^[[:space:]]*(›|>)[[:space:]].*fakechat'; }
#     [15] pick_fakechat() {
#     [16]   for k in $(seq 1 40); do
#     [17]     on_fakechat && return 0
#     [18]     tmux send-keys -t "$PANE" Down; sleep 0.3
#     [19]   done
#     [20]   return 1
#     [21] }
#     [22] for try in 1 2 3; do
#     [23]   up && { say "연결됨"; exit 0; }
#     [24]   say "다시 연결 시도 $try"
#     [25]   tmux send-keys -t "$PANE" Escape; sleep 0.5
#     [26]   tmux send-keys -t "$PANE" "/mcp" Enter; sleep 3
#     [27]   if ! pick_fakechat; then
#     [28]     say "메뉴에서 fakechat 을 찾지 못함 — 메뉴를 닫음"
#     [29]     tmux send-keys -t "$PANE" Escape; sleep 1; tmux send-keys -t "$PANE" Escape; sleep 5; continue
#     [30]   fi
#     [31]   tmux send-keys -t "$PANE" Enter; sleep 2
#     [32]   if screen | grep -q "Reconnect"; then tmux send-keys -t "$PANE" Enter; fi
#     [33]   for w in $(seq 1 15); do up && break; sleep 2; done
#     [34]   tmux send-keys -t "$PANE" Escape; sleep 0.5; tmux send-keys -t "$PANE" Escape
#     [35] done
#     [36] tmux send-keys -t "$PANE" Escape; sleep 0.5
#     [37] up && { say "연결됨"; exit 0; }
#     [38] say "연결 실패 — 쭌 칸에서 /mcp → fakechat → Reconnect 를 직접 눌러 주세요"
#     [39] tmux display-message -t "$PANE" "관리 화면 연결 실패: 쭌 칸에서 /mcp → fakechat → Reconnect" 2>/dev/null
#     [40] exit 1

# ━━━━━━━━━━ 구역 1  변수와 작은 함수 ━━━━━━━━━━

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 키를 누를 대상(쭌 칸)의 위치를 PANE 에 담는다.
# │   PANE             : 변수 이름. pane = tmux 의 칸.
# │   $1               : 이 파일을 실행할 때 넘겨준 첫 번째 값. start.sh 는 "publisher:team.0" 을 넘긴다.
# │   ${1:-…}          : 첫 번째 값이 비어 있으면 :- 뒤의 기본값을 쓴다.
# │   publisher:team.0 : publisher 세션의 team 창의 0번 칸(쭌 칸). 모양: 세션:창.칸
# └── ▼ 실행 코드 [1] ───────────────
PANE="${1:-publisher:team.0}"

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: fakechat 이 듣는 번호(포트)를 PORT 에 담는다.
# │   FAKECHAT_PORT : 환경변수. 미리 정해 두면 그 번호를 쓴다.
# │   8787          : 기본 포트. fakechat 대화방 주소는 http://localhost:8787
# └── ▼ 실행 코드 [2] ───────────────
PORT="${FAKECHAT_PORT:-8787}"

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 기록을 남길 파일 위치를 LOG 에 담는다.
# │   ~/my-publisher/.connect.log : 이름이 . 으로 시작하면 숨김 파일. `cat ~/my-publisher/.connect.log` 로 읽는다.
# └── ▼ 실행 코드 [3] ───────────────
LOG=~/my-publisher/.connect.log

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: up 이라는 함수를 만든다. fakechat 이 대답하는지(연결이 켜졌는지) 확인한다.
# │   up() { … }              : 함수 만들기. 아래에서 up 이라고만 쓰면 { } 안의 명령이 실행된다.
# │   curl                    : 주소에 요청을 보내는 프로그램(브라우저처럼 웹 주소를 여는 명령).
# │   -s                      : silent. 진행 상황 글을 찍지 않는다.
# │   -o /dev/null            : 받은 내용을 버린다(대답이 왔는지만 본다).
# │   --max-time 2            : 2초 안에 대답이 없으면 실패로 본다.
# │   http://127.0.0.1:$PORT/ : 내 컴퓨터(127.0.0.1)의 8787 번. fakechat 이 켜져 있으면 대답한다.
# │   결과                    : 대답하면 성공(0), 아니면 실패. if 나 && 가 이 성공/실패를 본다.
# └── ▼ 실행 코드 [4] ───────────────
up() { curl -s -o /dev/null --max-time 2 "http://127.0.0.1:$PORT/"; }

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: screen 이라는 함수를 만든다. 쭌 칸에 지금 보이는 글자를 그대로 읽어 온다.
# │   tmux capture-pane : 칸에 보이는 화면 글자를 가져오는 tmux 명령.
# │   -p                : 가져온 글자를 화면(표준 출력)으로 내보낸다. 그래야 | grep 으로 넘길 수 있다.
# │   -t "$PANE"        : 대상 칸 = 쭌 칸.
# │   2>/dev/null       : 칸이 아직 없을 때 나오는 오류 글을 버린다.
# └── ▼ 실행 코드 [5] ───────────────
screen() { tmux capture-pane -p -t "$PANE" 2>/dev/null; }

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: say 라는 함수를 만든다. 시각과 함께 한 줄을 기록 파일에 덧붙인다.
# │   echo              : 글자를 내보내는 명령.
# │   $(date +%H:%M:%S) : $( ) 안 명령의 결과로 바뀐다. date +%H:%M:%S = 지금 시각. 예) 09:01:12
# │   $*                : say 뒤에 적은 말 전체. 예) say "출근 확인 시작" → 출근 확인 시작
# │   >> "$LOG"         : 기록 파일 끝에 덧붙인다. (> 하나면 파일을 지우고 새로 쓴다)
# └── ▼ 실행 코드 [6] ───────────────
say() { echo "$(date +%H:%M:%S) $*" >> "$LOG"; }

# ━━━━━━━━━━ 구역 2  처음 켤 때 기다림 ━━━━━━━━━━

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 기록 파일에 "출근 확인 시작" 을 적는다. 예) 09:01:12 출근 확인 시작
# └── ▼ 실행 코드 [7] ───────────────
say "출근 확인 시작"

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 처음 켤 때 잠깐 기다린다. 최대 120번 반복(한 번에 2초 → 최대 약 4분).
# │   폴더 신뢰 질문(Is this a project you trust?)이 떠 있으면 사장님이 답할 때까지 기다린다.
# │   for i in …; do … done : 목록의 값을 하나씩 i 에 넣으며 do ~ done 사이를 반복한다.
# │   $(seq 1 120)          : seq = 1 부터 120 까지 숫자를 차례로 만든다.
# │   i                     : 지금 몇 번째인지. 1, 2, 3 …
# └── ▼ 실행 코드 [8] ───────────────
for i in $(seq 1 120); do

  # ┌── 설명 ──────────────────────────────────
  # │ ▶ 이 줄이 하는 일: 연결이 이미 켜졌으면 "연결됨 (자동)" 을 적고 이 파일을 끝낸다.
  # │   up        : 위에서 만든 함수. fakechat 이 대답하면 성공.
  # │   &&        : 앞이 성공일 때만 뒤를 실행.
  # │   { …; …; } : 명령 여러 개를 하나로 묶는다. 닫는 } 앞에 ; 이 꼭 있어야 한다.
  # │   exit 0    : 이 파일을 끝낸다. 0 = 성공으로 끝남.
  # └── ▼ 실행 코드 [9] ───────────────
  up && { say "연결됨 (자동)"; exit 0; }

  # ┌── 설명 ──────────────────────────────────
  # │ ▶ 이 줄이 하는 일: 쭌 칸에 "trust this folder" 질문이 보이면 2초 쉬고 다음 반복으로 넘어간다(사장님이 답하기를 기다림).
  # │   screen | grep -q "…" : 쭌 화면 글자에서 "…" 를 찾는다. | = 앞 결과를 뒤 명령에 넘김.
  # │   grep                 : 글자를 찾는 명령. -q = 찾은 줄을 찍지 않고 있었는지(성공/실패)만 알려 준다.
  # │   sleep 2              : 2초 쉰다.
  # │   continue             : 아래 줄을 건너뛰고 반복의 처음으로 간다.
  # │   fi                   : 이 if 의 끝(한 줄에 이어 썼다).
  # └── ▼ 실행 코드 [10] ──────────────
  if screen | grep -q "trust this folder"; then sleep 2; continue; fi

  # ┌── 설명 ──────────────────────────────────
  # │ ▶ 이 줄이 하는 일: 쭌의 입력칸이 다 떴고(화면 아래 "accept edits" 또는 "for shortcuts" 글자), 10번(약 20초) 넘게 기다렸는데도
  # │   연결이 안 되었으면 기다리기를 그만두고 구역 4(직접 다시 연결)로 간다.
  # │   "accept edits\|for shortcuts" : \| = 둘 중 하나라도 있으면 찾음. 쭌 입력칸 아래에 늘 보이는 안내 글.
  # │   [ "$i" -ge 10 ]               : i 가 10 이상이면 참. -ge = greater or equal(크거나 같다).
  # │   break                         : 반복을 그만두고 done 다음 줄로 나간다.
  # └── ▼ 실행 코드 [11] ──────────────
  screen | grep -q "accept edits\|for shortcuts" && [ "$i" -ge 10 ] && break

  # ┌── 설명 ──────────────────────────────────
  # │ ▶ 이 줄이 하는 일: 2초 쉬고 다음 반복으로.
  # └── ▼ 실행 코드 [12] ──────────────
  sleep 2

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 위 for / while 반복의 끝
# └── ▼ 실행 코드 [13] ──────────────
done

# ━━━━━━━━━━ 구역 3  메뉴에서 fakechat 고르기 함수 ━━━━━━━━━━

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: on_fakechat 함수: /mcp 메뉴에서 커서(› 또는 >)가 놓인 줄이 fakechat 인지 확인한다.
# │   예전에는 순서 번호만 세서 ↓ 를 눌렀더니 claude.ai 커넥터(Claude Docs)가 열렸다. 그래서 화면 글자를 직접 본다.
# │   화면 아래 입력칸(> Try …)도 ">" 로 시작하므로, 같은 줄에 fakechat 이 있어야만 맞다고 본다.
# │   grep -qE     : -E = 확장 정규식(글자 모양 규칙)을 쓴다. -q = 결과만.
# │   '^…'         : ^ = 줄의 맨 앞.
# │   [[:space:]]* : 띄어쓰기가 0개 이상.
# │   (›|>)        : › 또는 > 글자(메뉴의 커서 표시).
# │   .*fakechat   : 그 뒤 어디든 fakechat 이 있음.  예) "› plugin:fakechat:fakechat · ✗ failed"
# └── ▼ 실행 코드 [14] ──────────────
on_fakechat() { screen | grep -qE '^[[:space:]]*(›|>)[[:space:]].*fakechat'; }

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: pick_fakechat 함수: 커서가 fakechat 줄에 올 때까지 ↓ 를 누른다(최대 40번).
# │   pick_fakechat() { : 함수 몸통이 여러 줄이라 { 와 } 사이에 줄을 나눠 썼다.
# └── ▼ 실행 코드 [15] ──────────────
pick_fakechat() {

  # ┌── 설명 ──────────────────────────────────
  # │ ▶ 이 줄이 하는 일: 최대 40번 반복한다(메뉴 항목이 40개를 넘지 않는다고 본다).
  # └── ▼ 실행 코드 [16] ──────────────
  for k in $(seq 1 40); do

    # ┌── 설명 ──────────────────────────────────
    # │ ▶ 이 줄이 하는 일: 커서가 fakechat 줄에 있으면 함수를 성공(0)으로 끝낸다.
    # │   return 0 : 함수를 끝내고 성공을 돌려준다. (exit 와 달리 파일 전체는 끝나지 않는다)
    # └── ▼ 실행 코드 [17] ──────────────
    on_fakechat && return 0

    # ┌── 설명 ──────────────────────────────────
    # │ ▶ 이 줄이 하는 일: 쭌 칸에 ↓ 키를 한 번 누르고 0.3초 기다린다(화면이 바뀔 시간).
    # │   Down      : 아래 화살표 키.
    # │   sleep 0.3 : 0.3초 쉰다.
    # └── ▼ 실행 코드 [18] ──────────────
    tmux send-keys -t "$PANE" Down; sleep 0.3

  # ┌── 설명 ──────────────────────────────────
  # │ ▶ 이 줄이 하는 일: 위 for / while 반복의 끝
  # └── ▼ 실행 코드 [19] ──────────────
  done

  # ┌── 설명 ──────────────────────────────────
  # │ ▶ 이 줄이 하는 일: 40번 눌러도 fakechat 줄을 못 찾았으면 실패(1)를 돌려준다.
  # └── ▼ 실행 코드 [20] ──────────────
  return 1

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 위 { 로 시작한 묶음(함수 몸통)의 끝
# └── ▼ 실행 코드 [21] ──────────────
}

# ━━━━━━━━━━ 구역 4  직접 다시 연결 (최대 3번) ━━━━━━━━━━

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 직접 다시 연결: /mcp → fakechat 고르기 → Reconnect 를 최대 3번 시도한다.
# │   try : 몇 번째 시도인지. 1, 2, 3
# └── ▼ 실행 코드 [22] ──────────────
for try in 1 2 3; do

  # ┌── 설명 ──────────────────────────────────
  # │ ▶ 이 줄이 하는 일: 그사이 연결이 켜졌으면 "연결됨" 을 적고 끝낸다.
  # └── ▼ 실행 코드 [23] ──────────────
  up && { say "연결됨"; exit 0; }

  # ┌── 설명 ──────────────────────────────────
  # │ ▶ 이 줄이 하는 일: 기록에 "다시 연결 시도 1" 처럼 몇 번째인지 적는다.
  # └── ▼ 실행 코드 [24] ──────────────
  say "다시 연결 시도 $try"

  # ┌── 설명 ──────────────────────────────────
  # │ ▶ 이 줄이 하는 일: 혹시 열려 있을 메뉴를 닫으려고 Esc 를 한 번 누르고 0.5초 쉰다.
  # │   Escape : Esc 키.
  # └── ▼ 실행 코드 [25] ──────────────
  tmux send-keys -t "$PANE" Escape; sleep 0.5

  # ┌── 설명 ──────────────────────────────────
  # │ ▶ 이 줄이 하는 일: 쭌 입력칸에 /mcp 를 치고 Enter → 연결 목록 메뉴가 열린다. 3초 기다린다.
  # │   /mcp : Claude Code 의 연결(MCP 서버·플러그인) 목록을 보여 주는 명령.
  # └── ▼ 실행 코드 [26] ──────────────
  tmux send-keys -t "$PANE" "/mcp" Enter; sleep 3

  # ┌── 설명 ──────────────────────────────────
  # │ ▶ 이 줄이 하는 일: fakechat 줄을 못 찾았으면(아래 두 줄 실행).
  # │   ! : 결과를 뒤집는다. 실패면 참.
  # └── ▼ 실행 코드 [27] ──────────────
  if ! pick_fakechat; then

    # ┌── 설명 ──────────────────────────────────
    # │ ▶ 이 줄이 하는 일: 못 찾았다고 기록한다.
    # └── ▼ 실행 코드 [28] ──────────────
    say "메뉴에서 fakechat 을 찾지 못함 — 메뉴를 닫음"

    # ┌── 설명 ──────────────────────────────────
    # │ ▶ 이 줄이 하는 일: Esc 를 두 번 눌러 메뉴를 닫고 5초 쉰 뒤, 다음 시도로 넘어간다(continue).
    # └── ▼ 실행 코드 [29] ──────────────
    tmux send-keys -t "$PANE" Escape; sleep 1; tmux send-keys -t "$PANE" Escape; sleep 5; continue

  # ┌── 설명 ──────────────────────────────────
  # │ ▶ 이 줄이 하는 일: 위 if 블록의 끝 (if 를 거꾸로 쓴 말)
  # └── ▼ 실행 코드 [30] ──────────────
  fi

  # ┌── 설명 ──────────────────────────────────
  # │ ▶ 이 줄이 하는 일: 커서가 fakechat 줄에 있으니 Enter → fakechat 상세 화면이 열린다. 2초 기다린다.
  # └── ▼ 실행 코드 [31] ──────────────
  tmux send-keys -t "$PANE" Enter; sleep 2

  # ┌── 설명 ──────────────────────────────────
  # │ ▶ 이 줄이 하는 일: 상세 화면에 "Reconnect"(다시 연결) 글자가 보이면 Enter 로 누른다.
  # │   Reconnect : 연결이 끊긴 플러그인을 다시 켜는 메뉴 항목.
  # └── ▼ 실행 코드 [32] ──────────────
  if screen | grep -q "Reconnect"; then tmux send-keys -t "$PANE" Enter; fi

  # ┌── 설명 ──────────────────────────────────
  # │ ▶ 이 줄이 하는 일: 최대 15번(약 30초) 연결이 켜지기를 기다린다. 켜지면 바로 반복을 나간다(break).
  # └── ▼ 실행 코드 [33] ──────────────
  for w in $(seq 1 15); do up && break; sleep 2; done

  # ┌── 설명 ──────────────────────────────────
  # │ ▶ 이 줄이 하는 일: 메뉴를 닫으려고 Esc 를 두 번 누른다. 시도마다 메뉴가 남지 않게 한다.
  # └── ▼ 실행 코드 [34] ──────────────
  tmux send-keys -t "$PANE" Escape; sleep 0.5; tmux send-keys -t "$PANE" Escape

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 위 for / while 반복의 끝
# └── ▼ 실행 코드 [35] ──────────────
done

# ━━━━━━━━━━ 구역 5  마무리 ━━━━━━━━━━

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 마지막으로 메뉴가 남아 있지 않도록 Esc 를 한 번 더 누른다.
# └── ▼ 실행 코드 [36] ──────────────
tmux send-keys -t "$PANE" Escape; sleep 0.5

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 세 번 시도 뒤 연결이 켜졌으면 "연결됨" 을 적고 끝낸다.
# └── ▼ 실행 코드 [37] ──────────────
up && { say "연결됨"; exit 0; }

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 끝까지 연결이 안 되면 사장님이 할 일을 기록에 적는다.
# └── ▼ 실행 코드 [38] ──────────────
say "연결 실패 — 쭌 칸에서 /mcp → fakechat → Reconnect 를 직접 눌러 주세요"

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: tmux 화면 아래 상태줄에 같은 안내를 잠깐 띄운다.
# │   display-message : tmux 상태줄에 글을 보여 주는 명령.
# └── ▼ 실행 코드 [39] ──────────────
tmux display-message -t "$PANE" "관리 화면 연결 실패: 쭌 칸에서 /mcp → fakechat → Reconnect" 2>/dev/null

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 이 파일을 실패(1)로 끝낸다.
# └── ▼ 실행 코드 [40] ──────────────
exit 1
PUBLISHER_FILE_7_END

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 파일 ~/my-publisher/make-book.sh 를 만든다. (원고를 묶어 전자책(HTML·EPUB·PDF)을 만드는 '제본기'. AI 가 아니라 보통 프로그램이라 AI 사용량이 0 이다.)
# │   아래 970줄이 그 파일 내용 그대로이고, PUBLISHER_FILE_8_END 줄에서 끝난다.
# └── ▼ 실행 코드 [19] (아래 972줄이 한 덩어리) ────
cat > "$P/make-book.sh" <<'PUBLISHER_FILE_8_END'
#!/bin/bash
# [1] 역할
#     make-book.sh — 원고를 묶어 전자책(HTML·EPUB·PDF)을 만드는 '제본기'. AI 가 아니라 보통 프로그램이라 AI 사용량이 0 이다.
#     쭌(편집장)이 최종 보고 단계에서 `bash make-book.sh books/작업폴더` 로 실행한다(CLAUDE.md 4번, settings.json 의 허용 목록).
#     파일 안에 두 가지 언어가 섞여 있다.
#       - bash   : 맨 위 두 줄과 맨 아래 PDF 만들기
#       - Python : <<'PY' 와 PY 사이. 글(마크다운)을 HTML 로 바꾸고 EPUB 파일을 만든다.
#     다른 주제(예: 유튜브 영상팀)로 바꿀 때는 이 파일 자리에 그 주제의 결과물 도구를 새로 만든다.
#     맨 윗줄 #!/bin/bash : "쉬뱅(shebang)". 이 파일을 /bin/bash 프로그램으로 실행하라는 표시.
#       #! 는 파일 맨 처음에만 쓰며, 뒤에 적힌 프로그램(위치)으로 이 파일을 실행한다.
#
# [2] 받는 것 → 내보내는 것
#     사용법     : bash make-book.sh books/작업폴더
#     받는 것    : books/작업폴더/manuscript/*.md   (장마다 파일 하나, 이름이 _ 로 시작하면 뺌)
#                  books/작업폴더/plan/title.txt    (1줄 제목, 2줄 부제, 3줄 저자)
#                  books/작업폴더/design/cover.svg  (없으면 글자 표지)
#     내보내는 것: books/작업폴더/dist/book.html, dist/book.epub, dist/book.pdf (PDF 는 Windows Edge 또는 Chromium 이 있을 때)
#                  화면 예) ✅ 제본 완료: 「느린 아침의 기술」 5개 장, 약 12,345자
#
# [3] 앞뒤 파일
#     CLAUDE.md(4. 최종 보고) → 쭌이 이 파일 실행 → dist/book.*
#                                              → 관리 화면이 dist/ 를 읽어 "PDF·EPUB 내려받기" 단추를 보여 줌
#     .claude/settings.json 의 "Bash(bash make-book.sh:*)" 줄이 있어야 쭌이 묻지 않고 실행할 수 있다.
#
# [4] 구역 목록
#     구역 1  책 폴더 확인 (bash)
#     구역 2  Python 시작: 원고 목록, 제목 읽기
#     구역 3  마크다운 → HTML 바꾸는 함수 inline, md2html
#     구역 4  장(chapter) 모으기, 표지
#     구역 5  book.html 만들기 (모양 css 포함)
#     구역 6  book.epub 만들기
#     구역 7  결과 알림 (Python 끝)
#     구역 8  book.pdf 만들기 (bash, Edge 또는 Chromium)
#
# [5] 먼저 알 용어
#     bash: $( ), ||, heredoc(<<'PY' … PY), for/if, [ -f ] [ -s ] [ -x ], \ (다음 줄로 이어짐), timeout
#     Python: import, 변수 =, 리스트 [ ], 튜플 ( ), 함수 def, return, if/for, f"…{값}…", re.sub(정규식 바꾸기), with
#     마크다운: # 제목, - 목록, > 인용, **굵게**, *기울임*, `코드`
#
# [6] 읽는 순서
#     구역 1 → 2 → 4 → 5 → 6 → 7 → 8 을 먼저 읽고, 구역 3(글을 HTML 로 바꾸는 규칙)은 마지막에 읽는다.
#
# [7] 다 읽고 확인
#     - plan/title.txt 가 없으면 책 제목은 무엇이 되는가? ("제목 없는 책", 저자 "그린데스크 출판사")
#     - 원고에 "(확인 필요)" 라는 글이 남아 있으면 책에 찍히는가? (아니다. 구역 4 에서 지운다)
#
# [0] 코드만 모아 보기 — 이 파일에서 실제로 실행되는 줄 전체. 아래 본문에서 ▼ 실행 코드 [번호] 를 찾으면 그 줄의 설명이 있다.
#     [1] BOOK_DIR="$(cd "${1:-.}" 2>/dev/null && pwd)" || { echo "❌ 책 폴더를 찾을 수 없어요: $1"; exit 1; }
#     [2] python3 - "$BOOK_DIR" <<'PY' || exit 1
#     [3] import sys, os, re, html, glob, zipfile, uuid, datetime
#     [4] book = sys.argv[1]
#     [5] mdir, ddir = os.path.join(book, "manuscript"), os.path.join(book, "dist")
#     [6] os.makedirs(ddir, exist_ok=True)
#     [7] files = sorted(f for f in glob.glob(os.path.join(mdir, "*.md")) if not os.path.basename(f).startswith("_"))
#     [8] if not files:
#     [9]     print("❌ manuscript 폴더에 원고(.md)가 없습니다. 원고가 먼저 있어야 책을 묶을 수 있어요."); sys.exit(1)
#     [10] meta = ["제목 없는 책", "", "그린데스크 출판사"]
#     [11] tp = os.path.join(book, "plan", "title.txt")
#     [12] if os.path.exists(tp):
#     [13]     lines = [l.strip() for l in open(tp, encoding="utf-8") if l.strip()]
#     [14]     for i, l in enumerate(lines[:3]): meta[i] = re.sub(r"^(제목|부제|저자)\s*[:：]\s*", "", l)
#     [15] title, subtitle, author = meta
#     [16] def inline(t):
#     [17]     t = html.escape(t, quote=False)
#     [18]     t = re.sub(r"`([^`]+)`", r"<code>\1</code>", t)
#     [19]     t = re.sub(r"\*\*([^*]+)\*\*", r"<strong>\1</strong>", t)
#     [20]     t = re.sub(r"(?<!\*)\*([^*\s][^*]*)\*(?!\*)", r"<em>\1</em>", t)
#     [21]     t = re.sub(r"\[([^\]]+)\]\((https?://[^)\s]+)\)", r'<a href="\2">\1</a>', t)
#     [22]     return t
#     [23] def md2html(src):
#     [24]     out, para, lst, bq = [], [], None, None
#     [25]     def flush():
#     [26]         nonlocal para, lst, bq
#     [27]         if para: out.append("<p>" + inline(" ".join(para)) + "</p>"); para = []
#     [28]         if lst: out.append(f"</{lst}>"); lst = None
#     [29]         if bq is not None:
#     [30]             body = "".join(f"<p>{inline(' '.join(x))}</p>" for x in bq if x)
#     [31]             if body: out.append(f"<blockquote>{body}</blockquote>")
#     [32]             bq = None
#     [33]     for raw in src.splitlines():
#     [34]         l = raw.rstrip()
#     [35]         if l.startswith(">"):
#     [36]             t = l[1:].strip()
#     [37]             if bq is None:
#     [38]                 if para or lst: flush()
#     [39]                 bq = [[]]
#     [40]             if t: bq[-1].append(t)
#     [41]             else: bq.append([])
#     [42]             continue
#     [43]         if bq is not None: flush()
#     [44]         if not l.strip(): flush(); continue
#     [45]         l = re.sub(r"^(\s*[-*]\s+)\[ \]\s*", r"\1☐ ", l)
#     [46]         l = re.sub(r"^(\s*[-*]\s+)\[[xX]\]\s*", r"\1☑ ", l)
#     [47]         m = re.match(r"^(#{1,4})\s+(.*)", l)
#     [48]         if m:
#     [49]             flush(); n = len(m.group(1)); out.append(f"<h{n}>{inline(m.group(2))}</h{n}>"); continue
#     [50]         m = re.match(r"^\s*([-*]|\d+[.)])\s+(.*)", l)
#     [51]         if m:
#     [52]             if para: out.append("<p>" + inline(" ".join(para)) + "</p>"); para = []
#     [53]             kind = "ol" if m.group(1)[0].isdigit() else "ul"
#     [54]             if lst != kind:
#     [55]                 if lst: out.append(f"</{lst}>")
#     [56]                 out.append(f"<{kind}>"); lst = kind
#     [57]             out.append(f"<li>{inline(m.group(2))}</li>"); continue
#     [58]         if re.match(r"^-{3,}$", l.strip()): flush(); out.append("<hr/>"); continue
#     [59]         if lst: out.append(f"</{lst}>"); lst = None
#     [60]         para.append(l.strip())
#     [61]     flush()
#     [62]     return "\n".join(out)
#     [63] chapters = []
#     [64] for f in files:
#     [65]     src = open(f, encoding="utf-8").read()
#     [66]     src = re.sub(r"\((확인 필요|출처 필요)\)", "", src)
#     [67]     m = re.search(r"^#\s+(.+)$", src, re.M)
#     [68]     chapters.append((m.group(1).strip() if m else os.path.splitext(os.path.basename(f))[0], md2html(src)))
#     [69] svgp = os.path.join(book, "design", "cover.svg")
#     [70] svg = open(svgp, encoding="utf-8").read() if os.path.exists(svgp) else ""
#     [71] svg = re.sub(r"<\?xml[^>]*\?>", "", svg).strip()
#     [72] text_cover = f'<div class="tc"><h1>{html.escape(title)}</h1><p>{html.escape(subtitle)}</p><p class="au">{ht…
#     [73] cover = svg or text_cover
#     [74] css = """   (+14줄)
#     [75] today = datetime.date.today().isoformat()
#     [76] toc = "".join(f'<li><a href="#ch{i}">{html.escape(t)}</a></li>' for i, (t, _) in enumerate(chapters, 1))
#     [77] body = "".join(f'<section class="ch" id="ch{i}">{h}</section>' for i, (_, h) in enumerate(chapters, 1))
#     [78] page = f"""<!doctype html><html lang="ko"><head><meta charset="utf-8"><title>{html.escape(title)}</title><s…   (+6줄)
#     [79] open(os.path.join(ddir, "book.html"), "w", encoding="utf-8").write(page)
#     [80] uid = "urn:uuid:" + str(uuid.uuid5(uuid.NAMESPACE_URL, book + title))
#     [81] def xhtml(t, inner):
#     [82]     return f'<?xml version="1.0" encoding="utf-8"?><!DOCTYPE html><html xmlns="http://www.w3.org/1999/xhtml…
#     [83] def fix(h):  # XHTML 형식 맞추기
#     [84]     return h.replace("<hr/>", "<hr />")
#     [85] ep = os.path.join(ddir, "book.epub")
#     [86] with zipfile.ZipFile(ep, "w") as z:
#     [87]     z.writestr(zipfile.ZipInfo("mimetype"), "application/epub+zip", compress_type=zipfile.ZIP_STORED)
#     [88]     zc = lambda n, d: z.writestr(n, d, compress_type=zipfile.ZIP_DEFLATED)
#     [89]     zc("META-INF/container.xml", '<?xml version="1.0"?><container version="1.0" xmlns="urn:oasis:names:tc:o…
#     [90]     zc("OEBPS/style.css", css.replace("@page{size:A5;margin:18mm 16mm}", ""))
#     [91]     items, spine = [], []
#     [92]     cov_inner = f'<div class="cover">{svg}</div>' if svg.startswith("<svg") else text_cover
#     [93]     zc("OEBPS/cover.xhtml", xhtml(title, cov_inner)); items.append('<item id="cover" href="cover.xhtml" med…
#     [94]     navl = "".join(f'<li><a href="ch{i}.xhtml">{html.escape(t)}</a></li>' for i, (t, _) in enumerate(chapte…
#     [95]     zc("OEBPS/nav.xhtml", f'<?xml version="1.0" encoding="utf-8"?><!DOCTYPE html><html xmlns="http://www.w3…
#     [96]     items.append('<item id="nav" href="nav.xhtml" media-type="application/xhtml+xml" properties="nav"/>'); …
#     [97]     for i, (t, h) in enumerate(chapters, 1):
#     [98]         zc(f"OEBPS/ch{i}.xhtml", xhtml(t, fix(h)))
#     [99]         items.append(f'<item id="ch{i}" href="ch{i}.xhtml" media-type="application/xhtml+xml"/>'); spine.ap…
#     [100]     items.append('<item id="css" href="style.css" media-type="text/css"/>')
#     [101]     mod = datetime.datetime.now(datetime.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
#     [102]     zc("OEBPS/content.opf", f'<?xml version="1.0" encoding="utf-8"?><package xmlns="http://www.idpf.org/200…
#     [103] n = sum(len(re.sub(r"\s", "", re.sub(r"<[^>]+>", "", h))) for _, h in chapters)
#     [104] print(f"✅ 제본 완료: 「{title}」 {len(chapters)}개 장, 약 {n:,}자")
#     [105] print(f"   📄 {ddir}/book.html")
#     [106] print(f"   📱 {ddir}/book.epub  ← 전자책 리더·리디·교보 eBook 등록용")
#     [107] DIST="$BOOK_DIR/dist"; rm -f "$DIST/book.pdf"
#     [108] EDGE=""
#     [109] for p in "/mnt/c/Program Files (x86)/Microsoft/Edge/Application/msedge.exe" "/mnt/c/Program Files/Microsoft…
#     [110]   [ -f "$p" ] && EDGE="$p" && break
#     [111] done
#     [112] if [ -n "$EDGE" ]; then
#     [113]   W=/mnt/c/Users/Public/ai-publisher-tmp; mkdir -p "$W" && cp "$DIST/book.html" "$W/book.html" && rm -f "$W…
#     [114]   timeout 120 "$EDGE" --headless --disable-gpu --no-pdf-header-footer \   (+1줄)
#     [115]   [ -s "$W/book.pdf" ] && cp "$W/book.pdf" "$DIST/book.pdf"
#     [116] else
#     [117]   for b in chromium chromium-browser google-chrome /opt/pw-browsers/chromium-*/chrome-linux/chrome; do
#     [118]     if command -v "$b" >/dev/null 2>&1 || [ -x "$b" ]; then
#     [119]       timeout 120 "$b" --headless --no-sandbox --disable-gpu --no-pdf-header-footer \   (+1줄)
#     [120]       break
#     [121]     fi
#     [122]   done
#     [123] fi
#     [124] if [ -s "$DIST/book.pdf" ]; then
#     [125]   echo "   📕 $DIST/book.pdf"
#     [126] else
#     [127]   echo "   (PDF 건너뜀 — book.html을 열어 인쇄 → PDF로 저장하세요)"
#     [128] fi

# ━━━━━━━━━━ 구역 1  책 폴더 확인 (bash) ━━━━━━━━━━

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 받은 책 폴더를 "/" 부터 시작하는 전체 경로로 바꿔 BOOK_DIR 에 담는다. 폴더가 없으면 오류를 알리고 끝낸다.
# │   $1                       : 실행할 때 넘긴 첫 번째 값. 예) books/2026-11-09-slow-morning
# │   ${1:-.}                  : 첫 번째 값이 비었으면 . (지금 폴더).
# │   cd … && pwd              : 그 폴더로 들어가서(cd) 전체 경로를 찍는다(pwd). 예) /home/khbs_d_0/my-publisher/books/2026-11-09-slow-morning
# │   "$( … )"                 : 안 명령이 찍은 글이 값이 된다.
# │   2>/dev/null              : cd 가 실패할 때 나오는 오류 글을 버린다.
# │   ||                       : 앞이 실패하면 뒤를 실행한다.
# │   { echo "❌ …"; exit 1; } : 오류 글을 찍고 실패(1)로 끝낸다.
# └── ▼ 실행 코드 [1] ───────────────
BOOK_DIR="$(cd "${1:-.}" 2>/dev/null && pwd)" || { echo "❌ 책 폴더를 찾을 수 없어요: $1"; exit 1; }

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 아래 PY 까지의 글을 Python 프로그램으로 실행한다. 책 폴더 경로를 넘겨준다. Python 이 실패하면 여기서 끝낸다.
# │   python3     : Python 언어 실행 프로그램.
# │   -           : 프로그램을 파일 대신 "입력"으로 받겠다는 뜻.
# │   "$BOOK_DIR" : Python 안에서 sys.argv[1] 로 받는 값.
# │   <<'PY'      : heredoc. 이 줄 다음부터 PY 라고만 적힌 줄 앞까지를 입력으로 준다.
# │                 따옴표('PY')로 감싸서 그 안의 $ 를 bash 가 바꾸지 않고 그대로 Python 에 넘긴다.
# │   || exit 1   : Python 이 실패(원고 없음 등)하면 PDF 단계로 가지 않고 끝낸다.
# └── ▼ 실행 코드 [2] ───────────────
python3 - "$BOOK_DIR" <<'PY' || exit 1

# ━━━━━━━━━━ 구역 2  Python 시작: 원고 목록, 제목 읽기 ━━━━━━━━━━

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 쓸 Python 도구(모듈)들을 불러온다.
# │   import   : 도구 묶음을 불러오는 말.
# │   sys      : 실행할 때 받은 값(sys.argv)·끝내기(sys.exit)
# │   os       : 파일·폴더 경로 다루기
# │   re       : 정규식(글자 모양 규칙)으로 찾기·바꾸기
# │   html     : HTML 특수 글자(< > &) 바꾸기
# │   glob     : "*.md" 같은 모양으로 파일 찾기
# │   zipfile  : zip 파일 만들기 (EPUB 은 사실 zip 파일)
# │   uuid     : 책마다 다른 고유 번호 만들기
# │   datetime : 오늘 날짜·지금 시각
# └── ▼ 실행 코드 [3] ───────────────
import sys, os, re, html, glob, zipfile, uuid, datetime

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 넘겨받은 책 폴더 경로를 book 에 담는다.
# │   sys.argv[1] : bash 가 넘겨준 첫 번째 값(= "$BOOK_DIR"). [0] 은 프로그램 자신이라 [1] 부터가 받은 값.
# └── ▼ 실행 코드 [4] ───────────────
book = sys.argv[1]

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 원고 폴더와 결과 폴더 경로를 한 번에 만든다.
# │   a, b = x, y  : 두 변수에 한 번에 넣는다.
# │   os.path.join : 폴더 이름을 / 로 이어 경로를 만든다. 예) …/slow-morning/manuscript
# │   mdir         : manuscript 폴더 = 원고
# │   ddir         : dist 폴더 = 완성 파일 (distribution 의 줄임)
# └── ▼ 실행 코드 [5] ───────────────
mdir, ddir = os.path.join(book, "manuscript"), os.path.join(book, "dist")

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: dist 폴더를 만든다. 이미 있으면 그냥 넘어간다.
# │   exist_ok=True : 이미 있어도 오류로 보지 않는다.
# └── ▼ 실행 코드 [6] ───────────────
os.makedirs(ddir, exist_ok=True)

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 원고 폴더의 .md 파일을 이름 순서로 모은다. 이름이 _ 로 시작하는 파일(메모 등)은 뺀다.
# │   glob.glob(… "*.md")      : 확장자가 .md 인 파일 전부.
# │   if not … startswith("_") : 이름이 _ 로 시작하지 않는 것만.
# │   sorted                   : 이름 순서로 정렬. 그래서 원고 이름을 01-…, 02-… 로 짓는다.
# │   결과 예                  : ['…/manuscript/01-intro.md', '…/manuscript/02-morning.md']
# └── ▼ 실행 코드 [7] ───────────────
files = sorted(f for f in glob.glob(os.path.join(mdir, "*.md")) if not os.path.basename(f).startswith("_"))

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 원고가 하나도 없으면 아래 줄을 실행한다.
# │   not files : 목록이 비어 있으면 참.
# └── ▼ 실행 코드 [8] ───────────────
if not files:

    # ┌── 설명 ──────────────────────────────────
    # │ ▶ 이 줄이 하는 일: 원고가 없다는 글을 찍고 실패(1)로 끝낸다. → bash 의 || exit 1 때문에 PDF 단계도 건너뛴다.
    # │   sys.exit(1) : Python 을 실패로 끝낸다.
    # └── ▼ 실행 코드 [9] ───────────────
    print("❌ manuscript 폴더에 원고(.md)가 없습니다. 원고가 먼저 있어야 책을 묶을 수 있어요."); sys.exit(1)

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 책 정보의 기본값. [제목, 부제, 저자] 순서. title.txt 가 없거나 줄이 모자라면 이 값이 쓰인다.
# │   [ … ] : 리스트(여러 값을 순서대로 담는 묶음).
# └── ▼ 실행 코드 [10] ──────────────
meta = ["제목 없는 책", "", "그린데스크 출판사"]

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: title.txt 경로를 tp 에 담는다. 예) …/slow-morning/plan/title.txt
# └── ▼ 실행 코드 [11] ──────────────
tp = os.path.join(book, "plan", "title.txt")

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: title.txt 가 있으면 아래 두 줄로 meta 를 채운다.
# │   os.path.exists : 그 파일이 있으면 True.
# └── ▼ 실행 코드 [12] ──────────────
if os.path.exists(tp):

    # ┌── 설명 ──────────────────────────────────
    # │ ▶ 이 줄이 하는 일: title.txt 를 줄마다 읽어 앞뒤 공백을 지우고, 빈 줄은 뺀다.
    # │   open(tp, encoding="utf-8") : 파일을 한글(utf-8)로 연다. for 로 돌리면 한 줄씩 나온다.
    # │   l.strip()                  : 줄 앞뒤의 공백·줄바꿈을 지운다.
    # │   [x for l in … if …]        : 조건에 맞는 것만 모아 새 리스트를 만드는 짧은 문법.
    # └── ▼ 실행 코드 [13] ──────────────
    lines = [l.strip() for l in open(tp, encoding="utf-8") if l.strip()]

    # ┌── 설명 ──────────────────────────────────
    # │ ▶ 이 줄이 하는 일: 앞 3줄을 차례로 meta 의 0·1·2 번 칸에 넣는다. 줄 앞의 "제목:" "부제:" "저자:" 글자는 지운다.
    # │   lines[:3]                    : 앞에서 3개까지.
    # │   enumerate                    : 번호(i = 0,1,2)와 값(l)을 같이 준다.
    # │   re.sub(규칙, 바꿀 글, 대상)  : 규칙에 맞는 부분을 바꾼다. 여기서는 "" 로 바꿔 지운다.
    # │   ^(제목|부제|저자)\s*[:：]\s* : 줄 맨 앞(^)의 제목/부제/저자 + 공백 + 쌍점(: 또는 전각 ：) + 공백.
    # │                                  예) "제목: 느린 아침의 기술" → "느린 아침의 기술"
    # └── ▼ 실행 코드 [14] ──────────────
    for i, l in enumerate(lines[:3]): meta[i] = re.sub(r"^(제목|부제|저자)\s*[:：]\s*", "", l)

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: meta 의 세 값을 각각 title(제목), subtitle(부제), author(저자)에 나눠 담는다.
# └── ▼ 실행 코드 [15] ──────────────
title, subtitle, author = meta

# ━━━━━━━━━━ 구역 3  마크다운 → HTML 바꾸는 함수 ━━━━━━━━━━

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: inline 함수: 한 줄 안의 마크다운 꾸밈(`코드`, **굵게**, *기울임*, [글](주소))을 HTML 로 바꾼다.
# │   def 이름(값): : 함수 만들기. 아래 들여쓴 줄이 함수 몸통.
# │   t             : 바꿀 글 한 덩어리.
# └── ▼ 실행 코드 [16] ──────────────
def inline(t):

    # ┌── 설명 ──────────────────────────────────
    # │ ▶ 이 줄이 하는 일: < > & 를 &lt; &gt; &amp; 로 바꾼다. 원고의 < 가 HTML 태그로 잘못 읽히지 않게.
    # │   quote=False : 따옴표(" ')는 그대로 둔다.
    # └── ▼ 실행 코드 [17] ──────────────
    t = html.escape(t, quote=False)

    # ┌── 설명 ──────────────────────────────────
    # │ ▶ 이 줄이 하는 일: `글` → <code>글</code> (코드 글씨).
    # │   `([^`]+)` : ` 사이의 글(` 가 아닌 글자 1개 이상).
    # │   \1        : 규칙의 첫 번째 ( ) 에 잡힌 글.
    # └── ▼ 실행 코드 [18] ──────────────
    t = re.sub(r"`([^`]+)`", r"<code>\1</code>", t)

    # ┌── 설명 ──────────────────────────────────
    # │ ▶ 이 줄이 하는 일: **글** → <strong>글</strong> (굵게).
    # │   \* : * 글자 그대로. (* 는 규칙에서 특별한 뜻이 있어 \ 를 붙인다)
    # └── ▼ 실행 코드 [19] ──────────────
    t = re.sub(r"\*\*([^*]+)\*\*", r"<strong>\1</strong>", t)

    # ┌── 설명 ──────────────────────────────────
    # │ ▶ 이 줄이 하는 일: *글* → <em>글</em> (기울임). ** 와 헷갈리지 않게 앞뒤에 * 가 또 붙은 경우는 뺀다.
    # │   (?<!\*) : 바로 앞 글자가 * 가 아닐 때만.
    # │   (?!\*)  : 바로 뒤 글자가 * 가 아닐 때만.
    # └── ▼ 실행 코드 [20] ──────────────
    t = re.sub(r"(?<!\*)\*([^*\s][^*]*)\*(?!\*)", r"<em>\1</em>", t)

    # ┌── 설명 ──────────────────────────────────
    # │ ▶ 이 줄이 하는 일: [글](https://주소) → <a href="주소">글</a> (누르면 열리는 링크).
    # │   https?:// : http:// 또는 https:// 로 시작하는 주소만.
    # │   \2        : 두 번째 ( ) = 주소.
    # └── ▼ 실행 코드 [21] ──────────────
    t = re.sub(r"\[([^\]]+)\]\((https?://[^)\s]+)\)", r'<a href="\2">\1</a>', t)

    # ┌── 설명 ──────────────────────────────────
    # │ ▶ 이 줄이 하는 일: 바꾼 글을 돌려준다.
    # └── ▼ 실행 코드 [22] ──────────────
    return t

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: md2html 함수: 원고 한 장(마크다운 전체)을 HTML 로 바꾼다. 줄을 하나씩 보며 제목·목록·인용·문단을 구별한다.
# │   src : 원고 파일 내용 전체.
# └── ▼ 실행 코드 [23] ──────────────
def md2html(src):

    # ┌── 설명 ──────────────────────────────────
    # │ ▶ 이 줄이 하는 일: 작업용 변수 4개를 준비한다.
    # │   out  : 만든 HTML 조각을 차례로 쌓는 리스트.
    # │   para : 아직 문단으로 내보내지 않은 줄들.
    # │   lst  : 지금 열려 있는 목록 종류. "ul"(점 목록) / "ol"(번호 목록) / None(없음).
    # │   bq   : 모으는 중인 인용(> …) 줄들. None 이면 인용 중이 아님.
    # └── ▼ 실행 코드 [24] ──────────────
    out, para, lst, bq = [], [], None, None

    # ┌── 설명 ──────────────────────────────────
    # │ ▶ 이 줄이 하는 일: flush 함수: 모아 둔 문단·목록·인용을 HTML 로 마무리해 out 에 내보낸다. (flush = 비우다)
    # └── ▼ 실행 코드 [25] ──────────────
    def flush():

        # ┌── 설명 ──────────────────────────────────
        # │ ▶ 이 줄이 하는 일: 바깥 함수(md2html)의 변수 para, lst, bq 를 이 안에서 바꾸겠다는 선언.
        # │   nonlocal : 없으면 이 안에서 새 변수가 생겨 바깥 값이 안 바뀐다.
        # └── ▼ 실행 코드 [26] ──────────────
        nonlocal para, lst, bq

        # ┌── 설명 ──────────────────────────────────
        # │ ▶ 이 줄이 하는 일: 모아 둔 줄이 있으면 띄어쓰기로 이어 <p>문단</p> 으로 내보내고 비운다.
        # │   " ".join(para) : 줄들을 띄어쓰기로 이어 한 덩어리로.
        # │   out.append     : out 리스트 끝에 하나 더 넣는다.
        # └── ▼ 실행 코드 [27] ──────────────
        if para: out.append("<p>" + inline(" ".join(para)) + "</p>"); para = []

        # ┌── 설명 ──────────────────────────────────
        # │ ▶ 이 줄이 하는 일: 열린 목록이 있으면 닫는다. 예) </ul>
        # │   f"</{lst}>" : f 글자: { } 안을 값으로 바꾼다. lst="ul" → "</ul>"
        # └── ▼ 실행 코드 [28] ──────────────
        if lst: out.append(f"</{lst}>"); lst = None

        # ┌── 설명 ──────────────────────────────────
        # │ ▶ 이 줄이 하는 일: 모으는 중인 인용이 있으면 아래 세 줄로 마무리한다.
        # └── ▼ 실행 코드 [29] ──────────────
        if bq is not None:

            # ┌── 설명 ──────────────────────────────────
            # │ ▶ 이 줄이 하는 일: 인용 안의 문단마다 <p>…</p> 로 만들어 붙인다. (> 빈 줄로 문단이 나뉜다)
            # └── ▼ 실행 코드 [30] ──────────────
            body = "".join(f"<p>{inline(' '.join(x))}</p>" for x in bq if x)

            # ┌── 설명 ──────────────────────────────────
            # │ ▶ 이 줄이 하는 일: 내용이 있으면 <blockquote>(인용 상자)로 감싸 내보낸다.
            # └── ▼ 실행 코드 [31] ──────────────
            if body: out.append(f"<blockquote>{body}</blockquote>")

            # ┌── 설명 ──────────────────────────────────
            # │ ▶ 이 줄이 하는 일: 인용 모으기를 끝낸다.
            # └── ▼ 실행 코드 [32] ──────────────
            bq = None

    # ┌── 설명 ──────────────────────────────────
    # │ ▶ 이 줄이 하는 일: 원고를 한 줄씩 본다.
    # │   splitlines() : 글을 줄 단위 리스트로 나눈다.
    # └── ▼ 실행 코드 [33] ──────────────
    for raw in src.splitlines():

        # ┌── 설명 ──────────────────────────────────
        # │ ▶ 이 줄이 하는 일: 줄 끝의 공백을 지운다.
        # └── ▼ 실행 코드 [34] ──────────────
        l = raw.rstrip()

        # ┌── 설명 ──────────────────────────────────
        # │ ▶ 이 줄이 하는 일: 줄이 > 로 시작하면 인용 줄이다.
        # └── ▼ 실행 코드 [35] ──────────────
        if l.startswith(">"):

            # ┌── 설명 ──────────────────────────────────
            # │ ▶ 이 줄이 하는 일: > 를 뺀 나머지 글. 예) "> 아침은 천천히" → "아침은 천천히"
            # │   l[1:] : 두 번째 글자부터 끝까지.
            # └── ▼ 실행 코드 [36] ──────────────
            t = l[1:].strip()

            # ┌── 설명 ──────────────────────────────────
            # │ ▶ 이 줄이 하는 일: 인용이 새로 시작되면 아래 두 줄.
            # └── ▼ 실행 코드 [37] ──────────────
            if bq is None:

                # ┌── 설명 ──────────────────────────────────
                # │ ▶ 이 줄이 하는 일: 앞에 모아 둔 문단·목록을 먼저 내보낸다.
                # └── ▼ 실행 코드 [38] ──────────────
                if para or lst: flush()

                # ┌── 설명 ──────────────────────────────────
                # │ ▶ 이 줄이 하는 일: 인용 모으기 시작. 빈 문단 하나를 가진 리스트.
                # └── ▼ 실행 코드 [39] ──────────────
                bq = [[]]

            # ┌── 설명 ──────────────────────────────────
            # │ ▶ 이 줄이 하는 일: 글이 있으면 지금 인용 문단에 붙인다.
            # │   bq[-1] : 리스트의 마지막 칸.
            # └── ▼ 실행 코드 [40] ──────────────
            if t: bq[-1].append(t)

            # ┌── 설명 ──────────────────────────────────
            # │ ▶ 이 줄이 하는 일: 글이 없는 "> " 줄이면 인용 안에서 새 문단을 시작한다.
            # └── ▼ 실행 코드 [41] ──────────────
            else: bq.append([])

            # ┌── 설명 ──────────────────────────────────
            # │ ▶ 이 줄이 하는 일: 이 줄 처리는 끝. 다음 줄로.
            # └── ▼ 실행 코드 [42] ──────────────
            continue

        # ┌── 설명 ──────────────────────────────────
        # │ ▶ 이 줄이 하는 일: 인용 중이었는데 > 가 아닌 줄이 나오면 인용을 마무리한다.
        # └── ▼ 실행 코드 [43] ──────────────
        if bq is not None: flush()

        # ┌── 설명 ──────────────────────────────────
        # │ ▶ 이 줄이 하는 일: 빈 줄이면 문단이 끝난 것. 내보내고 다음 줄로.
        # └── ▼ 실행 코드 [44] ──────────────
        if not l.strip(): flush(); continue

        # ┌── 설명 ──────────────────────────────────
        # │ ▶ 이 줄이 하는 일: 체크 목록 "- [ ] 할 일" → "- ☐ 할 일"
        # └── ▼ 실행 코드 [45] ──────────────
        l = re.sub(r"^(\s*[-*]\s+)\[ \]\s*", r"\1☐ ", l)

        # ┌── 설명 ──────────────────────────────────
        # │ ▶ 이 줄이 하는 일: 체크 완료 "- [x] 한 일" → "- ☑ 한 일"
        # └── ▼ 실행 코드 [46] ──────────────
        l = re.sub(r"^(\s*[-*]\s+)\[[xX]\]\s*", r"\1☑ ", l)

        # ┌── 설명 ──────────────────────────────────
        # │ ▶ 이 줄이 하는 일: 줄이 # ~ #### + 띄어쓰기로 시작하는지(제목 줄인지) 본다.
        # │   re.match : 줄 맨 앞부터 규칙에 맞는지 본다. 맞으면 m 에 결과, 아니면 None.
        # │   #{1,4}   : # 가 1개에서 4개.
        # └── ▼ 실행 코드 [47] ──────────────
        m = re.match(r"^(#{1,4})\s+(.*)", l)

        # ┌── 설명 ──────────────────────────────────
        # │ ▶ 이 줄이 하는 일: 제목 줄이면 아래 줄 실행.
        # └── ▼ 실행 코드 [48] ──────────────
        if m:

            # ┌── 설명 ──────────────────────────────────
            # │ ▶ 이 줄이 하는 일: 모아 둔 것을 내보내고, # 개수로 제목 크기를 정해 <h1>~<h4> 로 내보낸다.
            # │   m.group(1) : 첫 번째 ( ) 에 잡힌 글 = "##" 같은 # 들.
            # │   len        : 글자 수. "##" → 2 → <h2>
            # └── ▼ 실행 코드 [49] ──────────────
            flush(); n = len(m.group(1)); out.append(f"<h{n}>{inline(m.group(2))}</h{n}>"); continue

        # ┌── 설명 ──────────────────────────────────
        # │ ▶ 이 줄이 하는 일: 줄이 목록(- 또는 * 또는 1. 1))으로 시작하는지 본다.
        # │   [-*]    : - 또는 *
        # │   \d+[.)] : 숫자 + . 또는 )  예) 1.  2)
        # └── ▼ 실행 코드 [50] ──────────────
        m = re.match(r"^\s*([-*]|\d+[.)])\s+(.*)", l)

        # ┌── 설명 ──────────────────────────────────
        # │ ▶ 이 줄이 하는 일: 목록 줄이면 아래 줄 실행.
        # └── ▼ 실행 코드 [51] ──────────────
        if m:

            # ┌── 설명 ──────────────────────────────────
            # │ ▶ 이 줄이 하는 일: 앞에 모아 둔 문단이 있으면 먼저 내보낸다.
            # └── ▼ 실행 코드 [52] ──────────────
            if para: out.append("<p>" + inline(" ".join(para)) + "</p>"); para = []

            # ┌── 설명 ──────────────────────────────────
            # │ ▶ 이 줄이 하는 일: 숫자로 시작하면 "ol"(번호 목록), 아니면 "ul"(점 목록).
            # │   A if 조건 else B : 조건이 참이면 A, 아니면 B.
            # └── ▼ 실행 코드 [53] ──────────────
            kind = "ol" if m.group(1)[0].isdigit() else "ul"

            # ┌── 설명 ──────────────────────────────────
            # │ ▶ 이 줄이 하는 일: 지금 열린 목록과 종류가 다르면 아래 두 줄로 새 목록을 연다.
            # └── ▼ 실행 코드 [54] ──────────────
            if lst != kind:

                # ┌── 설명 ──────────────────────────────────
                # │ ▶ 이 줄이 하는 일: 열린 목록이 있으면 먼저 닫는다.
                # └── ▼ 실행 코드 [55] ──────────────
                if lst: out.append(f"</{lst}>")

                # ┌── 설명 ──────────────────────────────────
                # │ ▶ 이 줄이 하는 일: <ul> 또는 <ol> 을 열고 기억한다.
                # └── ▼ 실행 코드 [56] ──────────────
                out.append(f"<{kind}>"); lst = kind

            # ┌── 설명 ──────────────────────────────────
            # │ ▶ 이 줄이 하는 일: 목록 한 칸 <li>…</li> 를 내보내고 다음 줄로.
            # └── ▼ 실행 코드 [57] ──────────────
            out.append(f"<li>{inline(m.group(2))}</li>"); continue

        # ┌── 설명 ──────────────────────────────────
        # │ ▶ 이 줄이 하는 일: --- (- 3개 이상)만 있는 줄이면 가로줄 <hr/>.
        # └── ▼ 실행 코드 [58] ──────────────
        if re.match(r"^-{3,}$", l.strip()): flush(); out.append("<hr/>"); continue

        # ┌── 설명 ──────────────────────────────────
        # │ ▶ 이 줄이 하는 일: 보통 글 줄이 나왔는데 목록이 열려 있으면 목록을 닫는다.
        # └── ▼ 실행 코드 [59] ──────────────
        if lst: out.append(f"</{lst}>"); lst = None

        # ┌── 설명 ──────────────────────────────────
        # │ ▶ 이 줄이 하는 일: 보통 글 줄은 문단에 모은다.
        # └── ▼ 실행 코드 [60] ──────────────
        para.append(l.strip())

    # ┌── 설명 ──────────────────────────────────
    # │ ▶ 이 줄이 하는 일: 마지막에 남은 것을 내보낸다.
    # └── ▼ 실행 코드 [61] ──────────────
    flush()

    # ┌── 설명 ──────────────────────────────────
    # │ ▶ 이 줄이 하는 일: HTML 조각들을 줄바꿈으로 이어 돌려준다.
    # └── ▼ 실행 코드 [62] ──────────────
    return "\n".join(out)

# ━━━━━━━━━━ 구역 4  장 모으기, 표지 ━━━━━━━━━━

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 장 목록. 한 칸 = (장 제목, 장 HTML).
# └── ▼ 실행 코드 [63] ──────────────
chapters = []

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 원고 파일을 하나씩 처리한다.
# └── ▼ 실행 코드 [64] ──────────────
for f in files:

    # ┌── 설명 ──────────────────────────────────
    # │ ▶ 이 줄이 하는 일: 원고 파일 내용 전체를 읽는다.
    # └── ▼ 실행 코드 [65] ──────────────
    src = open(f, encoding="utf-8").read()

    # ┌── 설명 ──────────────────────────────────
    # │ ▶ 이 줄이 하는 일: 원고에 남은 "(확인 필요)" "(출처 필요)" 표시를 지운다. 기획·조사 단계의 메모가 책에 찍히지 않게.
    # └── ▼ 실행 코드 [66] ──────────────
    src = re.sub(r"\((확인 필요|출처 필요)\)", "", src)

    # ┌── 설명 ──────────────────────────────────
    # │ ▶ 이 줄이 하는 일: 원고에서 첫 번째 "# 제목" 줄을 찾는다.
    # │   re.M : ^ $ 가 글 전체가 아니라 줄마다의 처음·끝을 뜻하게 한다.
    # └── ▼ 실행 코드 [67] ──────────────
    m = re.search(r"^#\s+(.+)$", src, re.M)

    # ┌── 설명 ──────────────────────────────────
    # │ ▶ 이 줄이 하는 일: (장 제목, HTML) 을 장 목록에 넣는다. 제목 줄이 없으면 파일 이름(확장자 뺌)을 제목으로 쓴다.
    # │   os.path.splitext : 이름과 확장자를 나눈다. "01-intro.md" → ("01-intro", ".md")
    # └── ▼ 실행 코드 [68] ──────────────
    chapters.append((m.group(1).strip() if m else os.path.splitext(os.path.basename(f))[0], md2html(src)))

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 표지 그림 경로. 예) …/design/cover.svg (태양이 만든다)
# └── ▼ 실행 코드 [69] ──────────────
svgp = os.path.join(book, "design", "cover.svg")

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 표지 그림이 있으면 읽고, 없으면 빈 글.
# └── ▼ 실행 코드 [70] ──────────────
svg = open(svgp, encoding="utf-8").read() if os.path.exists(svgp) else ""

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 그림 맨 앞의 <?xml …?> 머리줄을 지운다(HTML 안에 넣을 때 필요 없음).
# └── ▼ 실행 코드 [71] ──────────────
svg = re.sub(r"<\?xml[^>]*\?>", "", svg).strip()

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 그림이 없을 때 쓸 글자 표지(제목·부제·저자).
# │   f'…' : 작은따옴표 f 글자. 안에 큰따옴표(class="tc")를 쓰려고 작은따옴표로 감쌌다.
# └── ▼ 실행 코드 [72] ──────────────
text_cover = f'<div class="tc"><h1>{html.escape(title)}</h1><p>{html.escape(subtitle)}</p><p class="au">{html.escape(author)}</p></div>'

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 그림이 있으면 그림, 없으면 글자 표지.
# │   A or B : A 가 비어 있지 않으면 A, 비어 있으면 B.
# └── ▼ 실행 코드 [73] ──────────────
cover = svg or text_cover

# ━━━━━━━━━━ 구역 5  book.html 만들기 ━━━━━━━━━━

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 책의 모양(글꼴·여백·쪽 나눔)을 정하는 CSS 글. """ 부터 """ 까지 여러 줄이 한 값이다.
# │   @page{size:A5…} : 인쇄(PDF) 쪽 크기 A5, 여백 위아래 18mm·양옆 16mm.
# │   body{…}         : 본문 글꼴(한글 명조 계열), 줄 간격 1.85, 단어 중간에서 줄을 바꾸지 않음(keep-all).
# │   .cover          : 표지가 한 쪽을 다 쓰고, 다음 내용은 새 쪽에서(page-break-after).
# │   section.ch      : 장마다 새 쪽에서 시작.
# │   blockquote      : 인용 상자: 왼쪽 초록 줄 + 연한 바탕.
# │   .howto          : 화면에서만 보이는 노란 "PDF 만들기" 안내 상자.
# │   @media print    : 인쇄할 때는 안내 상자를 숨기고 여백을 없앤다.
# └── ▼ 실행 코드 [74] (아래 15줄이 한 덩어리) ────
css = """
@page{size:A5;margin:18mm 16mm}
body{font-family:"Noto Serif KR","Nanum Myeongjo","Apple SD Gothic Neo","Malgun Gothic",serif;line-height:1.85;color:#222;max-width:640px;margin:0 auto;padding:24px;word-break:keep-all}
.cover{min-height:90vh;display:flex;align-items:center;justify-content:center;page-break-after:always;text-align:center}
.cover svg{width:100%;height:auto;max-height:88vh}
.tc h1{font-size:2.2em;margin:0 0 .4em}.tc .au{margin-top:3em;color:#666}
.toc{page-break-after:always}.toc li{margin:.4em 0}
section.ch{page-break-before:always}
h1{font-size:1.6em;margin:1.2em 0 .8em}h2{font-size:1.25em;margin:1.6em 0 .6em}h3{font-size:1.08em}
blockquote{margin:1em 0;padding:.6em 1em;border-left:4px solid #8bb174;background:#f4f8f1}
code{background:#f2f2f2;padding:0 .3em;border-radius:3px}
.colophon{page-break-before:always;font-size:.9em;color:#555;margin-top:30vh}
.howto{background:#fff6e0;border:1px solid #f0c060;padding:10px 14px;border-radius:8px;font-family:sans-serif;font-size:14px}
@media print{.howto{display:none}body{max-width:none;padding:0}}
"""

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 오늘 날짜. 예) 2026-11-10 (책 끝의 "펴낸 날")
# └── ▼ 실행 코드 [75] ──────────────
today = datetime.date.today().isoformat()

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 차례 목록 HTML. 장마다 <li><a href="#ch1">장 제목</a></li>
# │   enumerate(chapters, 1) : 1 부터 번호를 붙인다.
# │   (t, _)                 : 장 제목만 쓰고 HTML 은 쓰지 않는다(_ = 안 쓰는 값).
# └── ▼ 실행 코드 [76] ──────────────
toc = "".join(f'<li><a href="#ch{i}">{html.escape(t)}</a></li>' for i, (t, _) in enumerate(chapters, 1))

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 본문 HTML. 장마다 <section class="ch" id="ch1">…</section>
# └── ▼ 실행 코드 [77] ──────────────
body = "".join(f'<section class="ch" id="ch{i}">{h}</section>' for i, (_, h) in enumerate(chapters, 1))

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 완성 HTML 한 장 전체. 안내 상자 → 표지 → 차례 → 본문 → 끝 쪽(제목·지은이·펴낸 날).
# │   <meta charset="utf-8"> : 한글이 깨지지 않게.
# │   <style>{css}</style>   : 위 css 를 넣는다.
# │   class="colophon"       : 책 맨 끝 판권 쪽.
# └── ▼ 실행 코드 [78] (아래 7줄이 한 덩어리) ────
page = f"""<!doctype html><html lang="ko"><head><meta charset="utf-8"><title>{html.escape(title)}</title><style>{css}</style></head><body>
<p class="howto">📄 PDF 만들기: <b>Ctrl+P</b>(Mac은 <b>⌘P</b>) → 대상(프린터)을 <b>PDF로 저장</b> → 저장. 이 노란 상자는 PDF에 나오지 않아요.</p>
<div class="cover">{cover}</div>
<nav class="toc"><h2>차례</h2><ol>{toc}</ol></nav>
{body}
<div class="colophon"><p><b>{html.escape(title)}</b><br>{html.escape(subtitle)}</p><p>지은이 · {html.escape(author)}<br>펴낸 날 · {today}</p></div>
</body></html>"""

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: dist/book.html 파일로 저장한다.
# │   "w" : 쓰기. 있던 파일은 새로 덮어쓴다.
# └── ▼ 실행 코드 [79] ──────────────
open(os.path.join(ddir, "book.html"), "w", encoding="utf-8").write(page)

# ━━━━━━━━━━ 구역 6  book.epub 만들기 ━━━━━━━━━━

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: EPUB 에 넣을 이 책의 고유 번호. 같은 폴더·같은 제목이면 매번 같은 번호가 나온다.
# │   uuid5 : 이름(폴더+제목)으로 정해지는 번호.
# └── ▼ 실행 코드 [80] ──────────────
uid = "urn:uuid:" + str(uuid.uuid5(uuid.NAMESPACE_URL, book + title))

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: xhtml 함수: EPUB 안의 쪽 하나(XHTML 문서)를 만든다.
# │   XHTML : EPUB 이 요구하는 엄격한 HTML. 태그를 모두 닫아야 한다.
# └── ▼ 실행 코드 [81] ──────────────
def xhtml(t, inner):

    # ┌── 설명 ──────────────────────────────────
    # │ ▶ 이 줄이 하는 일: 머리(제목·style.css 연결) + 몸통(inner) 으로 된 XHTML 글을 돌려준다.
    # └── ▼ 실행 코드 [82] ──────────────
    return f'<?xml version="1.0" encoding="utf-8"?><!DOCTYPE html><html xmlns="http://www.w3.org/1999/xhtml" xml:lang="ko" lang="ko"><head><meta charset="utf-8"/><title>{html.escape(t)}</title><link rel="stylesheet" href="style.css"/></head><body>{inner}</body></html>'

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: fix 함수: XHTML 규칙에 맞게 <hr/> 를 <hr /> 로 고친다.
# │   # XHTML 형식 맞추기 : 줄 끝의 짧은 설명(원래 있던 것).
# └── ▼ 실행 코드 [83] ──────────────
def fix(h):  # XHTML 형식 맞추기

    # ┌── 설명 ──────────────────────────────────
    # │ ▶ 이 줄이 하는 일: 바꾼 글을 돌려준다.
    # └── ▼ 실행 코드 [84] ──────────────
    return h.replace("<hr/>", "<hr />")

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: EPUB 파일 경로. 예) …/dist/book.epub
# └── ▼ 실행 코드 [85] ──────────────
ep = os.path.join(ddir, "book.epub")

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: book.epub 을 zip 으로 새로 만든다. 아래 들여쓴 줄에서 z 에 파일을 넣고, 끝나면 자동으로 닫는다.
# │   with … as z : 열고, 다 쓰면 저절로 닫아 주는 문법.
# │   EPUB        : 정해진 이름의 파일들을 zip 으로 묶은 것.
# └── ▼ 실행 코드 [86] ──────────────
with zipfile.ZipFile(ep, "w") as z:

    # ┌── 설명 ──────────────────────────────────
    # │ ▶ 이 줄이 하는 일: 첫 파일 mimetype = "application/epub+zip". EPUB 규칙상 맨 처음, 압축 없이(ZIP_STORED) 넣어야 한다.
    # └── ▼ 실행 코드 [87] ──────────────
    z.writestr(zipfile.ZipInfo("mimetype"), "application/epub+zip", compress_type=zipfile.ZIP_STORED)

    # ┌── 설명 ──────────────────────────────────
    # │ ▶ 이 줄이 하는 일: zc 함수(짧은 이름): 이름 n 으로 내용 d 를 압축해서 넣는다.
    # │   lambda : 한 줄짜리 함수를 만드는 말.
    # └── ▼ 실행 코드 [88] ──────────────
    zc = lambda n, d: z.writestr(n, d, compress_type=zipfile.ZIP_DEFLATED)

    # ┌── 설명 ──────────────────────────────────
    # │ ▶ 이 줄이 하는 일: 전자책 리더에게 "본문 목록은 OEBPS/content.opf 에 있다" 고 알려 주는 파일.
    # └── ▼ 실행 코드 [89] ──────────────
    zc("META-INF/container.xml", '<?xml version="1.0"?><container version="1.0" xmlns="urn:oasis:names:tc:opendocument:xmlns:container"><rootfiles><rootfile full-path="OEBPS/content.opf" media-type="application/oebps-package+xml"/></rootfiles></container>')

    # ┌── 설명 ──────────────────────────────────
    # │ ▶ 이 줄이 하는 일: 모양 파일. EPUB 에서는 쪽 크기(@page) 줄을 뺀다(리더가 화면에 맞춤).
    # └── ▼ 실행 코드 [90] ──────────────
    zc("OEBPS/style.css", css.replace("@page{size:A5;margin:18mm 16mm}", ""))

    # ┌── 설명 ──────────────────────────────────
    # │ ▶ 이 줄이 하는 일: items = 들어간 파일 목록, spine = 읽는 순서.
    # └── ▼ 실행 코드 [91] ──────────────
    items, spine = [], []

    # ┌── 설명 ──────────────────────────────────
    # │ ▶ 이 줄이 하는 일: 표지 쪽 내용: 그림이 <svg 로 시작하면 그림, 아니면 글자 표지.
    # └── ▼ 실행 코드 [92] ──────────────
    cov_inner = f'<div class="cover">{svg}</div>' if svg.startswith("<svg") else text_cover

    # ┌── 설명 ──────────────────────────────────
    # │ ▶ 이 줄이 하는 일: 표지 쪽을 넣고, 목록(items)과 읽는 순서(spine) 맨 앞에 적는다.
    # │   properties="svg" : 그 쪽에 SVG 그림이 들어 있다는 표시(EPUB 규칙).
    # └── ▼ 실행 코드 [93] ──────────────
    zc("OEBPS/cover.xhtml", xhtml(title, cov_inner)); items.append('<item id="cover" href="cover.xhtml" media-type="application/xhtml+xml"' + (' properties="svg"' if svg.startswith("<svg") else '') + '/>'); spine.append('<itemref idref="cover"/>')

    # ┌── 설명 ──────────────────────────────────
    # │ ▶ 이 줄이 하는 일: 전자책 차례 목록. 장마다 <li><a href="ch1.xhtml">장 제목</a></li>
    # └── ▼ 실행 코드 [94] ──────────────
    navl = "".join(f'<li><a href="ch{i}.xhtml">{html.escape(t)}</a></li>' for i, (t, _) in enumerate(chapters, 1))

    # ┌── 설명 ──────────────────────────────────
    # │ ▶ 이 줄이 하는 일: 차례 쪽을 넣는다. epub:type="toc" 가 리더의 "목차" 단추와 연결된다.
    # └── ▼ 실행 코드 [95] ──────────────
    zc("OEBPS/nav.xhtml", f'<?xml version="1.0" encoding="utf-8"?><!DOCTYPE html><html xmlns="http://www.w3.org/1999/xhtml" xmlns:epub="http://www.idpf.org/2007/ops" xml:lang="ko" lang="ko"><head><meta charset="utf-8"/><title>차례</title></head><body><nav epub:type="toc" id="toc"><h2>차례</h2><ol>{navl}</ol></nav></body></html>')

    # ┌── 설명 ──────────────────────────────────
    # │ ▶ 이 줄이 하는 일: 차례 쪽을 목록과 읽는 순서에 적는다.
    # └── ▼ 실행 코드 [96] ──────────────
    items.append('<item id="nav" href="nav.xhtml" media-type="application/xhtml+xml" properties="nav"/>'); spine.append('<itemref idref="nav"/>')

    # ┌── 설명 ──────────────────────────────────
    # │ ▶ 이 줄이 하는 일: 장마다 아래 두 줄.
    # └── ▼ 실행 코드 [97] ──────────────
    for i, (t, h) in enumerate(chapters, 1):

        # ┌── 설명 ──────────────────────────────────
        # │ ▶ 이 줄이 하는 일: 장 하나를 ch1.xhtml, ch2.xhtml … 로 넣는다.
        # └── ▼ 실행 코드 [98] ──────────────
        zc(f"OEBPS/ch{i}.xhtml", xhtml(t, fix(h)))

        # ┌── 설명 ──────────────────────────────────
        # │ ▶ 이 줄이 하는 일: 그 장을 목록과 읽는 순서에 적는다.
        # └── ▼ 실행 코드 [99] ──────────────
        items.append(f'<item id="ch{i}" href="ch{i}.xhtml" media-type="application/xhtml+xml"/>'); spine.append(f'<itemref idref="ch{i}"/>')

    # ┌── 설명 ──────────────────────────────────
    # │ ▶ 이 줄이 하는 일: style.css 도 목록에 적는다.
    # └── ▼ 실행 코드 [100] ─────────────
    items.append('<item id="css" href="style.css" media-type="text/css"/>')

    # ┌── 설명 ──────────────────────────────────
    # │ ▶ 이 줄이 하는 일: 지금 시각(세계 표준시). 예) 2026-11-10T02:15:00Z (EPUB 필수 정보 "고친 때")
    # └── ▼ 실행 코드 [101] ─────────────
    mod = datetime.datetime.now(datetime.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")

    # ┌── 설명 ──────────────────────────────────
    # │ ▶ 이 줄이 하는 일: 책 정보(번호·제목·저자·언어 ko·고친 때) + 파일 목록 + 읽는 순서를 담은 핵심 파일.
    # │   dc:title / dc:creator : 제목 / 저자.
    # └── ▼ 실행 코드 [102] ─────────────
    zc("OEBPS/content.opf", f'<?xml version="1.0" encoding="utf-8"?><package xmlns="http://www.idpf.org/2007/opf" version="3.0" unique-identifier="bookid" xml:lang="ko"><metadata xmlns:dc="http://purl.org/dc/elements/1.1/"><dc:identifier id="bookid">{uid}</dc:identifier><dc:title>{html.escape(title)}</dc:title><dc:creator>{html.escape(author)}</dc:creator><dc:language>ko</dc:language><meta property="dcterms:modified">{mod}</meta></metadata><manifest>{"".join(items)}</manifest><spine>{"".join(spine)}</spine></package>')

# ━━━━━━━━━━ 구역 7  결과 알림 (Python 끝) ━━━━━━━━━━

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 본문 글자 수(태그와 공백을 뺀 수)를 센다.
# │   <[^>]+> : HTML 태그.
# │   \s      : 공백·줄바꿈.
# └── ▼ 실행 코드 [103] ─────────────
n = sum(len(re.sub(r"\s", "", re.sub(r"<[^>]+>", "", h))) for _, h in chapters)

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 결과를 찍는다. 예) ✅ 제본 완료: 「느린 아침의 기술」 5개 장, 약 12,345자
# │   {n:,} : 천 단위 쉼표.
# └── ▼ 실행 코드 [104] ─────────────
print(f"✅ 제본 완료: 「{title}」 {len(chapters)}개 장, 약 {n:,}자")

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: HTML 파일 위치를 찍는다.
# └── ▼ 실행 코드 [105] ─────────────
print(f"   📄 {ddir}/book.html")

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: EPUB 파일 위치를 찍는다.
# └── ▼ 실행 코드 [106] ─────────────
print(f"   📱 {ddir}/book.epub  ← 전자책 리더·리디·교보 eBook 등록용")

PY

# ━━━━━━━━━━ 구역 8  book.pdf 만들기 (bash) ━━━━━━━━━━

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: dist 폴더 경로를 DIST 에 담고, 예전 PDF 는 지운다(실패했을 때 옛 PDF 가 남지 않게).
# │   rm -f : 파일 지우기. -f = 없어도 오류 없음.
# └── ▼ 실행 코드 [107] ─────────────
DIST="$BOOK_DIR/dist"; rm -f "$DIST/book.pdf"

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: Windows Edge 위치를 담을 변수. 처음엔 비워 둔다.
# └── ▼ 실행 코드 [108] ─────────────
EDGE=""

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: Edge 가 있을 만한 두 위치를 차례로 본다. (/mnt/c = 우분투에서 본 Windows C: 드라이브)
# └── ▼ 실행 코드 [109] ─────────────
for p in "/mnt/c/Program Files (x86)/Microsoft/Edge/Application/msedge.exe" "/mnt/c/Program Files/Microsoft/Edge/Application/msedge.exe"; do

  # ┌── 설명 ──────────────────────────────────
  # │ ▶ 이 줄이 하는 일: 그 위치에 파일이 있으면 EDGE 에 담고 찾기를 멈춘다.
  # └── ▼ 실행 코드 [110] ─────────────
  [ -f "$p" ] && EDGE="$p" && break

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 위 for / while 반복의 끝
# └── ▼ 실행 코드 [111] ─────────────
done

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: Edge 를 찾았으면 Edge 로 PDF 를 만든다(아래 3줄).
# └── ▼ 실행 코드 [112] ─────────────
if [ -n "$EDGE" ]; then

  # ┌── 설명 ──────────────────────────────────
  # │ ▶ 이 줄이 하는 일: Windows 쪽 임시 폴더를 만들고 book.html 을 복사한다.
  # │   Edge 는 Windows 프로그램이라 Windows 폴더의 파일만 잘 연다.
  # │   W        : Windows 임시 폴더 = C:\Users\Public\ai-publisher-tmp
  # │   mkdir -p : 폴더 만들기. -p = 이미 있어도 괜찮음.
  # └── ▼ 실행 코드 [113] ─────────────
  W=/mnt/c/Users/Public/ai-publisher-tmp; mkdir -p "$W" && cp "$DIST/book.html" "$W/book.html" && rm -f "$W/book.pdf"

  # ┌── 설명 ──────────────────────────────────
  # │ ▶ 이 줄이 하는 일: Edge 를 창 없이(--headless) 띄워 book.html 을 PDF 로 인쇄한다. 120초가 넘으면 멈춘다.
  # │   (줄 끝 \ = 다음 줄과 한 명령)
  # │   timeout 120            : 120초 제한.
  # │   --headless             : 화면에 창을 띄우지 않는다.
  # │   --disable-gpu          : 그래픽 카드를 쓰지 않는다(창 없을 때 오류 방지).
  # │   --no-pdf-header-footer : PDF 쪽 위아래에 날짜·주소가 찍히지 않게.
  # │   --print-to-pdf=…       : 이 위치에 PDF 로 저장.
  # │   'file:///C:/…'         : 열 HTML 파일 주소(Windows 형식).
  # └── ▼ 실행 코드 [114] (아래 2줄이 한 덩어리) ────
  timeout 120 "$EDGE" --headless --disable-gpu --no-pdf-header-footer \
    --print-to-pdf='C:\Users\Public\ai-publisher-tmp\book.pdf' 'file:///C:/Users/Public/ai-publisher-tmp/book.html' >/dev/null 2>&1

  # ┌── 설명 ──────────────────────────────────
  # │ ▶ 이 줄이 하는 일: PDF 가 만들어졌으면(크기 0 이 아니면) dist 폴더로 가져온다.
  # │   -s : 파일이 있고 크기가 0 보다 크면 참.
  # └── ▼ 실행 코드 [115] ─────────────
  [ -s "$W/book.pdf" ] && cp "$W/book.pdf" "$DIST/book.pdf"

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 조건이 거짓일 때 실행할 부분의 시작
# └── ▼ 실행 코드 [116] ─────────────
else

  # ┌── 설명 ──────────────────────────────────
  # │ ▶ 이 줄이 하는 일: Edge 가 없으면(리눅스 PC 등) Chromium·Chrome 을 차례로 찾는다.
  # └── ▼ 실행 코드 [117] ─────────────
  for b in chromium chromium-browser google-chrome /opt/pw-browsers/chromium-*/chrome-linux/chrome; do

    # ┌── 설명 ──────────────────────────────────
    # │ ▶ 이 줄이 하는 일: 그 이름의 명령이 있거나 실행 파일이면 아래로.
    # │   [ -x "$b" ] : 실행할 수 있는 파일이면 참.
    # └── ▼ 실행 코드 [118] ─────────────
    if command -v "$b" >/dev/null 2>&1 || [ -x "$b" ]; then

      # ┌── 설명 ──────────────────────────────────
      # │ ▶ 이 줄이 하는 일: Chromium 으로 같은 방식으로 PDF 를 만든다.
      # │   --no-sandbox : 보호 상자 기능을 끈다(일부 리눅스에서 필요).
      # └── ▼ 실행 코드 [119] (아래 2줄이 한 덩어리) ────
      timeout 120 "$b" --headless --no-sandbox --disable-gpu --no-pdf-header-footer \
        --print-to-pdf="$DIST/book.pdf" "file://$DIST/book.html" >/dev/null 2>&1

      # ┌── 설명 ──────────────────────────────────
      # │ ▶ 이 줄이 하는 일: 하나로 만들었으면 더 찾지 않는다.
      # └── ▼ 실행 코드 [120] ─────────────
      break

    # ┌── 설명 ──────────────────────────────────
    # │ ▶ 이 줄이 하는 일: 위 if 블록의 끝 (if 를 거꾸로 쓴 말)
    # └── ▼ 실행 코드 [121] ─────────────
    fi

  # ┌── 설명 ──────────────────────────────────
  # │ ▶ 이 줄이 하는 일: 위 for / while 반복의 끝
  # └── ▼ 실행 코드 [122] ─────────────
  done

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 위 if 블록의 끝 (if 를 거꾸로 쓴 말)
# └── ▼ 실행 코드 [123] ─────────────
fi

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: PDF 가 생겼는지 보고 결과를 알린다.
# └── ▼ 실행 코드 [124] ─────────────
if [ -s "$DIST/book.pdf" ]; then

  # ┌── 설명 ──────────────────────────────────
  # │ ▶ 이 줄이 하는 일: PDF 위치를 찍는다.
  # └── ▼ 실행 코드 [125] ─────────────
  echo "   📕 $DIST/book.pdf"

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 조건이 거짓일 때 실행할 부분의 시작
# └── ▼ 실행 코드 [126] ─────────────
else

  # ┌── 설명 ──────────────────────────────────
  # │ ▶ 이 줄이 하는 일: PDF 를 못 만들었으면 직접 만드는 방법을 알린다(브라우저에서 인쇄 → PDF로 저장).
  # └── ▼ 실행 코드 [127] ─────────────
  echo "   (PDF 건너뜀 — book.html을 열어 인쇄 → PDF로 저장하세요)"

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 위 if 블록의 끝 (if 를 거꾸로 쓴 말)
# └── ▼ 실행 코드 [128] ─────────────
fi
PUBLISHER_FILE_8_END

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 파일 ~/my-publisher/staff.yml 를 만든다. (직원 명부(관리 화면이 읽어 책상·자리를 만듦))
# │   아래 137줄이 그 파일 내용 그대로이고, PUBLISHER_FILE_9_END 줄에서 끝난다.
# └── ▼ 실행 코드 [20] (아래 139줄이 한 덩어리) ────
cat > "$P/staff.yml" <<'PUBLISHER_FILE_9_END'
# [1] 역할
#     staff.yml — 직원 명부. 출판사 사람들을 한곳에 적어 둔다.
#     관리 화면(publisher-dashboard)은 이 파일을 읽어 사무실에 책상, 회의실에 자리, 직원 현황 표를 자동으로 만든다.
#     쭌(Claude Code)이 직원을 부를 때 쓰는 역할 설명은 .claude/agents/<agent>.md 에 있고, 이 파일의 agent 값이 그 파일 이름이다.
#
#     새 직원 채용 방법 ("채용은 Pull Request로")
#       1) .claude/agents/<agent>.md 에 역할 설명을 만든다 (tools 에 SendMessage 꼭 포함)
#       2) 아래 staff 목록에 한 줄을 추가한다 (name 은 영문 소문자만)
#       3) GitHub 에 PR 을 올리면 CI 가 명부를 검사하고, 합치면 서버에 배포된다
#
#     YAML 이란: "이름: 값" 모양으로 설정을 적는 글 형식. 들여쓰기(띄어쓰기 2칸)로 무엇이 무엇 안에 들어가는지 나타낸다.
#       # 뒤는 설명(주석)이라 프로그램이 읽지 않는다.
#
# [2] 받는 것 → 내보내는 것
#     받는 것    : (사람이 직접 고쳐 쓰는 파일)
#     내보내는 것: 관리 화면이 읽는 직원 목록 6명(편집장 1 + 직원 5)
#                  예) 사무실 화면의 책상 "민준 · 기획", 회의실 자리, 색 #5b8cff 이름표
#
# [3] 앞뒤 파일
#     (이 파일)  →  관리 화면 StaffRegistry.java 가 읽음 (출근 로그: "직원 명부 5명을 읽었어요")
#                →  agent 값 → .claude/agents/<agent>.md (그 직원의 역할 설명)
#                →  CI(tepo/templates/ci.yml) 가 PR 마다 StaffRegistryTest 로 검사
#
# [4] 구역 목록
#     구역 1  lead   편집장(팀장) 한 명
#     구역 2  staff  직원 목록 (한 줄 = 한 사람)
#
# [5] 먼저 알 용어
#     YAML, 이름: 값, 들여쓰기, - (목록의 한 칸), { … } (한 줄로 쓴 묶음), "따옴표", 색 코드 #rrggbb
#
# [6] 읽는 순서
#     구역 1 → 구역 2. 직원 한 줄을 읽을 때는 name → korean → role → agent → team → color 순서.
#
# [7] 다 읽고 확인
#     - 직원 "하늘(디자인)" 을 새로 넣으려면 이 파일 말고 어떤 파일을 꼭 만들어야 하는가? (.claude/agents/<agent>.md)
#     - team 을 ops 로 적은 직원은 책 주문 때 불리는가? (아니다. ops 는 서버·배포 요청 때만)
#
# [0] 코드만 모아 보기 — 이 파일에서 실제로 읽히는 설정 줄 전체(# 설명 줄 제외). 아래 본문에서 ▼ 실행 코드 [번호] 를 찾으면 그 줄의 설명이 있다.
#     [1] lead:
#     [2]   name: team-lead
#     [3]   korean: 쭌
#     [4]   role: 편집장
#     [5]   color: "#f08a5d"
#     [6] staff:
#     [7]   - { name: minjun,  korean: 민준, role: 기획,       agent: planner,    team: book, color: "#5b8cff" }
#     [8]   - { name: jihun,   korean: 지훈, role: 자료 조사,  agent: researcher, team: book, color: "#3fbf8f" }
#     [9]   - { name: seoyeon, korean: 서연, role: 집필,       agent: writer,     team: book, color: "#b07cff" }
#     [10]   - { name: taeyang, korean: 태양, role: 교정·표지,  agent: editor,     team: book, color: "#ffb547" }
#     [11]   - { name: tepo,    korean: 테포, role: 배포·서버,  agent: devops,     team: ops,  color: "#3ec6e0" }

# ━━━━━━━━━━ 구역 1  lead (편집장) ━━━━━━━━━━

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 편집장(팀장) 한 명의 정보를 아래에 적는다. 편집장 = 쭌 = Claude Code 그 자체.
# │   lead : 팀을 이끄는 사람. 사장님 말을 직접 받는 칸(쭌 칸)의 주인.
# │   :    : 이름과 값 사이의 구분. 값이 비어 있으면 아래 들여쓴 줄들이 그 값이 된다.
# └── ▼ 실행 코드 [1] ───────────────
lead:

  # ┌── 설명 ──────────────────────────────────
  # │ ▶ 이 줄이 하는 일: 편집장의 영문 이름(시스템 이름).
  # │   name      : 프로그램이 쓰는 이름. Claude Code 팀 기능에서 팀장 이름이 team-lead 로 정해져 있어 그대로 맞춘다.
  # │   team-lead : 바꾸면 관리 화면이 쭌의 대화 기록을 찾지 못한다.
  # └── ▼ 실행 코드 [2] ───────────────
  name: team-lead

  # ┌── 설명 ──────────────────────────────────
  # │ ▶ 이 줄이 하는 일: 화면에 보일 한글 이름.
  # │   korean : 사무실·회의실·대화방에 보이는 이름.
  # └── ▼ 실행 코드 [3] ───────────────
  korean: 쭌

  # ┌── 설명 ──────────────────────────────────
  # │ ▶ 이 줄이 하는 일: 화면에 보일 직책.
  # │   role : 이름 옆에 붙는 직책 글자. 예) "쭌 · 편집장"
  # └── ▼ 실행 코드 [4] ───────────────
  role: 편집장

  # ┌── 설명 ──────────────────────────────────
  # │ ▶ 이 줄이 하는 일: 쭌의 이름표·책상 색.
  # │   color     : 색. # 뒤 6자리 = 빨강·초록·파랑 세기(16진수 두 자리씩).
  # │   "#f08a5d" : 주황색. 따옴표가 꼭 필요하다. 따옴표가 없으면 # 뒤를 주석으로 읽어 값이 사라진다.
  # └── ▼ 실행 코드 [5] ───────────────
  color: "#f08a5d"

# ━━━━━━━━━━ 구역 2  staff (직원 목록) ━━━━━━━━━━

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 직원 목록. 아래 "- " 로 시작하는 줄 하나가 직원 한 사람이다.
# │   staff           : 직원들.
# │   -               : 목록의 한 칸.
# │   { 이름: 값, … } : 여러 "이름: 값" 을 한 줄에 묶어 쓴 모양. 칸을 맞추려고 띄어쓰기를 더 넣어도 된다.
# └── ▼ 실행 코드 [6] ───────────────
staff:

  # ┌── 설명 ──────────────────────────────────
  # │ ▶ 이 줄이 하는 일: 직원 민준 — 기획 담당.
  # │   name: minjun     : 영문 소문자 이름. 쭌이 직원을 부를 때 이 이름을 쓰고, 관리 화면도 이 이름으로 대화 기록을 찾는다.
  # │   korean: 민준     : 화면에 보일 한글 이름.
  # │   role: 기획       : 직책. 목차·장별 계획을 세운다.
  # │   agent: planner   : 역할 설명 파일 이름 → .claude/agents/planner.md
  # │   team: book       : 팀. book = 책 만드는 팀. 쭌이 책 주문을 받으면 이 팀을 부른다.
  # │   color: "#5b8cff" : 파란색 이름표.
  # └── ▼ 실행 코드 [7] ───────────────
  - { name: minjun,  korean: 민준, role: 기획,       agent: planner,    team: book, color: "#5b8cff" }

  # ┌── 설명 ──────────────────────────────────
  # │ ▶ 이 줄이 하는 일: 직원 지훈 — 자료 조사 담당.
  # │   agent: researcher : → .claude/agents/researcher.md
  # │   team: book        : 책 만드는 팀.
  # │   color: "#3fbf8f"  : 초록색.
  # └── ▼ 실행 코드 [8] ───────────────
  - { name: jihun,   korean: 지훈, role: 자료 조사,  agent: researcher, team: book, color: "#3fbf8f" }

  # ┌── 설명 ──────────────────────────────────
  # │ ▶ 이 줄이 하는 일: 직원 서연 — 집필(원고 쓰기) 담당.
  # │   agent: writer    : → .claude/agents/writer.md
  # │   team: book       : 책 만드는 팀.
  # │   color: "#b07cff" : 보라색.
  # └── ▼ 실행 코드 [9] ───────────────
  - { name: seoyeon, korean: 서연, role: 집필,       agent: writer,     team: book, color: "#b07cff" }

  # ┌── 설명 ──────────────────────────────────
  # │ ▶ 이 줄이 하는 일: 직원 태양 — 교정·표지 담당.
  # │   agent: editor    : → .claude/agents/editor.md
  # │   team: book       : 책 만드는 팀.
  # │   color: "#ffb547" : 노란색.
  # └── ▼ 실행 코드 [10] ──────────────
  - { name: taeyang, korean: 태양, role: 교정·표지,  agent: editor,     team: book, color: "#ffb547" }

  # ┌── 설명 ──────────────────────────────────
  # │ ▶ 이 줄이 하는 일: 직원 테포 — 배포·서버 담당.
  # │   agent: devops    : → .claude/agents/devops.md
  # │   team: ops        : ops = 서버·배포 팀. 책 주문 때는 부르지 않고, 사장님이 배포를 요청할 때만 부른다.
  # │   color: "#3ec6e0" : 하늘색.
  # └── ▼ 실행 코드 [11] ──────────────
  - { name: tepo,    korean: 테포, role: 배포·서버,  agent: devops,     team: ops,  color: "#3ec6e0" }
PUBLISHER_FILE_9_END

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 파일 ~/my-publisher/start.sh 를 만든다. (출판사 출근.)
# │   아래 291줄이 그 파일 내용 그대로이고, PUBLISHER_FILE_10_END 줄에서 끝난다.
# └── ▼ 실행 코드 [21] (아래 293줄이 한 덩어리) ────
cat > "$P/start.sh" <<'PUBLISHER_FILE_10_END'
#!/bin/bash
# [1] 역할
#     start.sh — 출판사 출근.
#     우분투 창에서 `출근` 을 입력하면 실행된다(설치가 ~/.bashrc 에 alias 출근='bash ~/my-publisher/start.sh' 를 넣어 둠).
#     tmux(한 창을 여러 칸으로 나누는 프로그램)를 열고, 왼쪽 큰 칸에서 Claude Code(편집장 쭌)를 켠다.
#     쭌이 직원(민준·지훈·서연·태양)을 부르면 오른쪽에 직원 칸이 자동으로 생긴다.
#     창 1(dashboard)에서는 PC 브라우저용 관리 화면(http://localhost:8080)이 함께 켜진다.
#     사장님 말이 들어오는 길(채널):
#       - 관리 화면 대화방 : 공식 채널 플러그인 fakechat (항상 켬)
#       - 휴대폰 텔레그램  : 텔레그램 토큰을 설정해 두었으면 함께 켬 (선택)
#     빠져나오기: Ctrl+B 를 눌렀다 떼고 D (출판사는 계속 일함) · 다시 보기: 출근
#     맨 윗줄 #!/bin/bash : "쉬뱅(shebang)". 이 파일을 /bin/bash 프로그램으로 실행하라는 표시.
#       #! 는 파일 맨 처음에만 쓰며, 뒤에 적힌 프로그램(위치)으로 이 파일을 실행한다.
#
# [2] 받는 것 → 내보내는 것
#     받는 것    : 환경변수 CHANNEL(보통 비어 있음), 파일 ~/.claude/channels/telegram/.env 가 있는지
#     내보내는 것: tmux 세션 "publisher"
#                  창 0 "team"      — 칸 0 에서 claude 실행, 칸 위 이름표 "쭌 편집장 (사장님 말을 받는 칸)"
#                  창 1 "dashboard" — java -jar publisher-dashboard.jar (http://localhost:8080)
#
# [3] 앞뒤 파일
#     ~/.bashrc 의 alias 출근  →  (이 파일)  →  connect.sh (연결 확인 도우미, 뒤에서 실행)
#                                          →  claude 가 읽는 CLAUDE.md · .claude/settings.json
#                                          →  dashboard/publisher-dashboard.jar (관리 화면)
#
# [4] 구역 목록
#     구역 1  변수 정하기       P, SESSION, CHANNEL
#     구역 2  이미 출근했으면   그 화면으로 들어가고 끝
#     구역 3  tmux 화면 만들기  세션·옵션·이름표
#     구역 4  쭌 켜기           claude 실행 + connect.sh
#     구역 5  관리 화면 켜기    java -jar
#     구역 6  화면 보여 주기    tmux attach
#
# [5] 먼저 알 용어
#     변수, 환경변수, $, "따옴표", [ ] 검사, if/then/fi, &&, exec, tmux(세션·창·칸), 2>/dev/null
#
# [6] 읽는 순서
#     구역 1 → 2 → 3 → 4 → 5 → 6 (위에서 아래로)
#
# [7] 다 읽고 확인
#     - 텔레그램 토큰을 설정하지 않았으면 쭌은 어떤 채널만 듣는가? (fakechat 하나)
#     - 이미 출근해 있는데 `출근` 을 또 입력하면 새 쭌이 하나 더 생기는가? (아니다. 구역 2 에서 기존 화면에 들어가고 끝난다)
#
# [0] 코드만 모아 보기 — 이 파일에서 실제로 실행되는 줄 전체. 아래 본문에서 ▼ 실행 코드 [번호] 를 찾으면 그 줄의 설명이 있다.
#     [1] P=~/my-publisher
#     [2] SESSION=publisher
#     [3] if [ -z "$CHANNEL" ]; then
#     [4]   CHANNEL="plugin:fakechat@claude-plugins-official"
#     [5]   [ -f ~/.claude/channels/telegram/.env ] && CHANNEL="$CHANNEL plugin:telegram@claude-plugins-official"
#     [6] fi
#     [7] if tmux has-session -t "$SESSION" 2>/dev/null; then
#     [8]   [ -n "$TMUX" ] && exec tmux switch-client -t "$SESSION"
#     [9]   exec tmux attach -t "$SESSION"
#     [10] fi
#     [11] tmux -f /dev/null new-session -d -s "$SESSION" -n team -x "${COLUMNS:-200}" -y "${LINES:-50}" -c "$P"
#     [12] tmux set-option -t "$SESSION" mouse on
#     [13] tmux set-option -g focus-events on   # 직원 칸에 tmux 안내 문구가 끼지 않게
#     [14] tmux set-option -t "$SESSION" pane-border-status top
#     [15] tmux set-option -t "$SESSION" pane-border-format " #{?#{@label},#{@label},#{pane_title}} "
#     [16] tmux set-option -p -t "$SESSION:team.0" @label "쭌 편집장 (사장님 말을 받는 칸)"
#     [17] tmux send-keys -t "$SESSION:team.0" "cd $P && MCP_TIMEOUT=60000 claude --channels $CHANNEL --model sonnet -…
#     [18] case "$CHANNEL" in *fakechat*) setsid bash "$P/connect.sh" "$SESSION:team.0" >/dev/null 2>&1 < /dev/null & …
#     [19] JAR="$P/dashboard/publisher-dashboard.jar"
#     [20] if command -v java >/dev/null 2>&1 && [ -f "$JAR" ]; then
#     [21]   tmux new-window -d -t "$SESSION" -n dashboard -c "$P" "java -jar '$JAR'; echo '관리 화면이 꺼졌어요. Ente…
#     [22] fi
#     [23] [ -n "$TMUX" ] && exec tmux switch-client -t "$SESSION"
#     [24] exec tmux attach -t "$SESSION"

# ━━━━━━━━━━ 구역 1  변수 정하기 ━━━━━━━━━━

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 출판사 폴더 위치를 P 라는 이름에 담는다. 아래에서 $P 로 꺼내 쓴다.
# │   P              : 변수(값을 담아 두는 이름). Publisher 의 첫 글자.
# │   =              : 오른쪽 값을 왼쪽 이름에 넣는다. bash 에서는 = 양옆에 띄어쓰기를 하면 안 된다.
# │   ~              : 내 홈 폴더.  예) /home/khbs_d_0
# │   ~/my-publisher : 결과 예) /home/khbs_d_0/my-publisher
# └── ▼ 실행 코드 [1] ───────────────
P=~/my-publisher

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: tmux 세션 이름을 "publisher" 로 정한다.
# │   SESSION   : 변수 이름. tmux 에서 "세션" = 창 여러 개를 묶은 작업 단위.
# │   publisher : 세션 이름. `tmux ls` 로 보면 이 이름이 나온다.
# └── ▼ 실행 코드 [2] ───────────────
SESSION=publisher

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: CHANNEL 변수가 비어 있을 때만 아래 두 줄로 채운다.
# │   (CHANNEL 을 미리 정해 두고 출근하면 그 값을 그대로 쓴다. 보통은 비어 있다.)
# │   if         : "만약 ~이면". 아래 then ~ fi 사이를 조건이 참일 때만 실행한다.
# │   [ ... ]    : 조건 검사. 대괄호 안쪽 양옆에 띄어쓰기가 꼭 필요하다.
# │   -z         : 글자 길이가 0(비어 있음)이면 참.
# │   "$CHANNEL" : CHANNEL 변수의 값. 따옴표는 값이 비어 있어도 검사가 깨지지 않게 한다.
# │   ;          : 한 줄에 명령 두 개를 이어 쓸 때 쓰는 구분표.
# │   then       : 조건이 참일 때 실행할 부분의 시작.
# └── ▼ 실행 코드 [3] ───────────────
if [ -z "$CHANNEL" ]; then

  # ┌── 설명 ──────────────────────────────────
  # │ ▶ 이 줄이 하는 일: 쭌이 들을 채널에 관리 화면 대화방(fakechat)을 넣는다. 항상 들어간다.
  # │   CHANNEL                  : 쭌(claude)에게 넘길 채널 목록을 담는 변수.
  # │   plugin:                  : "플러그인으로 된 채널"이라는 앞말.
  # │   fakechat                 : 관리 화면 대화방과 쭌을 잇는 공식 플러그인 이름.
  # │   @claude-plugins-official : 이 플러그인이 들어 있는 공식 장터(마켓플레이스) 이름.
  # └── ▼ 실행 코드 [4] ───────────────
  CHANNEL="plugin:fakechat@claude-plugins-official"

  # ┌── 설명 ──────────────────────────────────
  # │ ▶ 이 줄이 하는 일: 텔레그램 토큰 파일이 있으면 채널 목록 뒤에 텔레그램을 덧붙인다.
  # │   [ -f 파일 ]                      : 그 파일이 있으면 참. (-f = 보통 파일인가)
  # │   ~/.claude/channels/telegram/.env : `/telegram:configure` 로 저장한 봇 토큰 파일.
  # │   &&                               : 앞 검사가 참일 때만 뒤 명령을 실행한다.
  # │   "$CHANNEL plugin:telegram@…"     : 원래 값 + 띄어쓰기 + 텔레그램.
  # │                                      결과 예) "plugin:fakechat@… plugin:telegram@…"
  # └── ▼ 실행 코드 [5] ───────────────
  [ -f ~/.claude/channels/telegram/.env ] && CHANNEL="$CHANNEL plugin:telegram@claude-plugins-official"

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 위 if 블록의 끝 (if 를 거꾸로 쓴 말)
# └── ▼ 실행 코드 [6] ───────────────
fi

# ━━━━━━━━━━ 구역 2  이미 출근했으면 그 화면으로 들어가기만 함 ━━━━━━━━━━

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: "publisher" 세션이 이미 있는지(이미 출근했는지) 확인한다.
# │   tmux          : 화면을 칸으로 나누고, 창을 닫아도 프로그램을 계속 돌려 주는 프로그램.
# │   has-session   : "이 세션이 있나?" 하고 묻는 tmux 명령. 있으면 성공, 없으면 실패.
# │   -t "$SESSION" : 대상(target)을 정한다. 여기서는 publisher.
# │   2>/dev/null   : 오류 글(2번 출력)을 버린다. 세션이 없을 때 나오는 "can't find session" 글을 안 보이게 한다.
# └── ▼ 실행 코드 [7] ───────────────
if tmux has-session -t "$SESSION" 2>/dev/null; then

  # ┌── 설명 ──────────────────────────────────
  # │ ▶ 이 줄이 하는 일: 지금 이미 tmux 안에 있으면, 새로 붙지 않고 publisher 세션으로 화면만 바꾼다.
  # │   -n "$TMUX"    : TMUX 변수가 비어 있지 않으면 참. tmux 안에서 실행 중이면 tmux 가 이 변수를 채워 둔다.
  # │   exec          : 지금 스크립트를 뒤 명령으로 바꿔치기한다. 뒤 명령이 끝나면 스크립트도 끝난다.
  # │   switch-client : 지금 보고 있는 화면을 다른 세션으로 바꾸는 tmux 명령.
  # └── ▼ 실행 코드 [8] ───────────────
  [ -n "$TMUX" ] && exec tmux switch-client -t "$SESSION"

  # ┌── 설명 ──────────────────────────────────
  # │ ▶ 이 줄이 하는 일: (tmux 밖이면) 이미 있는 publisher 세션 화면에 들어간다. 여기서 스크립트가 끝난다.
  # │   attach : 떠 있는 세션에 내 창을 붙인다. 빠져나올 때는 Ctrl+B 를 누른 뒤 D.
  # └── ▼ 실행 코드 [9] ───────────────
  exec tmux attach -t "$SESSION"

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 위 if 블록의 끝 (if 를 거꾸로 쓴 말)
# └── ▼ 실행 코드 [10] ──────────────
fi

# ━━━━━━━━━━ 구역 3  tmux 화면 만들기 ━━━━━━━━━━

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 새 tmux 세션 publisher 를 만들고, 첫 창 이름을 team 으로 정한다.
# │   -f /dev/null         : 설정 파일로 빈 파일을 쓴다. 사용자의 ~/.tmux.conf 를 읽지 않으므로,
# │                          그 파일에 오류가 있어도 출근이 막히지 않는다. (필요한 설정은 아래 set-option 들이 대신 넣는다)
# │                          tmux 서버는 처음 시작할 때만 설정 파일을 읽는다.
# │   new-session          : 새 세션을 만든다.
# │   -d                   : detached. 만들기만 하고 아직 화면에 띄우지 않는다(맨 아래 attach 에서 띄운다).
# │   -s "$SESSION"        : 세션 이름 = publisher.
# │   -n team              : 첫 번째 창(0번)의 이름 = team. 쭌과 직원 칸이 이 창에 생긴다.
# │   -x "${COLUMNS:-200}" : 화면 가로 칸 수. COLUMNS 변수가 비어 있으면 200. (${이름:-기본값} = 비었으면 기본값)
# │   -y "${LINES:-50}"    : 화면 세로 줄 수. LINES 가 비어 있으면 50.
# │   -c "$P"              : 처음 위치(폴더) = ~/my-publisher.
# └── ▼ 실행 코드 [11] ──────────────
tmux -f /dev/null new-session -d -s "$SESSION" -n team -x "${COLUMNS:-200}" -y "${LINES:-50}" -c "$P"

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 마우스를 켠다. 칸을 클릭해 고르고, 휠로 지난 글을 올려 볼 수 있다.
# │   set-option    : tmux 설정을 바꾸는 명령.
# │   -t "$SESSION" : publisher 세션에만 적용.
# │   mouse on      : 마우스 사용 = 켬.
# └── ▼ 실행 코드 [12] ──────────────
tmux set-option -t "$SESSION" mouse on

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 칸을 오갈 때 프로그램에 "포커스가 바뀌었다"를 알려 준다.
# │   -g            : global. 이 tmux 서버의 모든 세션에 적용.
# │   focus-events  : 이 설정이 꺼져 있으면 Claude Code 칸에 "focus-events 를 켜라"는 안내 글이 끼어든다.
# │   on            : 켬.
# │   # 직원 칸에 … : 줄 끝의 # 뒤는 실행되지 않는 짧은 설명이다.
# └── ▼ 실행 코드 [13] ──────────────
tmux set-option -g focus-events on   # 직원 칸에 tmux 안내 문구가 끼지 않게

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 칸마다 위쪽 테두리에 이름표 줄을 보인다.
# │   pane-border-status : 칸 테두리에 상태(이름표) 줄을 보일 위치.
# │   top                : 위쪽. (off 면 이름표가 안 보인다)
# └── ▼ 실행 코드 [14] ──────────────
tmux set-option -t "$SESSION" pane-border-status top

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 이름표 줄에 무엇을 쓸지 정한다.
# │   Claude Code 가 칸 제목(pane_title)을 "Claude Code" 로 바꿔도 이름표가 사라지지 않도록,
# │   우리가 붙인 사용자 옵션 @label 을 먼저 쓴다. 이름표가 없는 칸(직원 칸)은 pane_title 을 보여 준다.
# │   pane-border-format : 이름표 줄의 모양(서식).
# │   #{ ... }           : tmux 가 값으로 바꿔 넣는 자리.
# │   #{?조건,참,거짓}   : 조건이 있으면 참 쪽, 없으면 거짓 쪽 값을 쓴다.
# │   #{@label}          : 우리가 칸에 붙인 사용자 옵션 @label 의 값. 예) 쭌 편집장 (사장님 말을 받는 칸)
# │   #{pane_title}      : 칸 제목. 직원 칸에서는 Claude Code 가 정한 직원 이름이 들어간다.
# │   앞뒤 띄어쓰기      : 이름표 글자 양옆의 여백.
# └── ▼ 실행 코드 [15] ──────────────
tmux set-option -t "$SESSION" pane-border-format " #{?#{@label},#{@label},#{pane_title}} "

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 쭌 칸(team 창의 0번 칸)에 이름표 "쭌 편집장 (사장님 말을 받는 칸)" 을 붙인다.
# │   -p                   : pane(칸) 하나에만 적용.
# │   -t "$SESSION:team.0" : 대상 = publisher 세션의 team 창의 0번 칸. (모양: 세션:창.칸)
# │   @label               : 이름이 @ 로 시작하면 사용자가 만든 옵션. tmux·Claude Code 가 건드리지 않는다.
# └── ▼ 실행 코드 [16] ──────────────
tmux set-option -p -t "$SESSION:team.0" @label "쭌 편집장 (사장님 말을 받는 칸)"

# ━━━━━━━━━━ 구역 4  쭌 켜기 ━━━━━━━━━━

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 쭌 칸에 명령을 "타자 쳐서" Claude Code(쭌)를 켠다.
# │   send-keys            : 지정한 칸에 글자를 입력해 준다. 사람이 키보드로 친 것과 같다.
# │   "cd $P"              : 출판사 폴더로 이동. 그래야 claude 가 이 폴더의 CLAUDE.md 와 .claude/settings.json 을 읽는다.
# │   &&                   : 앞 명령이 성공하면 뒤 명령을 실행.
# │   MCP_TIMEOUT=60000    : 이 명령에서만 쓰는 환경변수. 플러그인(fakechat·telegram) 연결을 60000밀리초(60초)까지 기다린다.
# │   claude               : Claude Code 프로그램. 이것이 편집장 쭌이다.
# │   --channels $CHANNEL  : 채널 목록. 이 채널로 들어온 사장님 말이 쭌의 대화에 들어온다.
# │   --model sonnet       : 쭌이 쓸 AI 모델 = Sonnet.
# │   --teammate-mode tmux : 쭌이 직원(팀원)을 부르면 tmux 칸을 나눠 직원마다 칸 하나씩 띄운다.
# │   Enter                : 마지막에 Enter 키를 눌러 명령을 실행한다.
# └── ▼ 실행 코드 [17] ──────────────
tmux send-keys -t "$SESSION:team.0" "cd $P && MCP_TIMEOUT=60000 claude --channels $CHANNEL --model sonnet --teammate-mode tmux" Enter

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 채널에 fakechat 이 있으면 connect.sh(관리 화면 ↔ 쭌 연결 확인 도우미)를 뒤에서 조용히 실행한다.
# │   case 값 in 모양) 명령 ;; esac : 값이 모양과 맞으면 명령을 실행. (esac = case 를 거꾸로 쓴 끝 표시)
# │   *fakechat*                    : 앞뒤에 무엇이 있어도 fakechat 이 들어 있으면 맞음.
# │   setsid                        : 새 묶음(세션)으로 떼어 실행한다. 이 창을 닫아도 도우미가 같이 꺼지지 않는다.
# │   bash "$P/connect.sh"          : 도우미 파일 실행.
# │   "$SESSION:team.0"             : 도우미에게 넘기는 값 = 쭌 칸의 위치.
# │   >/dev/null 2>&1               : 일반 출력과 오류 출력을 모두 버린다. 기록은 ~/my-publisher/.connect.log 에 남는다.
# │   < /dev/null                   : 입력도 빈 것으로 준다(키보드를 기다리지 않게).
# │   &                             : 뒤에서(백그라운드로) 실행하고 바로 다음 줄로 넘어간다.
# └── ▼ 실행 코드 [18] ──────────────
case "$CHANNEL" in *fakechat*) setsid bash "$P/connect.sh" "$SESSION:team.0" >/dev/null 2>&1 < /dev/null & ;; esac

# ━━━━━━━━━━ 구역 5  관리 화면 켜기 ━━━━━━━━━━

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 관리 화면 실행 파일의 위치를 JAR 변수에 담는다.
# │   JAR     : 변수 이름. jar = 자바 프로그램을 하나로 묶은 파일.
# │   결과 예 : /home/khbs_d_0/my-publisher/dashboard/publisher-dashboard.jar
# └── ▼ 실행 코드 [19] ──────────────
JAR="$P/dashboard/publisher-dashboard.jar"

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: java 가 설치되어 있고 jar 파일도 있을 때만 관리 화면을 켠다.
# │   command -v java : java 명령이 어디 있는지 찾는다. 있으면 성공.
# │   >/dev/null 2>&1 : 찾은 결과 글은 화면에 보이지 않게 버린다.
# │   &&              : 앞뒤 두 조건이 모두 참일 때만.
# │   [ -f "$JAR" ]   : jar 파일이 있으면 참.
# └── ▼ 실행 코드 [20] ──────────────
if command -v java >/dev/null 2>&1 && [ -f "$JAR" ]; then

  # ┌── 설명 ──────────────────────────────────
  # │ ▶ 이 줄이 하는 일: tmux 에 두 번째 창 dashboard 를 만들고, 그 안에서 관리 화면을 실행한다.
  # │   new-window       : 새 창(1번)을 만든다. Ctrl+B 누른 뒤 1 로 이 창에 갈 수 있다.
  # │   -d               : 만들기만 하고 화면은 team 창에 그대로 둔다.
  # │   -n dashboard     : 창 이름 = dashboard.
  # │   -c "$P"          : 시작 폴더 = ~/my-publisher.
  # │   java -jar '$JAR' : 관리 화면 실행. 켜지면 http://localhost:8080 에서 열린다.
  # │   ; echo '…'       : 관리 화면이 꺼지면 안내 글을 보여 준다. (; = 앞 명령이 끝나면 다음 명령)
  # │   ; read           : Enter 를 누를 때까지 기다린다. 오류 글을 읽을 시간을 주려는 것이다.
  # └── ▼ 실행 코드 [21] ──────────────
  tmux new-window -d -t "$SESSION" -n dashboard -c "$P" "java -jar '$JAR'; echo '관리 화면이 꺼졌어요. Enter를 누르면 창이 닫혀요'; read"

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 위 if 블록의 끝 (if 를 거꾸로 쓴 말)
# └── ▼ 실행 코드 [22] ──────────────
fi

# ━━━━━━━━━━ 구역 6  화면 보여 주기 ━━━━━━━━━━

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 이미 tmux 안에서 실행했다면 publisher 세션으로 화면을 바꾼다. (구역 2 와 같은 방법)
# └── ▼ 실행 코드 [23] ──────────────
[ -n "$TMUX" ] && exec tmux switch-client -t "$SESSION"

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 만든 publisher 세션을 내 우분투 창에 띄운다. 이때부터 쭌 칸이 보인다.
# │   빠져나오기: Ctrl+B 를 누르고 뗀 뒤 D. 출판사는 계속 일한다. 다시 보려면 `출근`.
# └── ▼ 실행 코드 [24] ──────────────
exec tmux attach -t "$SESSION"
PUBLISHER_FILE_10_END

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 파일 ~/my-publisher/tepo/common.sh 를 만든다. (테포(배포 담당 AI 직원)의 스크립트가 모두 맨 처음 불러오는(source) 공용 설정이다. 직접 실행하지 않는다.)
# │   아래 213줄이 그 파일 내용 그대로이고, PUBLISHER_FILE_11_END 줄에서 끝난다.
# └── ▼ 실행 코드 [22] (아래 215줄이 한 덩어리) ────
cat > "$P/tepo/common.sh" <<'PUBLISHER_FILE_11_END'
#!/bin/bash
# [1] 역할
#     테포(배포 담당 AI 직원)의 스크립트가 모두 맨 처음 불러오는(source) 공용 설정이다. 직접 실행하지 않는다.
#     폴더 위치, AWS 지역, 만들 것들의 이름, 화면에 찍는 함수(say·ok·warn·fail)를 정한다.
#     맨 윗줄 #!/bin/bash : "쉬뱅(shebang)". 이 파일을 /bin/bash 프로그램으로 실행하라는 표시.
#       #! 는 파일 맨 처음에만 쓰며, 뒤에 적힌 프로그램(위치)으로 이 파일을 실행한다.
#
# [2] 받는 것 → 내보내는 것
#     받는 것  : 환경변수 (없으면 기본값)
#     내보내는 것: 변수와 함수.  예) P=/root/my-publisher, OPS=$P/ops, REGION=ap-northeast-2, INSTANCE=publisher-office,
#                  STATIC_IP=publisher-ip, DB=publisher-db, KEY=publisher-key
#       say "1/5 SSH 열쇠"  → 화면: ▶ 1/5 SSH 열쇠
#       ok "열쇠 publisher-key" → 화면: ✅ 열쇠 publisher-key
#
# [3] 앞뒤 파일
#     preflight.sh, create-infra.sh, server-setup.sh, github-setup.sh, health.sh, deploy-status.sh, install-tools.sh  →  source (이 파일)
#
# [4] 메서드 목록
#     이름            하는 일                                                    예
#     say/ok/warn     ▶ ✅ ⚠️ 를 붙여 한 줄 찍기
#     fail            ❌ 찍고 종료(exit 1)
#     lsail           aws --region 지역 lightsail …   를 줄여 쓴 것         lsail get-instance …
#     getv 파일 키     key=value 파일에서 값 하나 읽기                         getv ops/infra.env IP → 3.35.10.20
#     newpass 길이     영문·숫자로 된 무작위 비밀번호                            newpass 16
#
# [5] 먼저 알 용어
#     source, set -euo pipefail, ${변수:-기본값}, export, 함수 정의 이름() { … }, "$@"
#
# [6] 읽는 순서
#     set -euo pipefail → 변수들 → 함수들
#
# [7] 다 읽고 확인
#     - set -e 가 없으면 lsail create-instances 가 실패해도 스크립트는 어떻게 되는가? (다음 줄로 계속 간다)
#     - 연습(run-practice.sh)일 때 PATH 를 뒤에 붙이는 이유는? (가짜 aws·gh 가 진짜보다 먼저 불려야 진짜 서버가 만들어지지 않는다)
#
# [0] 코드만 모아 보기 — 이 파일에서 실제로 실행되는 줄 전체. 아래 본문에서 ▼ 실행 코드 [번호] 를 찾으면 그 줄의 설명이 있다.
#     [1] set -euo pipefail
#     [2] if [ -n "${MOCK_DIR:-}" ]; then export PATH="$PATH:$HOME/.local/bin"; else export PATH="$HOME/.local/bin:$P…
#     [3] export AWS_PAGER=""
#     [4] P="${PUBLISHER_HOME:-$HOME/my-publisher}"            # 출판사 폴더
#     [5] REPO="${PUBLISHER_REPO:-$HOME/ai-publisher}"          # zip 을 푼 소스 폴더 (GitHub 저장소가 됨)
#     [6] OPS="$P/ops"                                          # 배포 기록
#     [7] SECRETS="$OPS/secrets"                                # 비밀 파일 (권한 600, git 에 안 올라감)
#     [8] TEPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
#     [9] REGION="${LIGHTSAIL_REGION:-ap-northeast-2}"          # 서울
#     [10] AZ="${LIGHTSAIL_AZ:-${REGION}a}"
#     [11] NAME="${LIGHTSAIL_NAME:-publisher}"
#     [12] INSTANCE="$NAME-office"; STATIC_IP="$NAME-ip"; DB="$NAME-db"; KEY="$NAME-key"
#     [13] GH_REPO="${GH_REPO_NAME:-ai-publisher}"
#     [14] BOSS_USER="${BOSS_USERNAME:-boss}"
#     [15] mkdir -p "$OPS" "$SECRETS"
#     [16] chmod 700 "$SECRETS"
#     [17] say()  { echo "▶ $*"; }
#     [18] ok()   { echo "✅ $*"; }
#     [19] warn() { echo "⚠️  $*"; }
#     [20] fail() { echo "❌ $*" >&2; exit 1; }
#     [21] lsail() { aws --region "$REGION" lightsail "$@"; }
#     [22] getv() { grep -m1 "^$2=" "$1" 2>/dev/null | cut -d= -f2-; }
#     [23] newpass() { python3 -c "import secrets,string;a=string.ascii_letters+string.digits;print(''.join(secrets.ch…

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 오류가 나면 바로 멈추게 하는 안전 설정. 이 파일을 source 한 모든 테포 스크립트에 적용된다.
# │   set         : bash 의 동작 방식을 바꾸는 명령.
# │   -e          : 명령 하나라도 실패하면 즉시 멈춘다. (없으면 서버 만들기가 실패해도 다음 줄로 계속 간다)
# │   -u          : 정하지 않은 변수를 쓰면 멈춘다(오타 방지).
# │   -o pipefail : a | b 로 이은 명령에서 a 가 실패해도 실패로 본다.
# └── ▼ 실행 코드 [1] ───────────────
set -euo pipefail

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 프로그램을 찾는 길(PATH)에 ~/.local/bin(install-tools.sh 가 aws·gh 를 설치한 곳)을 넣는다.
# │   연습(mock/run-practice.sh)일 때는 뒤에 붙여 가짜 aws·gh 가 먼저 불리게 하고, 실제일 때는 앞에 붙인다.
# │   MOCK_DIR                 : 연습할 때만 run-practice.sh 가 정하는 변수(가짜 기록 폴더).
# │   ${MOCK_DIR:-}            : 변수가 없으면 빈 글. (set -u 때문에 :- 를 붙여야 오류가 안 난다)
# │   -n                       : 비어 있지 않으면 참.
# │   export                   : 이 변수를 이 스크립트가 부르는 다른 프로그램에도 넘긴다.
# │   PATH                     : 명령 이름을 입력하면 bash 가 찾아보는 폴더 목록. : 로 구분하고 앞쪽 폴더가 먼저.
# │   "$PATH:$HOME/.local/bin" : 원래 목록 뒤에 붙임 → 연습용 가짜가 이긴다.
# │   "$HOME/.local/bin:$PATH" : 앞에 붙임 → 설치한 진짜 aws·gh 가 먼저.
# └── ▼ 실행 코드 [2] ───────────────
if [ -n "${MOCK_DIR:-}" ]; then export PATH="$PATH:$HOME/.local/bin"; else export PATH="$HOME/.local/bin:$PATH"; fi

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: aws 결과를 less 같은 화면 넘김 프로그램으로 보여 주지 않게 한다(스크립트가 q 를 기다리며 멈추지 않게).
# │   AWS_PAGER : aws 명령이 결과를 보여 줄 때 쓸 프로그램. 빈 값 = 그냥 찍기.
# └── ▼ 실행 코드 [3] ───────────────
export AWS_PAGER=""

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 출판사 폴더 위치. 예) /home/khbs_d_0/my-publisher
# │   ${이름:-기본값} : 환경변수가 비어 있으면 기본값을 쓴다.
# │   PUBLISHER_HOME  : 다른 폴더를 쓰고 싶을 때 미리 정하는 환경변수(보통 없음).
# │   # 출판사 폴더   : 줄 끝의 짧은 설명.
# └── ▼ 실행 코드 [4] ───────────────
P="${PUBLISHER_HOME:-$HOME/my-publisher}"            # 출판사 폴더

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: zip 을 푼 소스 폴더. 이 폴더가 GitHub 저장소가 된다. 예) /home/khbs_d_0/ai-publisher
# └── ▼ 실행 코드 [5] ───────────────
REPO="${PUBLISHER_REPO:-$HOME/ai-publisher}"          # zip 을 푼 소스 폴더 (GitHub 저장소가 됨)

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 배포 기록 폴더. 예) ~/my-publisher/ops (infra.env, plan.md 등)
# └── ▼ 실행 코드 [6] ───────────────
OPS="$P/ops"                                          # 배포 기록

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 비밀 파일 폴더. DB 비밀번호·SSH 열쇠 등. git 에 올라가지 않는다(templates/gitignore).
# └── ▼ 실행 코드 [7] ───────────────
SECRETS="$OPS/secrets"                                # 비밀 파일 (권한 600, git 에 안 올라감)

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 이 common.sh 가 있는 폴더의 전체 경로. 예) /home/khbs_d_0/my-publisher/tepo
# │   ${BASH_SOURCE[0]} : source 로 불렸어도 "이 파일 자신"의 경로. ($0 은 부른 쪽 파일)
# │   cd … && pwd       : 그 폴더로 들어가 전체 경로를 찍는다.
# └── ▼ 실행 코드 [8] ───────────────
TEPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: AWS 지역 = ap-northeast-2 (서울). 서버가 서울 데이터센터에 만들어진다.
# └── ▼ 실행 코드 [9] ───────────────
REGION="${LIGHTSAIL_REGION:-ap-northeast-2}"          # 서울

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 가용 영역(지역 안의 건물 묶음) = ap-northeast-2a.
# │   ${REGION}a : REGION 값 뒤에 a 를 붙인 것. { } 로 변수 이름의 끝을 표시한다.
# └── ▼ 실행 코드 [10] ──────────────
AZ="${LIGHTSAIL_AZ:-${REGION}a}"

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 만들 것들 이름의 앞부분 = publisher.
# └── ▼ 실행 코드 [11] ──────────────
NAME="${LIGHTSAIL_NAME:-publisher}"

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 만들 것들의 이름 네 개를 한 줄에 정한다.
# │   INSTANCE  : 서버(컴퓨터) 이름 = publisher-office
# │   STATIC_IP : 고정 IP 이름 = publisher-ip
# │   DB        : 데이터베이스 이름 = publisher-db
# │   KEY       : SSH 열쇠 이름 = publisher-key
# │   ;         : 한 줄에 명령 여러 개.
# └── ▼ 실행 코드 [12] ──────────────
INSTANCE="$NAME-office"; STATIC_IP="$NAME-ip"; DB="$NAME-db"; KEY="$NAME-key"

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: GitHub 저장소 이름 = ai-publisher.
# └── ▼ 실행 코드 [13] ──────────────
GH_REPO="${GH_REPO_NAME:-ai-publisher}"

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 서버 관리 화면 로그인 아이디 = boss.
# └── ▼ 실행 코드 [14] ──────────────
BOSS_USER="${BOSS_USERNAME:-boss}"

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 기록 폴더와 비밀 폴더를 만든다(이미 있으면 그대로).
# │   -p : 중간 폴더까지 만들고, 이미 있어도 오류 없음.
# └── ▼ 실행 코드 [15] ──────────────
mkdir -p "$OPS" "$SECRETS"

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 비밀 폴더는 나만 읽고·쓰고·들어갈 수 있게 한다.
# │   chmod : 권한 바꾸기.
# │   700   : 주인 = 7(읽기4+쓰기2+실행1), 그룹 = 0, 다른 사람 = 0.
# └── ▼ 실행 코드 [16] ──────────────
chmod 700 "$SECRETS"

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: say 함수: 앞에 ▶ 를 붙여 한 줄 찍는다. 예) say "1/5 SSH 열쇠" → ▶ 1/5 SSH 열쇠
# │   $* : 함수에 넘긴 말 전체.
# └── ▼ 실행 코드 [17] ──────────────
say()  { echo "▶ $*"; }

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: ok 함수: ✅ 를 붙여 찍는다(성공).
# └── ▼ 실행 코드 [18] ──────────────
ok()   { echo "✅ $*"; }

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: warn 함수: ⚠️ 를 붙여 찍는다(주의, 계속 진행).
# └── ▼ 실행 코드 [19] ──────────────
warn() { echo "⚠️  $*"; }

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: fail 함수: ❌ 를 붙여 오류 출력으로 찍고 실패(1)로 끝낸다. 쭌은 이 ❌ 문장을 사장님께 그대로 전한다.
# │   >&2    : 표준 오류(2번)로 찍는다.
# │   exit 1 : 스크립트를 실패로 끝낸다.
# └── ▼ 실행 코드 [20] ──────────────
fail() { echo "❌ $*" >&2; exit 1; }

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: lsail 함수: "aws --region 서울 lightsail …" 를 줄여 쓴 것. 예) lsail get-instance …
# │   aws       : AWS 를 명령어로 다루는 프로그램.
# │   lightsail : AWS 의 쉬운 서버 서비스 이름.
# │   "$@"      : 함수에 넘긴 값들을 하나하나 따로 그대로 넘긴다.
# └── ▼ 실행 코드 [21] ──────────────
lsail() { aws --region "$REGION" lightsail "$@"; }

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: getv 함수: "키=값" 줄로 된 파일에서 값 하나를 읽는다. 예) getv ops/infra.env IP → 3.35.10.20
# │   $1, $2          : 첫 번째 값 = 파일, 두 번째 값 = 키.
# │   grep -m1 "^IP=" : "IP=" 로 시작하는 첫 줄만. 예) IP=3.35.10.20
# │   cut -d= -f2-    : = 로 나눠 두 번째 칸부터 끝까지. → 3.35.10.20
# └── ▼ 실행 코드 [22] ──────────────
getv() { grep -m1 "^$2=" "$1" 2>/dev/null | cut -d= -f2-; }

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: newpass 함수: 영문·숫자로만 된 무작위 비밀번호를 만든다. 길이를 안 주면 24자.
# │   python3 -c "…" : 따옴표 안의 짧은 Python 을 실행.
# │   secrets.choice : 추측하기 어려운(암호용) 무작위 고르기.
# │   ${1:-24}       : 첫 번째 값(길이), 없으면 24.
# └── ▼ 실행 코드 [23] ──────────────
newpass() { python3 -c "import secrets,string;a=string.ascii_letters+string.digits;print(''.join(secrets.choice(a) for _ in range(${1:-24})))"; }
PUBLISHER_FILE_11_END

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 파일 ~/my-publisher/tepo/create-infra.sh 를 만든다. (라이트세일에 서버·고정 IP·방화벽·MySQL DB 를 만든다. 돈이 드는 단계다.)
# │   아래 392줄이 그 파일 내용 그대로이고, PUBLISHER_FILE_12_END 줄에서 끝난다.
# └── ▼ 실행 코드 [23] (아래 394줄이 한 덩어리) ────
cat > "$P/tepo/create-infra.sh" <<'PUBLISHER_FILE_12_END'
#!/bin/bash
# [1] 역할
#     라이트세일에 서버·고정 IP·방화벽·MySQL DB 를 만든다. 돈이 드는 단계다.
#     사장님 승인 기록(ops/approved.txt)이 있고 마지막 준비 확인(ops/plan.env)보다 새것일 때만 실행된다.
#     이미 있는 것은 다시 만들지 않는다. 그래서 중간에 멈춰도 다시 실행하면 이어서 한다.
#     돈이 드는 단계다. 사장님 승인 기록(ops/approved.txt)이 마지막 준비 확인(ops/plan.env)보다 새것이어야만 실행된다.
#     이미 있는 것은 다시 만들지 않는다(여러 번 실행해도 안전). 중간에 멈춰도 다시 실행하면 이어서 한다.
#     맨 윗줄 #!/bin/bash : "쉬뱅(shebang)". 이 파일을 /bin/bash 프로그램으로 실행하라는 표시.
#       #! 는 파일 맨 처음에만 쓰며, 뒤에 적힌 프로그램(위치)으로 이 파일을 실행한다.
#
# [2] 받는 것 → 내보내는 것
#     받는 것  : ops/plan.env (preflight 결과), ops/approved.txt (첫 줄 시각, 둘째 줄 사장님 말)
#     내보내는 것 (실제 값은 연습 bash tepo/mock/run-practice.sh 를 실행해 얻은 것. 가짜 aws 가 돌려준 값이다)
#       ▶ 사장님 승인: 2026-11-10 02:56:35 — 좋아요, 서버에 올려 주세요
#       ✅ 열쇠 publisher-key   ✅ 서버 켜짐   ✅ 고정 IP 3.35.10.20
#       ✅ DB 준비됨 (ls-abc123.cluster.ap-northeast-2.rds.amazonaws.com:3306)
#       ops/infra.env: IP=3.35.10.20, HOST=3-35-10-20.sslip.io, SSH_USER=ubuntu, DB_HOST=…, DB_PORT=3306
#     승인 없이 실행하면  ❌ 사장님 승인 기록(ops/approved.txt)이 없어요. … (아무것도 만들지 않음)
#     두 번째 실행        만들기 명령 4번 그대로 (새로 만든 것 없음)
#
# [3] 앞뒤 파일
#     preflight.sh → ops/plan.env  →  (이 파일)  →  ops/infra.env, ops/secrets/lightsail_key, ops/secrets/db-password  →  server-setup.sh
#
# [4] 메서드 목록
#     단계    만드는 것                    이미 있는지 보는 명령                 만드는 명령
#     검사    (없음)                       plan.env, approved.txt, 두 파일 시각 비교
#     1/5     SSH 열쇠                     lsail get-key-pair                    ssh-keygen, lsail import-key-pair
#     2/5     서버                         lsail get-instance                    lsail create-instances
#     3/5     고정 IP, 방화벽 22·80·443     lsail get-static-ip                   allocate-static-ip, attach-static-ip, put-instance-public-ports
#     4/5     MySQL DB                     lsail get-relational-database         lsail create-relational-database
#     5/5     ops/infra.env 기록
#
# [5] 먼저 알 용어
#     [ -s 파일 ], [ a -nt b ](더 새것인가), ||, if ! 명령; then, for i in $(seq 1 60), ${IP//./-}(글자 바꾸기), heredoc
#
# [6] 읽는 순서
#     검사 세 줄 → 1/5 → 2/5 → 4/5 → 5/5
#
# [7] 다 읽고 확인
#     - 쭌이 [배포 제안]을 올린 뒤 preflight 를 다시 돌리면 왜 승인을 다시 받아야 하는가? (plan.env 가 승인보다 새것이 되어 -nt 검사가 실패)
#     - DB 를 만드는 중에 창을 닫았다가 다시 실행하면 DB 가 두 개 생기는가? (아니다. get-relational-database 가 성공해 만들기를 건너뛴다)
#
# [0] 코드만 모아 보기 — 이 파일에서 실제로 실행되는 줄 전체. 아래 본문에서 ▼ 실행 코드 [번호] 를 찾으면 그 줄의 설명이 있다.
#     [1] source "$(dirname "$0")/common.sh"
#     [2] [ -s "$OPS/plan.env" ] || fail "준비 확인 결과가 없어요. 먼저 bash tepo/preflight.sh"
#     [3] [ -s "$OPS/approved.txt" ] || fail "사장님 승인 기록(ops/approved.txt)이 없어요. 쭌이 [배포 제안] 승인을 받…
#     [4] [ "$OPS/approved.txt" -nt "$OPS/plan.env" ] || fail "승인이 마지막 준비 확인보다 오래됐어요. 쭌에게 다시 […
#     [5] say "사장님 승인: $(head -1 "$OPS/approved.txt") — $(sed -n 2p "$OPS/approved.txt" | cut -c1-60)"
#     [6] PLAN="$OPS/plan.env"
#     [7] BUNDLE="$(getv "$PLAN" BUNDLE)"; BLUEPRINT="$(getv "$PLAN" BLUEPRINT)"
#     [8] DB_BUNDLE="$(getv "$PLAN" DB_BUNDLE)"; DB_BLUEPRINT="$(getv "$PLAN" DB_BLUEPRINT)"
#     [9] say "1/5 SSH 열쇠"
#     [10] [ -f "$SECRETS/lightsail_key" ] || ssh-keygen -q -t rsa -b 4096 -N "" -C "ai-publisher" -f "$SECRETS/lights…
#     [11] chmod 600 "$SECRETS/lightsail_key"
#     [12] if ! lsail get-key-pair --key-pair-name "$KEY" >/dev/null 2>&1; then
#     [13]   lsail import-key-pair --key-pair-name "$KEY" --public-key-base64 "file://$SECRETS/lightsail_key.pub" >/de…
#     [14] fi
#     [15] ok "열쇠 $KEY"
#     [16] say "2/5 서버 $INSTANCE ($BUNDLE)"
#     [17] if ! lsail get-instance --instance-name "$INSTANCE" >/dev/null 2>&1; then
#     [18]   lsail create-instances --instance-names "$INSTANCE" --availability-zone "$AZ" \   (+2줄)
#     [19] fi
#     [20] for i in $(seq 1 60); do
#     [21]   S="$(lsail get-instance-state --instance-name "$INSTANCE" --query state.name --output text)"
#     [22]   [ "$S" = "running" ] && break; sleep 5
#     [23] done
#     [24] [ "$S" = "running" ] || fail "서버가 5분 안에 켜지지 않았어요 (상태: $S)"
#     [25] ok "서버 켜짐"
#     [26] say "3/5 고정 IP와 방화벽(22·80·443)"
#     [27] lsail get-static-ip --static-ip-name "$STATIC_IP" >/dev/null 2>&1 || lsail allocate-static-ip --static-ip-n…
#     [28] ATTACHED="$(lsail get-static-ip --static-ip-name "$STATIC_IP" --query staticIp.attachedTo --output text)"
#     [29] [ "$ATTACHED" = "$INSTANCE" ] || lsail attach-static-ip --static-ip-name "$STATIC_IP" --instance-name "$INS…
#     [30] IP="$(lsail get-static-ip --static-ip-name "$STATIC_IP" --query staticIp.ipAddress --output text)"
#     [31] lsail put-instance-public-ports --instance-name "$INSTANCE" --port-infos \   (+1줄)
#     [32] ok "고정 IP $IP"
#     [33] say "4/5 MySQL DB $DB ($DB_BUNDLE) — 처음 만들 때 10~20분 걸려요"
#     [34] if ! lsail get-relational-database --relational-database-name "$DB" >/dev/null 2>&1; then
#     [35]   [ -f "$SECRETS/db-password" ] || { newpass 28 > "$SECRETS/db-password"; chmod 600 "$SECRETS/db-password"; }
#     [36]   lsail create-relational-database --relational-database-name "$DB" --availability-zone "$AZ" \   (+4줄)
#     [37] fi
#     [38] for i in $(seq 1 180); do
#     [39]   S="$(lsail get-relational-database --relational-database-name "$DB" --query relationalDatabase.state --ou…
#     [40]   [ "$S" = "available" ] && break
#     [41]   [ $((i % 6)) -eq 0 ] && say "   DB 준비 중… ($((i / 6))분, 상태: $S)"
#     [42]   sleep 10
#     [43] done
#     [44] [ "$S" = "available" ] || fail "DB가 30분 안에 준비되지 않았어요 (상태: $S). 잠시 뒤 다시 실행하면 이어서 …
#     [45] read -r DB_HOST DB_PORT <<<"$(lsail get-relational-database --relational-database-name "$DB" --query '[rela…
#     [46] ok "DB 준비됨 ($DB_HOST:$DB_PORT)"
#     [47] say "5/5 기록 남기기 (ops/infra.env)"
#     [48] cat > "$OPS/infra.env" <<INFRA   (+10줄)
#     [49] ok "다 만들었어요. 다음: bash tepo/server-setup.sh"

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 공용 설정 파일 common.sh 를 불러와 그 안의 변수(OPS, REPO …)와 함수(ok, fail …)를 이 파일에서 쓴다.
# │   source 파일        : 그 파일의 내용을 지금 이 자리에서 실행한다(새 프로그램을 띄우지 않음). 그래서 변수·함수가 이어진다.
# │   $0                 : 지금 실행 중인 파일 이름. 예) tepo/health.sh
# │   dirname            : 경로에서 폴더 부분만. 예) tepo/health.sh → tepo
# │   "$( … )/common.sh" : 결과 예) tepo/common.sh
# └── ▼ 실행 코드 [1] ───────────────
source "$(dirname "$0")/common.sh"

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: preflight.sh 가 만든 계획 파일이 없으면 오류로 끝낸다.
# └── ▼ 실행 코드 [2] ───────────────
[ -s "$OPS/plan.env" ] || fail "준비 확인 결과가 없어요. 먼저 bash tepo/preflight.sh"

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 사장님 승인 기록이 없으면 오류로 끝낸다. (쭌이 [배포 제안]에 사장님의 "승인"을 받으면 이 파일을 쓴다)
# └── ▼ 실행 코드 [3] ───────────────
[ -s "$OPS/approved.txt" ] || fail "사장님 승인 기록(ops/approved.txt)이 없어요. 쭌이 [배포 제안] 승인을 받은 뒤에 실행해요."

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 승인이 마지막 계획보다 나중이어야 한다. 사장님은 마지막으로 계산한 계획(요금 포함)을 보고 승인했어야 한다.
# │   -nt : newer than. 앞 파일이 뒤 파일보다 나중에 고쳐졌으면 참.
# └── ▼ 실행 코드 [4] ───────────────
[ "$OPS/approved.txt" -nt "$OPS/plan.env" ] || fail "승인이 마지막 준비 확인보다 오래됐어요. 쭌에게 다시 [배포 제안]을 부탁해요."

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 승인 기록의 첫 줄(시각)과 둘째 줄 앞 60글자(승인 문장)를 찍는다.
# │   head -1    : 첫 줄.
# │   sed -n 2p  : 둘째 줄만.
# │   cut -c1-60 : 1~60번째 글자만.
# └── ▼ 실행 코드 [5] ───────────────
say "사장님 승인: $(head -1 "$OPS/approved.txt") — $(sed -n 2p "$OPS/approved.txt" | cut -c1-60)"

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 계획 파일 위치.
# └── ▼ 실행 코드 [6] ───────────────
PLAN="$OPS/plan.env"

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 계획에서 서버 요금제와 운영체제를 읽는다. 예) small_3_0, ubuntu_24_04
# └── ▼ 실행 코드 [7] ───────────────
BUNDLE="$(getv "$PLAN" BUNDLE)"; BLUEPRINT="$(getv "$PLAN" BLUEPRINT)"

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 계획에서 DB 요금제와 DB 종류를 읽는다. 예) micro_2_0, mysql_8_0
# └── ▼ 실행 코드 [8] ───────────────
DB_BUNDLE="$(getv "$PLAN" DB_BUNDLE)"; DB_BLUEPRINT="$(getv "$PLAN" DB_BLUEPRINT)"

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 1단계 제목.
# └── ▼ 실행 코드 [9] ───────────────
say "1/5 SSH 열쇠"

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 서버에 들어갈 SSH 열쇠 한 쌍을 만든다(없을 때만).
# │   lightsail_key = 비밀 열쇠(내 PC 에만), lightsail_key.pub = 공개 열쇠(라이트세일에 올림).
# │   ssh-keygen        : 열쇠 만들기 프로그램.
# │   -t rsa -b 4096    : 종류 RSA, 길이 4096비트.
# │   -N ""             : 열쇠 비밀번호 없음(스크립트와 GitHub Actions 가 그대로 쓸 수 있게).
# │   -C "ai-publisher" : 열쇠에 붙는 설명 글.
# │   -f 파일           : 저장할 곳.
# │   -q                : 조용히.
# └── ▼ 실행 코드 [10] ──────────────
[ -f "$SECRETS/lightsail_key" ] || ssh-keygen -q -t rsa -b 4096 -N "" -C "ai-publisher" -f "$SECRETS/lightsail_key"

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 비밀 열쇠는 나만 읽게 한다. (ssh 는 다른 사람도 읽을 수 있는 열쇠를 거부한다)
# └── ▼ 실행 코드 [11] ──────────────
chmod 600 "$SECRETS/lightsail_key"

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 라이트세일에 그 이름의 열쇠가 아직 없으면 아래 줄로 올린다.
# │   if ! 명령       : 명령이 실패하면(= 아직 없으면).
# │   >/dev/null 2>&1 : 결과와 오류 글을 모두 버린다.
# └── ▼ 실행 코드 [12] ──────────────
if ! lsail get-key-pair --key-pair-name "$KEY" >/dev/null 2>&1; then

  # ┌── 설명 ──────────────────────────────────
  # │ ▶ 이 줄이 하는 일: 공개 열쇠를 라이트세일에 올린다. 서버를 만들 때 이 열쇠를 넣는다.
  # │   file://경로 : aws 명령에서 "이 파일의 내용"이라는 뜻.
  # └── ▼ 실행 코드 [13] ──────────────
  lsail import-key-pair --key-pair-name "$KEY" --public-key-base64 "file://$SECRETS/lightsail_key.pub" >/dev/null

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 위 if 블록의 끝 (if 를 거꾸로 쓴 말)
# └── ▼ 실행 코드 [14] ──────────────
fi

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 예) ✅ 열쇠 publisher-key
# └── ▼ 실행 코드 [15] ──────────────
ok "열쇠 $KEY"

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 2단계 제목. 예) ▶ 2/5 서버 publisher-office (small_3_0)
# └── ▼ 실행 코드 [16] ──────────────
say "2/5 서버 $INSTANCE ($BUNDLE)"

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 그 이름의 서버가 아직 없으면 만든다.
# └── ▼ 실행 코드 [17] ──────────────
if ! lsail get-instance --instance-name "$INSTANCE" >/dev/null 2>&1; then

  # ┌── 설명 ──────────────────────────────────
  # │ ▶ 이 줄이 하는 일: 서버 한 대를 만든다(여기서부터 요금이 나간다). 줄 끝 \ 로 이어진 3줄이 한 명령이다.
  # │   --instance-names                      : 서버 이름 = publisher-office
  # │   --availability-zone                   : 가용 영역 = ap-northeast-2a
  # │   --blueprint-id                        : 운영체제 = ubuntu_24_04
  # │   --bundle-id                           : 요금제 = small_3_0
  # │   --key-pair-name                       : 넣을 SSH 열쇠.
  # │   --tags key=project,value=ai-publisher : 이름표. AWS 화면에서 이 프로젝트 것만 골라 보기 쉽게.
  # └── ▼ 실행 코드 [18] (아래 3줄이 한 덩어리) ────
  lsail create-instances --instance-names "$INSTANCE" --availability-zone "$AZ" \
    --blueprint-id "$BLUEPRINT" --bundle-id "$BUNDLE" --key-pair-name "$KEY" \
    --tags key=project,value=ai-publisher >/dev/null

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 위 if 블록의 끝 (if 를 거꾸로 쓴 말)
# └── ▼ 실행 코드 [19] ──────────────
fi

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 5초마다 최대 60번(5분) 서버 상태를 물어 running 이 되면 멈춘다.
# └── ▼ 실행 코드 [20] ──────────────
for i in $(seq 1 60); do

  # ┌── 설명 ──────────────────────────────────
  # │ ▶ 이 줄이 하는 일: 지금 상태를 S 에 담는다. 예) pending → running
  # │   --query state.name : 결과에서 상태 이름만.
  # └── ▼ 실행 코드 [21] ──────────────
  S="$(lsail get-instance-state --instance-name "$INSTANCE" --query state.name --output text)"

  # ┌── 설명 ──────────────────────────────────
  # │ ▶ 이 줄이 하는 일: running 이면 반복을 멈추고, 아니면 5초 쉰다.
  # └── ▼ 실행 코드 [22] ──────────────
  [ "$S" = "running" ] && break; sleep 5

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 위 for / while 반복의 끝
# └── ▼ 실행 코드 [23] ──────────────
done

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 5분이 지나도 안 켜졌으면 오류로 끝낸다.
# └── ▼ 실행 코드 [24] ──────────────
[ "$S" = "running" ] || fail "서버가 5분 안에 켜지지 않았어요 (상태: $S)"

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 알린다.
# └── ▼ 실행 코드 [25] ──────────────
ok "서버 켜짐"

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 3단계 제목.
# └── ▼ 실행 코드 [26] ──────────────
say "3/5 고정 IP와 방화벽(22·80·443)"

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 고정 IP 가 없을 때만 받는다(allocate). 고정 IP = 서버를 껐다 켜도 바뀌지 않는 주소.
# └── ▼ 실행 코드 [27] ──────────────
lsail get-static-ip --static-ip-name "$STATIC_IP" >/dev/null 2>&1 || lsail allocate-static-ip --static-ip-name "$STATIC_IP" >/dev/null

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 고정 IP 가 지금 어느 서버에 붙어 있는지. 예) publisher-office 또는 None
# └── ▼ 실행 코드 [28] ──────────────
ATTACHED="$(lsail get-static-ip --static-ip-name "$STATIC_IP" --query staticIp.attachedTo --output text)"

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 우리 서버에 붙어 있지 않으면 붙인다(attach).
# └── ▼ 실행 코드 [29] ──────────────
[ "$ATTACHED" = "$INSTANCE" ] || lsail attach-static-ip --static-ip-name "$STATIC_IP" --instance-name "$INSTANCE" >/dev/null

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 고정 IP 주소. 예) 3.35.10.20
# └── ▼ 실행 코드 [30] ──────────────
IP="$(lsail get-static-ip --static-ip-name "$STATIC_IP" --query staticIp.ipAddress --output text)"

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 방화벽: 22(SSH), 80(HTTP, 인증서 발급용), 443(HTTPS)만 연다. 8080 은 열지 않는다(Caddy 를 거쳐서만).
# │   줄 끝 \ 로 이어진 2줄이 한 명령이다.
# │   put-…                              : 목록을 이것으로 "통째로 바꾼다"(그 밖의 포트는 닫힘).
# │   fromPort=22,toPort=22,protocol=tcp : 22번 하나를 TCP 로 연다.
# └── ▼ 실행 코드 [31] (아래 2줄이 한 덩어리) ────
lsail put-instance-public-ports --instance-name "$INSTANCE" --port-infos \
  fromPort=22,toPort=22,protocol=tcp fromPort=80,toPort=80,protocol=tcp fromPort=443,toPort=443,protocol=tcp >/dev/null

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 예) ✅ 고정 IP 3.35.10.20
# └── ▼ 실행 코드 [32] ──────────────
ok "고정 IP $IP"

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 4단계 제목. DB 는 처음 만들 때 10~20분 걸린다.
# └── ▼ 실행 코드 [33] ──────────────
say "4/5 MySQL DB $DB ($DB_BUNDLE) — 처음 만들 때 10~20분 걸려요"

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 그 이름의 DB 가 아직 없으면 아래 두 줄로 만든다.
# └── ▼ 실행 코드 [34] ──────────────
if ! lsail get-relational-database --relational-database-name "$DB" >/dev/null 2>&1; then

  # ┌── 설명 ──────────────────────────────────
  # │ ▶ 이 줄이 하는 일: DB 비밀번호 28자를 만들어 권한 600 파일에 둔다(없을 때만). 화면과 연습 기록(calls.log)에는 **** 로만 보인다.
  # └── ▼ 실행 코드 [35] ──────────────
  [ -f "$SECRETS/db-password" ] || { newpass 28 > "$SECRETS/db-password"; chmod 600 "$SECRETS/db-password"; }

  # ┌── 설명 ──────────────────────────────────
  # │ ▶ 이 줄이 하는 일: MySQL DB 를 만든다. 줄 끝 \ 로 이어진 5줄이 한 명령이다.
  # │   --master-database-name publisher  : 처음 만들 DB 이름.
  # │   --master-username publisher       : DB 관리자 아이디.
  # │   --master-user-password "$(cat …)" : 위에서 만든 비밀번호 파일의 내용.
  # │   --no-publicly-accessible          : DB 는 인터넷에서 바로 접속할 수 없다. 같은 지역의 라이트세일 서버만 접속한다.
  # └── ▼ 실행 코드 [36] (아래 5줄이 한 덩어리) ────
  lsail create-relational-database --relational-database-name "$DB" --availability-zone "$AZ" \
    --relational-database-blueprint-id "$DB_BLUEPRINT" --relational-database-bundle-id "$DB_BUNDLE" \
    --master-database-name publisher --master-username publisher \
    --master-user-password "$(cat "$SECRETS/db-password")" --no-publicly-accessible \
    --tags key=project,value=ai-publisher >/dev/null

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 위 if 블록의 끝 (if 를 거꾸로 쓴 말)
# └── ▼ 실행 코드 [37] ──────────────
fi

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 10초마다 최대 180번(30분) DB 상태를 본다.
# └── ▼ 실행 코드 [38] ──────────────
for i in $(seq 1 180); do

  # ┌── 설명 ──────────────────────────────────
  # │ ▶ 이 줄이 하는 일: 지금 DB 상태. 예) creating → backing-up → available
  # └── ▼ 실행 코드 [39] ──────────────
  S="$(lsail get-relational-database --relational-database-name "$DB" --query relationalDatabase.state --output text)"

  # ┌── 설명 ──────────────────────────────────
  # │ ▶ 이 줄이 하는 일: 준비되면(available) 멈춘다.
  # └── ▼ 실행 코드 [40] ──────────────
  [ "$S" = "available" ] && break

  # ┌── 설명 ──────────────────────────────────
  # │ ▶ 이 줄이 하는 일: i 가 6의 배수일 때(1분마다) 진행 상황을 찍는다. 예) ▶    DB 준비 중… (3분, 상태: creating)
  # │   $(( )) : 정수 계산. % = 나머지, / = 몫.
  # │   -eq    : 같으면 참(숫자 비교).
  # └── ▼ 실행 코드 [41] ──────────────
  [ $((i % 6)) -eq 0 ] && say "   DB 준비 중… ($((i / 6))분, 상태: $S)"

  # ┌── 설명 ──────────────────────────────────
  # │ ▶ 이 줄이 하는 일: 10초 쉰다.
  # └── ▼ 실행 코드 [42] ──────────────
  sleep 10

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 위 for / while 반복의 끝
# └── ▼ 실행 코드 [43] ──────────────
done

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 30분이 지나도 안 되면 오류로 끝낸다. 다시 실행하면 이미 있는 DB 를 이어서 기다린다.
# └── ▼ 실행 코드 [44] ──────────────
[ "$S" = "available" ] || fail "DB가 30분 안에 준비되지 않았어요 (상태: $S). 잠시 뒤 다시 실행하면 이어서 기다려요."

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: DB 접속 주소와 포트를 두 변수에 나눠 담는다. 예) ls-abc123.cluster.ap-northeast-2.rds.amazonaws.com 3306
# └── ▼ 실행 코드 [45] ──────────────
read -r DB_HOST DB_PORT <<<"$(lsail get-relational-database --relational-database-name "$DB" --query '[relationalDatabase.masterEndpoint.address, relationalDatabase.masterEndpoint.port]' --output text)"

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 알린다.
# └── ▼ 실행 코드 [46] ──────────────
ok "DB 준비됨 ($DB_HOST:$DB_PORT)"

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 5단계 제목.
# └── ▼ 실행 코드 [47] ──────────────
say "5/5 기록 남기기 (ops/infra.env)"

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 다음 스크립트들(server-setup, github-setup, health)이 읽을 기록을 ops/infra.env 에 쓴다(아래 9줄이 파일 내용, INFRA 줄에서 끝).
# │   HOST=${IP//./-}.sslip.io : IP 의 점(.)을 모두 줄표(-)로 바꾼다. 예) 3.35.10.20 → 3-35-10-20.sslip.io
# │                              sslip.io 는 이름 안의 숫자를 그 IP 로 알려 주는 공개 DNS 라서 도메인을 사지 않아도 HTTPS 인증서를 받을 수 있다.
# │   ${변수//찾을/바꿀}       : 모두 바꾸기. (/ 하나면 첫 번째만)
# │   SSH_USER=ubuntu          : Ubuntu 서버의 기본 아이디.
# └── ▼ 실행 코드 [48] (아래 11줄이 한 덩어리) ────
cat > "$OPS/infra.env" <<INFRA
REGION=$REGION
INSTANCE=$INSTANCE
IP=$IP
HOST=${IP//./-}.sslip.io
SSH_USER=ubuntu
DB_HOST=$DB_HOST
DB_PORT=$DB_PORT
DB_NAME=publisher
DB_USER=publisher
INFRA

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 끝. 다음 할 일을 알린다.
# └── ▼ 실행 코드 [49] ──────────────
ok "다 만들었어요. 다음: bash tepo/server-setup.sh"
PUBLISHER_FILE_12_END

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 파일 ~/my-publisher/tepo/deploy-status.sh 를 만든다. (GitHub Actions 의 최근 실행 다섯 개를 보여 주고, 마지막 실행이 실패했으면 실패한 부분의 로그를 보여 준다.)
# │   아래 99줄이 그 파일 내용 그대로이고, PUBLISHER_FILE_13_END 줄에서 끝난다.
# └── ▼ 실행 코드 [24] (아래 101줄이 한 덩어리) ────
cat > "$P/tepo/deploy-status.sh" <<'PUBLISHER_FILE_13_END'
#!/bin/bash
# [1] 역할
#     GitHub Actions 의 최근 실행 다섯 개를 보여 주고, 마지막 실행이 실패했으면 실패한 부분의 로그를 보여 준다.
#     맨 윗줄 #!/bin/bash : "쉬뱅(shebang)". 이 파일을 /bin/bash 프로그램으로 실행하라는 표시.
#       #! 는 파일 맨 처음에만 쓰며, 뒤에 적힌 프로그램(위치)으로 이 파일을 실행한다.
#
# [2] 받는 것 → 내보내는 것
#     결과 예) gh run list 표 (상태, 이름, 가지, 시각) 다섯 줄
#     마지막이 실패면  ❌ 마지막 실행(#4242) 실패 로그:  + 로그 끝 60줄
#
# [3] 앞뒤 파일
#     (이 파일)  →  gh run list / gh run view --log-failed  →  .github/workflows/ci.yml, deploy.yml 의 실행 기록
#
# [4] 메서드 목록
#     줄              하는 일
#     gh run list     최근 5개
#     LAST=…          마지막 실행의 번호와 결과
#     gh run view     실패면 실패한 단계의 로그
#
# [5] 먼저 알 용어
#     gh run list --json --jq, read -r A B <<<
#
# [6] 읽는 순서
#     gh run list → LAST → if
#
# [7] 다 읽고 확인
#     - --log-failed 는 무엇만 보여 주는가? (실패한 단계의 로그)
#     - CI 에서 MySqlMigrationTest 가 실패하면 이 스크립트에서 무엇을 보게 되는가?
#
# [0] 코드만 모아 보기 — 이 파일에서 실제로 실행되는 줄 전체. 아래 본문에서 ▼ 실행 코드 [번호] 를 찾으면 그 줄의 설명이 있다.
#     [1] source "$(dirname "$0")/common.sh"
#     [2] cd "$REPO" || fail "소스 폴더로 갈 수 없어요: $REPO"
#     [3] gh run list --limit 5 || fail "GitHub 에서 결과를 읽지 못했어요 (gh auth status 확인)"
#     [4] LAST="$(gh run list --limit 1 --json databaseId,conclusion --jq '.[0] | "\(.databaseId) \(.conclusion)"')"
#     [5] read -r ID CONC <<<"$LAST"
#     [6] if [ "$CONC" = "failure" ]; then
#     [7]   echo; echo "❌ 마지막 실행(#$ID) 실패 로그:"
#     [8]   gh run view "$ID" --log-failed | tail -60
#     [9] fi

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 공용 설정 파일 common.sh 를 불러와 그 안의 변수(OPS, REPO …)와 함수(ok, fail …)를 이 파일에서 쓴다.
# │   source 파일        : 그 파일의 내용을 지금 이 자리에서 실행한다(새 프로그램을 띄우지 않음). 그래서 변수·함수가 이어진다.
# │   $0                 : 지금 실행 중인 파일 이름. 예) tepo/health.sh
# │   dirname            : 경로에서 폴더 부분만. 예) tepo/health.sh → tepo
# │   "$( … )/common.sh" : 결과 예) tepo/common.sh
# └── ▼ 실행 코드 [1] ───────────────
source "$(dirname "$0")/common.sh"

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 소스 폴더(GitHub 저장소)로 들어간다. gh 는 지금 폴더의 저장소를 본다.
# └── ▼ 실행 코드 [2] ───────────────
cd "$REPO" || fail "소스 폴더로 갈 수 없어요: $REPO"

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: GitHub Actions(자동 시험·배포)의 최근 실행 5개를 표로 보여 준다.
# │   gh        : GitHub 를 명령어로 다루는 프로그램.
# │   run list  : 실행 기록 목록.
# │   --limit 5 : 5개만.
# └── ▼ 실행 코드 [3] ───────────────
gh run list --limit 5 || fail "GitHub 에서 결과를 읽지 못했어요 (gh auth status 확인)"

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 마지막 실행 하나의 "번호 결과" 를 글자로 만든다. 예) "4242 failure"
# │   --json databaseId,conclusion : 번호와 결과(success/failure) 두 가지만 JSON 으로 받는다.
# │   --jq '…'                     : JSON 에서 값을 골라 글자로 만드는 규칙. .[0] = 첫 번째, \(…) = 값 끼워 넣기.
# └── ▼ 실행 코드 [4] ───────────────
LAST="$(gh run list --limit 1 --json databaseId,conclusion --jq '.[0] | "\(.databaseId) \(.conclusion)"')"

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: "4242 failure" 를 띄어쓰기로 나눠 ID=4242, CONC=failure 에 담는다.
# │   read : 입력을 읽어 변수에 나눠 담는 명령.
# │   -r   : \ 를 특별하게 다루지 않고 그대로 읽는다.
# │   <<<  : 뒤의 글을 입력으로 준다.
# └── ▼ 실행 코드 [5] ───────────────
read -r ID CONC <<<"$LAST"

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 마지막 실행이 실패였으면 아래 두 줄로 실패 내용을 보여 준다.
# │   = : [ ] 안에서는 "같은가" 비교.
# └── ▼ 실행 코드 [6] ───────────────
if [ "$CONC" = "failure" ]; then

  # ┌── 설명 ──────────────────────────────────
  # │ ▶ 이 줄이 하는 일: 빈 줄 하나, 그리고 제목 줄을 찍는다.
  # └── ▼ 실행 코드 [7] ───────────────
  echo; echo "❌ 마지막 실행(#$ID) 실패 로그:"

  # ┌── 설명 ──────────────────────────────────
  # │ ▶ 이 줄이 하는 일: 실패한 단계의 기록(로그)만 가져와 끝의 60줄을 보여 준다.
  # │   --log-failed : 실패한 단계의 로그만.
  # │   | tail -60   : 끝에서 60줄만.
  # └── ▼ 실행 코드 [8] ───────────────
  gh run view "$ID" --log-failed | tail -60

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 위 if 블록의 끝 (if 를 거꾸로 쓴 말)
# └── ▼ 실행 코드 [9] ───────────────
fi
PUBLISHER_FILE_13_END

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 파일 ~/my-publisher/tepo/github-setup.sh 를 만든다. (GitHub 비공개 저장소를 만들고, 서버 정보를 Secrets 에 넣고, CI/CD 설정(ci.yml·deploy.yml)을 넣어 push 한 뒤 첫 배포를 지켜본다.)
# │   아래 367줄이 그 파일 내용 그대로이고, PUBLISHER_FILE_14_END 줄에서 끝난다.
# └── ▼ 실행 코드 [25] (아래 369줄이 한 덩어리) ────
cat > "$P/tepo/github-setup.sh" <<'PUBLISHER_FILE_14_END'
#!/bin/bash
# [1] 역할
#     GitHub 비공개 저장소를 만들고, 서버 정보를 Secrets 에 넣고, CI/CD 설정(ci.yml·deploy.yml)을 넣어 push 한 뒤 첫 배포를 지켜본다.
#     --push-only 로 실행하면 고친 코드만 다시 올리고 배포 결과를 지켜본다.
#     맨 윗줄 #!/bin/bash : "쉬뱅(shebang)". 이 파일을 /bin/bash 프로그램으로 실행하라는 표시.
#       #! 는 파일 맨 처음에만 쓰며, 뒤에 적힌 프로그램(위치)으로 이 파일을 실행한다.
#
# [2] 받는 것 → 내보내는 것
#     받는 것  : ops/infra.env, ops/secrets/lightsail_key, 소스 폴더 ~/ai-publisher
#     내보내는 것 (실제 값은 연습 bash tepo/mock/run-practice.sh 를 실행해 얻은 것. 가짜 aws 가 돌려준 값이다)
#       ✅ ci.yml(검사) · deploy.yml(배포) · .gitignore
#       ✅ commit 47dc67c
#       ✅ 저장소 만듦: https://github.com/sajang/ai-publisher
#       ✅ Secrets 4개 등록 (값은 GitHub 에만 저장됨)   ← LIGHTSAIL_HOST, LIGHTSAIL_USER, LIGHTSAIL_DOMAIN, LIGHTSAIL_SSH_KEY
#       ▶    배포 #4242 지켜보는 중 (보통 3~6분)
#       ✅ 배포 성공 — https://github.com/sajang/ai-publisher/actions/runs/4242
#
# [3] 앞뒤 파일
#     server-setup.sh 다음  →  (이 파일)  →  GitHub  →  .github/workflows/deploy.yml (GitHub 서버에서 실행)  →  라이트세일 서버
#
# [4] 메서드 목록
#     단계    하는 일                                                   --push-only 일 때
#     1/4     git init, templates 의 ci.yml·deploy.yml·gitignore 복사       건너뜀
#     2/4     git add -A, 바뀐 것이 있으면 commit                            실행
#     3/4     gh repo create --private, gh secret set 네 개                  건너뜀
#     4/4     git push → gh run list 로 배포 번호 → gh run watch              실행
#
# [5] 먼저 알 용어
#     git init·add·commit·push, gh repo create, gh secret set, gh run list·watch·view, git -c 이름=값
#
# [6] 읽는 순서
#     1/4 → 2/4 → 3/4 → 4/4
#
# [7] 다 읽고 확인
#     - SSH 비밀 열쇠를 --body 가 아니라 < 파일 로 넘기는 이유는? (명령줄 글자에 비밀이 남지 않게. 연습 기록에도 값이 없다)
#     - 비공개(--private) 저장소가 아니면 무엇이 보이는가? (코드. Secrets 값은 공개 저장소에서도 보이지 않는다)
#
# [0] 코드만 모아 보기 — 이 파일에서 실제로 실행되는 줄 전체. 아래 본문에서 ▼ 실행 코드 [번호] 를 찾으면 그 줄의 설명이 있다.
#     [1] source "$(dirname "$0")/common.sh"
#     [2] MODE="${1:-}"
#     [3] INFRA="$OPS/infra.env"
#     [4] [ -d "$REPO/publisher-dashboard" ] || fail "소스 폴더가 없어요: $REPO"
#     [5] cd "$REPO" || fail "소스 폴더로 갈 수 없어요: $REPO"
#     [6] if [ "$MODE" != "--push-only" ]; then
#     [7]   [ -s "$INFRA" ] || fail "서버 정보(ops/infra.env)가 없어요. 먼저 create-infra.sh → server-setup.sh"
#     [8]   say "1/4 저장소 준비 (CI/CD 설정 파일 넣기)"
#     [9]   [ -d .git ] || git init -q -b main
#     [10]   mkdir -p .github/workflows
#     [11]   cp "$TEPO/templates/ci.yml" .github/workflows/ci.yml
#     [12]   cp "$TEPO/templates/deploy.yml" .github/workflows/deploy.yml
#     [13]   cp "$TEPO/templates/gitignore" .gitignore
#     [14]   ok "ci.yml(검사) · deploy.yml(배포) · .gitignore"
#     [15] fi
#     [16] say "2/4 변경 내용 저장 (commit)"
#     [17] git add -A
#     [18] if ! git diff --cached --quiet; then
#     [19]   git -c user.name="${GIT_AUTHOR_NAME:-테포 (AI 배포 담당)}" -c user.email="${GIT_AUTHOR_EMAIL:-tepo@ai-pub…   (+1줄)
#     [20]   ok "commit $(git rev-parse --short HEAD)"
#     [21] else
#     [22]   ok "새로 저장할 변경 없음"
#     [23] fi
#     [24] if [ "$MODE" != "--push-only" ]; then
#     [25]   say "3/4 GitHub 비공개 저장소와 Secrets"
#     [26]   if ! gh repo view "$GH_REPO" >/dev/null 2>&1; then
#     [27]     gh repo create "$GH_REPO" --private --source . --remote origin >/dev/null
#     [28]     ok "저장소 만듦: $(gh repo view "$GH_REPO" --json url --jq .url)"
#     [29]   fi
#     [30]   git remote get-url origin >/dev/null 2>&1 || git remote add origin "$(gh repo view "$GH_REPO" --json url …
#     [31]   FULL="$(gh repo view "$GH_REPO" --json nameWithOwner --jq .nameWithOwner)"
#     [32]   gh secret set LIGHTSAIL_HOST    --repo "$FULL" --body "$(getv "$INFRA" IP)"
#     [33]   gh secret set LIGHTSAIL_USER    --repo "$FULL" --body "$(getv "$INFRA" SSH_USER)"
#     [34]   gh secret set LIGHTSAIL_DOMAIN  --repo "$FULL" --body "$(getv "$INFRA" HOST)"
#     [35]   gh secret set LIGHTSAIL_SSH_KEY --repo "$FULL" < "$SECRETS/lightsail_key"
#     [36]   ok "Secrets 4개 등록 (값은 GitHub 에만 저장됨)"
#     [37] fi
#     [38] say "4/4 올리기(push) → GitHub Actions 가 테스트 후 서버에 배포"
#     [39] gh auth setup-git >/dev/null 2>&1 || true
#     [40] git push -q -u origin main
#     [41] sleep 8
#     [42] RUN="$(gh run list --workflow deploy.yml --branch main --limit 1 --json databaseId --jq '.[0].databaseId')"
#     [43] [ -n "$RUN" ] || fail "배포 실행을 찾지 못했어요. 잠시 뒤 bash tepo/deploy-status.sh 로 확인해요."
#     [44] say "   배포 #$RUN 지켜보는 중 (보통 3~6분)"
#     [45] if gh run watch "$RUN" --exit-status >/dev/null; then
#     [46]   ok "배포 성공 — $(gh run view "$RUN" --json url --jq .url)"
#     [47] else
#     [48]   echo "❌ 배포 실패 — 실패한 부분:"
#     [49]   gh run view "$RUN" --log-failed 2>/dev/null | tail -40
#     [50]   exit 1
#     [51] fi

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 공용 설정 파일 common.sh 를 불러와 그 안의 변수(OPS, REPO …)와 함수(ok, fail …)를 이 파일에서 쓴다.
# │   source 파일        : 그 파일의 내용을 지금 이 자리에서 실행한다(새 프로그램을 띄우지 않음). 그래서 변수·함수가 이어진다.
# │   $0                 : 지금 실행 중인 파일 이름. 예) tepo/health.sh
# │   dirname            : 경로에서 폴더 부분만. 예) tepo/health.sh → tepo
# │   "$( … )/common.sh" : 결과 예) tepo/common.sh
# └── ▼ 실행 코드 [1] ───────────────
source "$(dirname "$0")/common.sh"

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 첫 번째 값. 없으면 빈 글자. 예) bash tepo/github-setup.sh --push-only → MODE="--push-only"
# │   처음 설정이면 비워 두고, 고친 코드만 다시 올릴 때 --push-only.
# └── ▼ 실행 코드 [2] ───────────────
MODE="${1:-}"

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 서버 정보 파일 위치.
# └── ▼ 실행 코드 [3] ───────────────
INFRA="$OPS/infra.env"

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 소스 폴더가 없으면 오류로 끝낸다.
# │   -d : 폴더가 있으면 참.
# └── ▼ 실행 코드 [4] ───────────────
[ -d "$REPO/publisher-dashboard" ] || fail "소스 폴더가 없어요: $REPO"

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 소스 폴더로 들어간다. 아래 git 명령은 모두 이 폴더에서 일한다.
# └── ▼ 실행 코드 [5] ───────────────
cd "$REPO" || fail "소스 폴더로 갈 수 없어요: $REPO"

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 처음 설정일 때만 아래 줄들(1단계)을 실행한다.
# └── ▼ 실행 코드 [6] ───────────────
if [ "$MODE" != "--push-only" ]; then

  # ┌── 설명 ──────────────────────────────────
  # │ ▶ 이 줄이 하는 일: 서버가 아직 없으면 오류로 끝낸다(배포할 곳이 없음).
  # └── ▼ 실행 코드 [7] ───────────────
  [ -s "$INFRA" ] || fail "서버 정보(ops/infra.env)가 없어요. 먼저 create-infra.sh → server-setup.sh"

  # ┌── 설명 ──────────────────────────────────
  # │ ▶ 이 줄이 하는 일: 1단계 제목.
  # └── ▼ 실행 코드 [8] ───────────────
  say "1/4 저장소 준비 (CI/CD 설정 파일 넣기)"

  # ┌── 설명 ──────────────────────────────────
  # │ ▶ 이 줄이 하는 일: 아직 git 저장소가 아니면 새로 만든다. 기본 가지 이름 = main.
  # │   .git     : git 기록이 들어 있는 숨김 폴더.
  # │   git init : 저장소 만들기. -q = 조용히, -b main = 첫 가지 이름.
  # └── ▼ 실행 코드 [9] ───────────────
  [ -d .git ] || git init -q -b main

  # ┌── 설명 ──────────────────────────────────
  # │ ▶ 이 줄이 하는 일: GitHub Actions 설정 폴더를 만든다. GitHub 는 이 폴더의 .yml 파일을 자동 작업으로 읽는다.
  # └── ▼ 실행 코드 [10] ──────────────
  mkdir -p .github/workflows

  # ┌── 설명 ──────────────────────────────────
  # │ ▶ 이 줄이 하는 일: ci.yml(PR 마다 자동 시험)을 저장소에 복사한다.
  # └── ▼ 실행 코드 [11] ──────────────
  cp "$TEPO/templates/ci.yml" .github/workflows/ci.yml

  # ┌── 설명 ──────────────────────────────────
  # │ ▶ 이 줄이 하는 일: deploy.yml(main 에 올리면 시험 후 서버에 배포)을 복사한다.
  # └── ▼ 실행 코드 [12] ──────────────
  cp "$TEPO/templates/deploy.yml" .github/workflows/deploy.yml

  # ┌── 설명 ──────────────────────────────────
  # │ ▶ 이 줄이 하는 일: .gitignore(올리지 않을 파일 목록: build/, ops/, *.env 등)를 복사한다.
  # └── ▼ 실행 코드 [13] ──────────────
  cp "$TEPO/templates/gitignore" .gitignore

  # ┌── 설명 ──────────────────────────────────
  # │ ▶ 이 줄이 하는 일: 세 파일을 넣었다고 알린다.
  # └── ▼ 실행 코드 [14] ──────────────
  ok "ci.yml(검사) · deploy.yml(배포) · .gitignore"

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 위 if 블록의 끝 (if 를 거꾸로 쓴 말)
# └── ▼ 실행 코드 [15] ──────────────
fi

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 2단계 제목.
# └── ▼ 실행 코드 [16] ──────────────
say "2/4 변경 내용 저장 (commit)"

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 바뀐 파일을 모두 commit 할 목록에 넣는다. .gitignore 에 적힌 것은 빠진다.
# │   -A : All. 새 파일·고친 파일·지운 파일 모두.
# └── ▼ 실행 코드 [17] ──────────────
git add -A

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: commit 할 목록에 바뀐 것이 있으면 아래 줄로 저장한다.
# │   --cached : add 로 넣은 목록을 본다.
# │   --quiet  : 내용은 찍지 않고, 바뀐 것이 있으면 실패(1)를 돌려준다. ! 로 뒤집어 "바뀐 것이 있으면".
# └── ▼ 실행 코드 [18] ──────────────
if ! git diff --cached --quiet; then

  # ┌── 설명 ──────────────────────────────────
  # │ ▶ 이 줄이 하는 일: 테포 이름으로 commit(저장 기록 하나)을 만든다. (줄 끝 \ = 다음 줄과 한 명령)
  # │   -c 이름=값             : 이번 명령에서만 git 설정을 바꾼다.
  # │   user.name / user.email : 기록에 남을 작성자. 정해 두지 않으면 "테포 (AI 배포 담당)".
  # │   commit -q -m "…"       : 조용히 저장, -m = 기록 설명.
  # └── ▼ 실행 코드 [19] (아래 2줄이 한 덩어리) ────
  git -c user.name="${GIT_AUTHOR_NAME:-테포 (AI 배포 담당)}" -c user.email="${GIT_AUTHOR_EMAIL:-tepo@ai-publisher.local}" \
      commit -q -m "${COMMIT_MESSAGE:-테포: 관리 화면 배포 설정}"

  # ┌── 설명 ──────────────────────────────────
  # │ ▶ 이 줄이 하는 일: 방금 만든 기록의 짧은 번호를 알린다. 예) ✅ commit 3f2a1bc
  # │   HEAD : 지금 가지의 가장 최근 기록.
  # └── ▼ 실행 코드 [20] ──────────────
  ok "commit $(git rev-parse --short HEAD)"

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 조건이 거짓일 때 실행할 부분의 시작
# └── ▼ 실행 코드 [21] ──────────────
else

  # ┌── 설명 ──────────────────────────────────
  # │ ▶ 이 줄이 하는 일: 바뀐 것이 없다고 알린다.
  # └── ▼ 실행 코드 [22] ──────────────
  ok "새로 저장할 변경 없음"

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 위 if 블록의 끝 (if 를 거꾸로 쓴 말)
# └── ▼ 실행 코드 [23] ──────────────
fi

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 처음 설정일 때만 3단계(저장소 만들기·Secrets)를 한다.
# └── ▼ 실행 코드 [24] ──────────────
if [ "$MODE" != "--push-only" ]; then

  # ┌── 설명 ──────────────────────────────────
  # │ ▶ 이 줄이 하는 일: 3단계 제목.
  # └── ▼ 실행 코드 [25] ──────────────
  say "3/4 GitHub 비공개 저장소와 Secrets"

  # ┌── 설명 ──────────────────────────────────
  # │ ▶ 이 줄이 하는 일: GitHub 에 그 이름의 저장소가 아직 없으면 아래 두 줄로 만든다.
  # └── ▼ 실행 코드 [26] ──────────────
  if ! gh repo view "$GH_REPO" >/dev/null 2>&1; then

    # ┌── 설명 ──────────────────────────────────
    # │ ▶ 이 줄이 하는 일: 비공개 저장소를 만들고 지금 폴더와 origin 이름으로 연결한다.
    # │   --private       : 나만 보이는 저장소.
    # │   --source .      : 지금 폴더를 그 저장소의 원본으로.
    # │   --remote origin : 올릴 곳 이름 = origin.
    # └── ▼ 실행 코드 [27] ──────────────
    gh repo create "$GH_REPO" --private --source . --remote origin >/dev/null

    # ┌── 설명 ──────────────────────────────────
    # │ ▶ 이 줄이 하는 일: 저장소 주소를 알린다. 예) ✅ 저장소 만듦: https://github.com/sajang/ai-publisher
    # └── ▼ 실행 코드 [28] ──────────────
    ok "저장소 만듦: $(gh repo view "$GH_REPO" --json url --jq .url)"

  # ┌── 설명 ──────────────────────────────────
  # │ ▶ 이 줄이 하는 일: 위 if 블록의 끝 (if 를 거꾸로 쓴 말)
  # └── ▼ 실행 코드 [29] ──────────────
  fi

  # ┌── 설명 ──────────────────────────────────
  # │ ▶ 이 줄이 하는 일: origin 이 아직 없으면(저장소는 예전에 만들었을 때) 그 주소로 연결한다.
  # └── ▼ 실행 코드 [30] ──────────────
  git remote get-url origin >/dev/null 2>&1 || git remote add origin "$(gh repo view "$GH_REPO" --json url --jq .url).git"

  # ┌── 설명 ──────────────────────────────────
  # │ ▶ 이 줄이 하는 일: 저장소의 "주인/이름". 예) sajang/ai-publisher
  # └── ▼ 실행 코드 [31] ──────────────
  FULL="$(gh repo view "$GH_REPO" --json nameWithOwner --jq .nameWithOwner)"

  # ┌── 설명 ──────────────────────────────────
  # │ ▶ 이 줄이 하는 일: GitHub Secrets 에 서버 IP 를 저장한다. deploy.yml 이 ${{ secrets.LIGHTSAIL_HOST }} 로 읽는다.
  # │   gh secret set 이름 : 저장소 비밀값 저장. 값은 GitHub 에만 암호화되어 남고 다시 볼 수 없다.
  # │   --body "값"        : 값을 직접 준다.
  # └── ▼ 실행 코드 [32] ──────────────
  gh secret set LIGHTSAIL_HOST    --repo "$FULL" --body "$(getv "$INFRA" IP)"

  # ┌── 설명 ──────────────────────────────────
  # │ ▶ 이 줄이 하는 일: 서버 접속 아이디(ubuntu)를 저장한다.
  # └── ▼ 실행 코드 [33] ──────────────
  gh secret set LIGHTSAIL_USER    --repo "$FULL" --body "$(getv "$INFRA" SSH_USER)"

  # ┌── 설명 ──────────────────────────────────
  # │ ▶ 이 줄이 하는 일: 서버 주소(…sslip.io)를 저장한다.
  # └── ▼ 실행 코드 [34] ──────────────
  gh secret set LIGHTSAIL_DOMAIN  --repo "$FULL" --body "$(getv "$INFRA" HOST)"

  # ┌── 설명 ──────────────────────────────────
  # │ ▶ 이 줄이 하는 일: SSH 열쇠 파일 내용을 저장한다. 값은 < 로 파일에서 읽어 넘긴다(화면에 안 나옴).
  # └── ▼ 실행 코드 [35] ──────────────
  gh secret set LIGHTSAIL_SSH_KEY --repo "$FULL" < "$SECRETS/lightsail_key"

  # ┌── 설명 ──────────────────────────────────
  # │ ▶ 이 줄이 하는 일: 등록했다고 알린다.
  # └── ▼ 실행 코드 [36] ──────────────
  ok "Secrets 4개 등록 (값은 GitHub 에만 저장됨)"

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 위 if 블록의 끝 (if 를 거꾸로 쓴 말)
# └── ▼ 실행 코드 [37] ──────────────
fi

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 4단계 제목.
# └── ▼ 실행 코드 [38] ──────────────
say "4/4 올리기(push) → GitHub Actions 가 테스트 후 서버에 배포"

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: git 이 GitHub 로그인(gh)을 쓰도록 연결한다. 실패해도 계속(|| true).
# └── ▼ 실행 코드 [39] ──────────────
gh auth setup-git >/dev/null 2>&1 || true

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: main 가지를 GitHub 에 올린다 → deploy.yml 이 시작된다(on: push: branches: [main]).
# │   -u : 앞으로 이 가지의 올릴 곳을 origin 으로 기억.
# └── ▼ 실행 코드 [40] ──────────────
git push -q -u origin main

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: GitHub 가 실행을 시작할 시간 8초를 기다린다.
# └── ▼ 실행 코드 [41] ──────────────
sleep 8

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 방금 시작된 배포 실행의 번호. 예) 4242
# └── ▼ 실행 코드 [42] ──────────────
RUN="$(gh run list --workflow deploy.yml --branch main --limit 1 --json databaseId --jq '.[0].databaseId')"

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 번호가 없으면 오류로 끝낸다.
# └── ▼ 실행 코드 [43] ──────────────
[ -n "$RUN" ] || fail "배포 실행을 찾지 못했어요. 잠시 뒤 bash tepo/deploy-status.sh 로 확인해요."

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 지켜보는 중이라고 알린다.
# └── ▼ 실행 코드 [44] ──────────────
say "   배포 #$RUN 지켜보는 중 (보통 3~6분)"

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 실행이 끝날 때까지 기다린다. 배포가 실패하면 이 명령도 실패한다.
# │   --exit-status : 실행 결과를 이 명령의 성공/실패로 돌려준다.
# └── ▼ 실행 코드 [45] ──────────────
if gh run watch "$RUN" --exit-status >/dev/null; then

  # ┌── 설명 ──────────────────────────────────
  # │ ▶ 이 줄이 하는 일: 성공과 실행 주소를 알린다.
  # └── ▼ 실행 코드 [46] ──────────────
  ok "배포 성공 — $(gh run view "$RUN" --json url --jq .url)"

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 조건이 거짓일 때 실행할 부분의 시작
# └── ▼ 실행 코드 [47] ──────────────
else

  # ┌── 설명 ──────────────────────────────────
  # │ ▶ 이 줄이 하는 일: 실패 제목을 찍는다.
  # └── ▼ 실행 코드 [48] ──────────────
  echo "❌ 배포 실패 — 실패한 부분:"

  # ┌── 설명 ──────────────────────────────────
  # │ ▶ 이 줄이 하는 일: 실패한 단계의 기록 끝 40줄을 보여 준다.
  # └── ▼ 실행 코드 [49] ──────────────
  gh run view "$RUN" --log-failed 2>/dev/null | tail -40

  # ┌── 설명 ──────────────────────────────────
  # │ ▶ 이 줄이 하는 일: 실패로 끝낸다.
  # └── ▼ 실행 코드 [50] ──────────────
  exit 1

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 위 if 블록의 끝 (if 를 거꾸로 쓴 말)
# └── ▼ 실행 코드 [51] ──────────────
fi
PUBLISHER_FILE_14_END

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 파일 ~/my-publisher/tepo/health.sh 를 만든다. (서버 관리 화면이 살아 있는지 확인한다. 쭌이 사장님께 "서버 괜찮아?"에 답할 때 쓴다.)
# │   아래 64줄이 그 파일 내용 그대로이고, PUBLISHER_FILE_15_END 줄에서 끝난다.
# └── ▼ 실행 코드 [26] (아래 66줄이 한 덩어리) ────
cat > "$P/tepo/health.sh" <<'PUBLISHER_FILE_15_END'
#!/bin/bash
# [1] 역할
#     서버 관리 화면이 살아 있는지 확인한다. 쭌이 사장님께 "서버 괜찮아?"에 답할 때 쓴다.
#     맨 윗줄 #!/bin/bash : "쉬뱅(shebang)". 이 파일을 /bin/bash 프로그램으로 실행하라는 표시.
#       #! 는 파일 맨 처음에만 쓰며, 뒤에 적힌 프로그램(위치)으로 이 파일을 실행한다.
#
# [2] 받는 것 → 내보내는 것
#     실행  bash tepo/health.sh
#     결과  ✅ https://3-35-10-20.sslip.io → {"status":"UP"}       응답이 없으면 ❌ https://… 응답 없음
#
# [3] 앞뒤 파일
#     ops/infra.env 의 HOST  →  (이 파일)  →  GET https://주소/actuator/health  →  application.yml 의 management 설정
#
# [4] 메서드 목록
#     줄        하는 일
#     HOST=…     ops/infra.env 에서 주소 읽기
#     curl       8초 안에 응답이 오면 내용을 보여 준다
#
# [5] 먼저 알 용어
#     curl -fsS --max-time, if R="$(…)"; then
#
# [6] 읽는 순서
#     HOST → curl
#
# [7] 다 읽고 확인
#     - 관리 화면은 켜져 있는데 Caddy 가 꺼져 있으면 결과는? (❌ 응답 없음. 바깥에서는 Caddy 를 거쳐야 한다)
#     - /actuator/health 는 로그인 없이 열리는가? (열린다. SecurityConfig 가 이 주소만 허용)
#
# [0] 코드만 모아 보기 — 이 파일에서 실제로 실행되는 줄 전체. 아래 본문에서 ▼ 실행 코드 [번호] 를 찾으면 그 줄의 설명이 있다.
#     [1] source "$(dirname "$0")/common.sh"
#     [2] HOST="$(getv "$OPS/infra.env" HOST)"
#     [3] [ -n "$HOST" ] || fail "서버 정보(ops/infra.env)가 없어요"
#     [4] if R="$(curl -fsS --max-time 8 "https://$HOST/actuator/health")"; then ok "https://$HOST → $R"; else fail "…

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 공용 설정 파일 common.sh 를 불러와 그 안의 변수(OPS, REPO …)와 함수(ok, fail …)를 이 파일에서 쓴다.
# │   source 파일        : 그 파일의 내용을 지금 이 자리에서 실행한다(새 프로그램을 띄우지 않음). 그래서 변수·함수가 이어진다.
# │   $0                 : 지금 실행 중인 파일 이름. 예) tepo/health.sh
# │   dirname            : 경로에서 폴더 부분만. 예) tepo/health.sh → tepo
# │   "$( … )/common.sh" : 결과 예) tepo/common.sh
# └── ▼ 실행 코드 [1] ───────────────
source "$(dirname "$0")/common.sh"

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: ops/infra.env 에서 서버 주소(HOST)를 읽는다. 예) 3-35-10-20.sslip.io
# └── ▼ 실행 코드 [2] ───────────────
HOST="$(getv "$OPS/infra.env" HOST)"

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 주소가 비어 있으면(서버를 아직 안 만들었으면) 오류로 끝낸다.
# │   || : 앞이 실패(= 비어 있음)일 때만 뒤를 실행.
# └── ▼ 실행 코드 [3] ───────────────
[ -n "$HOST" ] || fail "서버 정보(ops/infra.env)가 없어요"

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 서버의 /actuator/health 주소에 물어봐서 대답이 오면 ✅ 와 대답을, 안 오면 ❌ 를 찍는다.
# │   R="$(…)"         : 대답 내용을 R 에 담는다. 명령이 성공했는지가 if 의 조건이 된다.
# │   curl -f          : 서버가 오류 번호(404, 500 …)를 주면 실패로 본다.
# │   -sS              : 진행 글은 숨기고(-s), 오류 글은 보인다(-S).
# │   --max-time 8     : 8초 안에 대답이 없으면 실패.
# │   /actuator/health : Spring Boot 가 "살아 있음"을 알려 주는 주소. 대답 예) {"status":"UP"}
# │   then … else … fi : 성공이면 then 쪽, 실패면 else 쪽.
# └── ▼ 실행 코드 [4] ───────────────
if R="$(curl -fsS --max-time 8 "https://$HOST/actuator/health")"; then ok "https://$HOST → $R"; else fail "https://$HOST 응답 없음"; fi
PUBLISHER_FILE_15_END

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 파일 ~/my-publisher/tepo/install-tools.sh 를 만든다. (aws(AWS CLI v2)와 gh(GitHub CLI)가 없으면 내 홈 폴더(~/.local)에 설치한다. sudo(관리자 비밀번호)가 필요 없다.)
# │   아래 175줄이 그 파일 내용 그대로이고, PUBLISHER_FILE_16_END 줄에서 끝난다.
# └── ▼ 실행 코드 [27] (아래 177줄이 한 덩어리) ────
cat > "$P/tepo/install-tools.sh" <<'PUBLISHER_FILE_16_END'
#!/bin/bash
# [1] 역할
#     aws(AWS CLI v2)와 gh(GitHub CLI)가 없으면 내 홈 폴더(~/.local)에 설치한다. sudo(관리자 비밀번호)가 필요 없다.
#     맨 윗줄 #!/bin/bash : "쉬뱅(shebang)". 이 파일을 /bin/bash 프로그램으로 실행하라는 표시.
#       #! 는 파일 맨 처음에만 쓰며, 뒤에 적힌 프로그램(위치)으로 이 파일을 실행한다.
#
# [2] 받는 것 → 내보내는 것
#     이미 있으면  ✅ aws aws-cli/2.39.7   ✅ gh version 2.x.x
#     없으면       ▶ AWS CLI 설치 중 (~/.local/aws-cli)  → ~/.local/bin/aws
#
# [3] 앞뒤 파일
#     preflight.sh  →  (이 파일)  →  ~/.local/bin/aws, ~/.local/bin/gh
#
# [4] 메서드 목록
#     구역       하는 일
#     aws        컴퓨터 종류(uname -m)에 맞는 zip 을 받아 ~/.local/aws-cli 에 설치
#     gh         GitHub 에서 최신 버전 번호를 읽고 tar.gz 를 받아 ~/.local/bin/gh 로
#
# [5] 먼저 알 용어
#     command -v, case … esac, mktemp -d, trap … EXIT, curl -fsSL, unzip, tar, install -m 755
#
# [6] 읽는 순서
#     aws 구역 → gh 구역
#
# [7] 다 읽고 확인
#     - trap 'rm -rf "$TMP"' EXIT 가 없으면 무엇이 남는가? (내려받은 zip 과 압축 푼 폴더)
#     - 회사 컴퓨터처럼 sudo 를 못 쓰는 곳에서도 설치되는 이유는? (내 홈 폴더 안에만 쓴다)
#
# [0] 코드만 모아 보기 — 이 파일에서 실제로 실행되는 줄 전체. 아래 본문에서 ▼ 실행 코드 [번호] 를 찾으면 그 줄의 설명이 있다.
#     [1] source "$(dirname "$0")/common.sh"
#     [2] mkdir -p "$HOME/.local/bin"
#     [3] ARCH="$(uname -m)"
#     [4] TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
#     [5] if ! command -v aws >/dev/null; then
#     [6]   say "AWS CLI 설치 중 (~/.local/aws-cli)"
#     [7]   case "$ARCH" in aarch64|arm64) Z=awscli-exe-linux-aarch64.zip ;; *) Z=awscli-exe-linux-x86_64.zip ;; esac
#     [8]   curl -fsSL "https://awscli.amazonaws.com/$Z" -o "$TMP/aws.zip"
#     [9]   (cd "$TMP" && unzip -q aws.zip && ./aws/install -i "$HOME/.local/aws-cli" -b "$HOME/.local/bin" --update …
#     [10] fi
#     [11] command -v aws >/dev/null && ok "aws $(aws --version 2>&1 | cut -d' ' -f1)"
#     [12] if ! command -v gh >/dev/null; then
#     [13]   say "GitHub CLI 설치 중 (~/.local/bin/gh)"
#     [14]   case "$ARCH" in aarch64|arm64) A=arm64 ;; *) A=amd64 ;; esac
#     [15]   V="$(curl -fsSL https://api.github.com/repos/cli/cli/releases/latest | python3 -c 'import json,sys;print(…
#     [16]   curl -fsSL "https://github.com/cli/cli/releases/download/v$V/gh_${V}_linux_$A.tar.gz" -o "$TMP/gh.tgz"
#     [17]   tar -xzf "$TMP/gh.tgz" -C "$TMP"
#     [18]   install -m 755 "$TMP/gh_${V}_linux_$A/bin/gh" "$HOME/.local/bin/gh"
#     [19] fi
#     [20] command -v gh >/dev/null && ok "$(gh --version | head -1)"

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 공용 설정 파일 common.sh 를 불러와 그 안의 변수(OPS, REPO …)와 함수(ok, fail …)를 이 파일에서 쓴다.
# │   source 파일        : 그 파일의 내용을 지금 이 자리에서 실행한다(새 프로그램을 띄우지 않음). 그래서 변수·함수가 이어진다.
# │   $0                 : 지금 실행 중인 파일 이름. 예) tepo/health.sh
# │   dirname            : 경로에서 폴더 부분만. 예) tepo/health.sh → tepo
# │   "$( … )/common.sh" : 결과 예) tepo/common.sh
# └── ▼ 실행 코드 [1] ───────────────
source "$(dirname "$0")/common.sh"

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 내 홈 안의 프로그램 폴더 ~/.local/bin 을 만든다. 여기에 설치하면 sudo(관리자 권한)가 필요 없다.
# └── ▼ 실행 코드 [2] ───────────────
mkdir -p "$HOME/.local/bin"

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 이 컴퓨터의 CPU 종류를 ARCH 에 담는다. 예) x86_64 (보통 PC), aarch64 (ARM)
# │   uname -m : 컴퓨터 종류(machine)를 찍는 명령.
# └── ▼ 실행 코드 [3] ───────────────
ARCH="$(uname -m)"

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 빈 임시 폴더를 만들고, 스크립트가 끝나면(성공·실패 모두) 그 폴더를 지우게 예약한다.
# │   mktemp -d        : 이름이 겹치지 않는 빈 임시 폴더를 만들고 경로를 찍는다. 예) /tmp/tmp.Ab12Cd
# │   trap '명령' EXIT : 스크립트가 끝날 때 명령을 실행하도록 걸어 둔다.
# │   rm -rf           : 폴더를 안의 파일까지 지운다.
# └── ▼ 실행 코드 [4] ───────────────
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: aws 명령이 없을 때만 아래 4줄로 AWS CLI 를 설치한다.
# │   command -v aws : aws 가 어디 있는지 찾는다. 있으면 성공.
# │   !              : 결과를 뒤집는다(없으면 참).
# └── ▼ 실행 코드 [5] ───────────────
if ! command -v aws >/dev/null; then

  # ┌── 설명 ──────────────────────────────────
  # │ ▶ 이 줄이 하는 일: 설치를 시작한다고 알린다.
  # └── ▼ 실행 코드 [6] ───────────────
  say "AWS CLI 설치 중 (~/.local/aws-cli)"

  # ┌── 설명 ──────────────────────────────────
  # │ ▶ 이 줄이 하는 일: CPU 종류에 맞는 AWS CLI 설치 파일 이름을 Z 에 담는다.
  # │   aarch64|arm64) : ARM 이면 aarch64 용.
  # │   *)             : 그 밖(보통 PC)이면 x86_64 용.
  # └── ▼ 실행 코드 [7] ───────────────
  case "$ARCH" in aarch64|arm64) Z=awscli-exe-linux-aarch64.zip ;; *) Z=awscli-exe-linux-x86_64.zip ;; esac

  # ┌── 설명 ──────────────────────────────────
  # │ ▶ 이 줄이 하는 일: AWS 공식 주소에서 설치 파일을 임시 폴더에 aws.zip 으로 내려받는다.
  # │   -L      : 주소가 다른 곳으로 넘겨 주면 따라간다.
  # │   -o 파일 : 받은 내용을 그 파일로 저장.
  # └── ▼ 실행 코드 [8] ───────────────
  curl -fsSL "https://awscli.amazonaws.com/$Z" -o "$TMP/aws.zip"

  # ┌── 설명 ──────────────────────────────────
  # │ ▶ 이 줄이 하는 일: 압축을 풀고, 설치 프로그램으로 ~/.local/aws-cli 에 설치한 뒤 aws 명령을 ~/.local/bin 에 둔다.
  # │   ( … )                   : 괄호 안은 따로 떨어진 셸에서 실행 → cd 해도 바깥 위치는 그대로.
  # │   unzip -q                : 조용히 압축 풀기.
  # │   ./aws/install -i … -b … : -i = 설치할 폴더, -b = 명령(aws)을 둘 폴더.
  # │   --update                : 이미 있으면 새 판으로 바꾼다.
  # └── ▼ 실행 코드 [9] ───────────────
  (cd "$TMP" && unzip -q aws.zip && ./aws/install -i "$HOME/.local/aws-cli" -b "$HOME/.local/bin" --update >/dev/null)

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 위 if 블록의 끝 (if 를 거꾸로 쓴 말)
# └── ▼ 실행 코드 [10] ──────────────
fi

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: aws 가 있으면 판 번호와 함께 ✅ 를 찍는다. 예) ✅ aws aws-cli/2.17.0
# │   aws --version 2>&1 : 판 글을 찍는다(오류 출력으로 나오는 판도 있어 2>&1 로 합침).
# │   cut -d' ' -f1      : 띄어쓰기로 나눠 첫 칸만.
# └── ▼ 실행 코드 [11] ──────────────
command -v aws >/dev/null && ok "aws $(aws --version 2>&1 | cut -d' ' -f1)"

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: gh(GitHub CLI)가 없을 때만 아래 5줄로 설치한다.
# └── ▼ 실행 코드 [12] ──────────────
if ! command -v gh >/dev/null; then

  # ┌── 설명 ──────────────────────────────────
  # │ ▶ 이 줄이 하는 일: 설치를 시작한다고 알린다.
  # └── ▼ 실행 코드 [13] ──────────────
  say "GitHub CLI 설치 중 (~/.local/bin/gh)"

  # ┌── 설명 ──────────────────────────────────
  # │ ▶ 이 줄이 하는 일: CPU 종류에 맞는 이름(arm64 / amd64)을 A 에 담는다.
  # └── ▼ 실행 코드 [14] ──────────────
  case "$ARCH" in aarch64|arm64) A=arm64 ;; *) A=amd64 ;; esac

  # ┌── 설명 ──────────────────────────────────
  # │ ▶ 이 줄이 하는 일: GitHub 에 gh 의 최신 판 번호를 물어 V 에 담는다. 예) 2.62.0
  # │   releases/latest : 가장 최근에 낸 판 정보(JSON).
  # │   python3 -c '…'  : JSON 에서 tag_name(예: v2.62.0)을 꺼내 앞의 v 를 뗀다.
  # └── ▼ 실행 코드 [15] ──────────────
  V="$(curl -fsSL https://api.github.com/repos/cli/cli/releases/latest | python3 -c 'import json,sys;print(json.load(sys.stdin)["tag_name"].lstrip("v"))')"

  # ┌── 설명 ──────────────────────────────────
  # │ ▶ 이 줄이 하는 일: 그 판의 리눅스용 압축 파일을 내려받는다.
  # │   gh_${V}_linux_$A.tar.gz : 예) gh_2.62.0_linux_amd64.tar.gz
  # └── ▼ 실행 코드 [16] ──────────────
  curl -fsSL "https://github.com/cli/cli/releases/download/v$V/gh_${V}_linux_$A.tar.gz" -o "$TMP/gh.tgz"

  # ┌── 설명 ──────────────────────────────────
  # │ ▶ 이 줄이 하는 일: 압축을 임시 폴더에 푼다.
  # │   tar -x : 풀기. -z = gzip 압축, -f = 파일 이름. -C 폴더 = 거기에 풀기.
  # └── ▼ 실행 코드 [17] ──────────────
  tar -xzf "$TMP/gh.tgz" -C "$TMP"

  # ┌── 설명 ──────────────────────────────────
  # │ ▶ 이 줄이 하는 일: gh 실행 파일을 ~/.local/bin/gh 로 복사하고 실행할 수 있게 한다.
  # │   install : 복사 + 권한 정하기를 한 번에.
  # │   -m 755  : 주인은 읽기·쓰기·실행, 다른 사람은 읽기·실행.
  # └── ▼ 실행 코드 [18] ──────────────
  install -m 755 "$TMP/gh_${V}_linux_$A/bin/gh" "$HOME/.local/bin/gh"

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 위 if 블록의 끝 (if 를 거꾸로 쓴 말)
# └── ▼ 실행 코드 [19] ──────────────
fi

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: gh 가 있으면 판 글 첫 줄과 함께 ✅ 를 찍는다. 예) ✅ gh version 2.62.0 (…)
# └── ▼ 실행 코드 [20] ──────────────
command -v gh >/dev/null && ok "$(gh --version | head -1)"
PUBLISHER_FILE_16_END

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 파일 ~/my-publisher/tepo/mock/aws 를 만든다. (연습 전용 가짜 명령. tepo/mock/run-practice.sh 가 PATH 맨 앞에 이 폴더를 넣어, 테포 스크립트가 진짜 대신 이 파일을 부르게 한다.)
# │   아래 230줄이 그 파일 내용 그대로이고, PUBLISHER_FILE_17_END 줄에서 끝난다.
# └── ▼ 실행 코드 [28] (아래 232줄이 한 덩어리) ────
cat > "$P/tepo/mock/aws" <<'PUBLISHER_FILE_17_END'
#!/bin/bash
# [1] 역할
#     연습 전용 가짜 명령. tepo/mock/run-practice.sh 가 PATH 맨 앞에 이 폴더를 넣어, 테포 스크립트가 진짜 대신 이 파일을 부르게 한다.
#     부른 명령은 $MOCK_DIR/calls.log 에 한 줄씩 남는다. 진짜 AWS·GitHub·서버에는 아무것도 하지 않는다.
#     가짜 aws: 명령에 따라 미리 정한 답을 찍고, 만든 것은 $MOCK_DIR 의 빈 파일로 기억한다(두 번째 실행 때 "이미 있음"이 되게).
#     맨 윗줄 #!/bin/bash : "쉬뱅(shebang)". 이 파일을 /bin/bash 프로그램으로 실행하라는 표시.
#       #! 는 파일 맨 처음에만 쓰며, 뒤에 적힌 프로그램(위치)으로 이 파일을 실행한다.
#
# [2] 받는 것 → 내보내는 것
#     aws sts get-caller-identity          → 123456789012
#     aws … lightsail get-bundles …        → small_3_0  12.0  2.0  2
#     aws … get-static-ip … ipAddress      → 3.35.10.20
#     aws … create-relational-database …   → $MOCK_DIR/db 파일을 만든다.  calls.log 에는 --master-user-password **** 로 가려 남긴다
#     aws … delete-…                       → "가짜 aws: 지우기는 연습에서도 막혀 있어요" (실패)
#
# [3] 앞뒤 파일
#     tepo/mock/run-practice.sh (PATH)  →  common.sh 의 lsail  →  (이 파일)
#
# [4] 메서드 목록
#     구역                하는 일
#     calls.log 기록       비밀번호는 **** 로 바꿔 남긴다
#     case                명령 글자에 따라 답하기
#
# [5] 먼저 알 용어
#     case 와 *"글자"* 패턴, $@, sed -E, exit 254(없음)
#
# [6] 읽는 순서
#     calls.log 줄 → case
#
# [7] 다 읽고 확인
#     - get-relational-database 의 state 를 처음 두 번은 creating 으로 답하는 이유는? (create-infra.sh 의 "기다리기" 반복을 연습하려고)
#     - 모르는 명령이 오면 왜 실패로 끝내는가? (스크립트가 바뀌었는데 가짜가 따라가지 못한 것을 바로 알게)
#
# [0] 코드만 모아 보기 — 이 파일에서 실제로 실행되는 줄 전체. 아래 본문에서 ▼ 실행 코드 [번호] 를 찾으면 그 줄의 설명이 있다.
#     [1] D="${MOCK_DIR:?}"; echo "aws $*" | sed -E "s/(--master-user-password) [^ ]+/\1 ****/" >> "$D/calls.log"
#     [2] args=" $* "; q=""; prev=""
#     [3] for a in "$@"; do [ "$prev" = "--query" ] && q="$a"; prev="$a"; done
#     [4] has() { [[ "$args" == *" $1 "* ]]; }
#     [5] case "$args" in
#     [6]   *" --version "*) echo "aws-cli/2 (가짜·연습용)" ;;
#     [7]   *" sts get-caller-identity "*) echo 123456789012 ;;
#     [8]   *" get-bundles "*) printf 'small_3_0\t12.0\t2.0\t2\n' ;;
#     [9]   *" get-blueprints "*) echo ubuntu_24_04 ;;
#     [10]   *" get-relational-database-bundles "*) printf 'micro_2_0\t15.0\t1.0\n' ;;
#     [11]   *" get-relational-database-blueprints "*) echo mysql_8_0 ;;
#     [12]   *" get-key-pair "*) [ -f "$D/key" ] ;;
#     [13]   *" import-key-pair "*) touch "$D/key" ;;
#     [14]   *" get-instance-state "*) echo running ;;
#     [15]   *" get-instance "*) [ -f "$D/instance" ] ;;
#     [16]   *" create-instances "*) touch "$D/instance" ;;
#     [17]   *" get-static-ip "*)
#     [18]      [ -f "$D/ip" ] || exit 254
#     [19]      case "$q" in *attachedTo*) [ -f "$D/attached" ] && echo publisher-office || echo None ;; *ipAddress*) …
#     [20]   *" allocate-static-ip "*) touch "$D/ip" ;;
#     [21]   *" attach-static-ip "*) touch "$D/attached" ;;
#     [22]   *" put-instance-public-ports "*) : ;;
#     [23]   *" create-relational-database "*) touch "$D/db" ;;
#     [24]   *" get-relational-database "*)
#     [25]      [ -f "$D/db" ] || exit 254
#     [26]      case "$q" in
#     [27]        *state*) n=$(cat "$D/dbpoll" 2>/dev/null || echo 0); echo $((n+1)) > "$D/dbpoll"; [ "$n" -ge 2 ] && …
#     [28]        *masterEndpoint*) printf 'ls-abc123.cluster.ap-northeast-2.rds.amazonaws.com\t3306\n' ;;
#     [29]      esac ;;
#     [30]   *" delete-"*|*" release-static-ip "*) echo "가짜 aws: 지우기는 연습에서도 막혀 있어요" >&2; exit 1 ;;
#     [31]   *) echo "가짜 aws: 모르는 명령 $*" >&2; exit 1 ;;
#     [32] esac

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 불린 aws 명령을 기록한다. 단 DB 비밀번호 값은 **** 로 가린다.
# │   sed -E "s/(앞) [^ ]+/\1 ****/" : --master-user-password 뒤의 낱말 하나를 **** 로 바꾼다. -E = 확장 정규식.
# │   [^ ]+                          : 띄어쓰기가 아닌 글자 1개 이상(= 낱말 하나).
# └── ▼ 실행 코드 [1] ───────────────
D="${MOCK_DIR:?}"; echo "aws $*" | sed -E "s/(--master-user-password) [^ ]+/\1 ****/" >> "$D/calls.log"

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 받은 값 전체(앞뒤 띄어쓰기 붙임)를 args 에, --query 값을 담을 q, 바로 앞 값을 기억할 prev 를 준비한다.
# └── ▼ 실행 코드 [2] ───────────────
args=" $* "; q=""; prev=""

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 값을 하나씩 보며 --query 바로 뒤 값을 q 에 담는다. 예) --query state.name → q=state.name
# └── ▼ 실행 코드 [3] ───────────────
for a in "$@"; do [ "$prev" = "--query" ] && q="$a"; prev="$a"; done

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: has 함수: args 에 그 낱말이 있는지. (지금은 쓰지 않지만 남겨 둔 도구)
# │   [[ … == *" $1 "* ]] : * = 아무 글자. 앞뒤 띄어쓰기로 낱말 단위로 찾는다.
# └── ▼ 실행 코드 [4] ───────────────
has() { [[ "$args" == *" $1 "* ]]; }

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 명령 글자에 따라 가짜 대답을 고른다. 위에서부터 처음 맞는 것 하나만 실행한다.
# └── ▼ 실행 코드 [5] ───────────────
case "$args" in

  # ┌── 설명 ──────────────────────────────────
  # │ ▶ 이 줄이 하는 일: aws --version → 가짜 판 글.
  # └── ▼ 실행 코드 [6] ───────────────
  *" --version "*) echo "aws-cli/2 (가짜·연습용)" ;;

  # ┌── 설명 ──────────────────────────────────
  # │ ▶ 이 줄이 하는 일: 열쇠 주인 묻기 → 가짜 계정 번호.
  # └── ▼ 실행 코드 [7] ───────────────
  *" sts get-caller-identity "*) echo 123456789012 ;;

  # ┌── 설명 ──────────────────────────────────
  # │ ▶ 이 줄이 하는 일: 서버 요금제 → 탭으로 나뉜 한 줄 "small_3_0 12.0 2.0 2".
  # │   printf '…\t…\n' : \t = 탭, \n = 줄바꿈.
  # └── ▼ 실행 코드 [8] ───────────────
  *" get-bundles "*) printf 'small_3_0\t12.0\t2.0\t2\n' ;;

  # ┌── 설명 ──────────────────────────────────
  # │ ▶ 이 줄이 하는 일: 운영체제 → ubuntu_24_04.
  # └── ▼ 실행 코드 [9] ───────────────
  *" get-blueprints "*) echo ubuntu_24_04 ;;

  # ┌── 설명 ──────────────────────────────────
  # │ ▶ 이 줄이 하는 일: DB 요금제 → "micro_2_0 15.0 1.0".
  # └── ▼ 실행 코드 [10] ──────────────
  *" get-relational-database-bundles "*) printf 'micro_2_0\t15.0\t1.0\n' ;;

  # ┌── 설명 ──────────────────────────────────
  # │ ▶ 이 줄이 하는 일: DB 종류 → mysql_8_0.
  # └── ▼ 실행 코드 [11] ──────────────
  *" get-relational-database-blueprints "*) echo mysql_8_0 ;;

  # ┌── 설명 ──────────────────────────────────
  # │ ▶ 이 줄이 하는 일: 열쇠가 있는지 → key 표시 파일이 있으면 성공.
  # └── ▼ 실행 코드 [12] ──────────────
  *" get-key-pair "*) [ -f "$D/key" ] ;;

  # ┌── 설명 ──────────────────────────────────
  # │ ▶ 이 줄이 하는 일: 열쇠 올리기 → key 표시 파일을 만든다.
  # └── ▼ 실행 코드 [13] ──────────────
  *" import-key-pair "*) touch "$D/key" ;;

  # ┌── 설명 ──────────────────────────────────
  # │ ▶ 이 줄이 하는 일: 서버 상태 → 늘 running. (get-instance 보다 먼저 적어야 이 줄이 먼저 맞는다)
  # └── ▼ 실행 코드 [14] ──────────────
  *" get-instance-state "*) echo running ;;

  # ┌── 설명 ──────────────────────────────────
  # │ ▶ 이 줄이 하는 일: 서버가 있는지 → instance 표시 파일.
  # └── ▼ 실행 코드 [15] ──────────────
  *" get-instance "*) [ -f "$D/instance" ] ;;

  # ┌── 설명 ──────────────────────────────────
  # │ ▶ 이 줄이 하는 일: 서버 만들기 → instance 표시 파일을 만든다.
  # └── ▼ 실행 코드 [16] ──────────────
  *" create-instances "*) touch "$D/instance" ;;

  # ┌── 설명 ──────────────────────────────────
  # │ ▶ 이 줄이 하는 일: 고정 IP 묻기 → 아래 두 줄.
  # └── ▼ 실행 코드 [17] ──────────────
  *" get-static-ip "*)

     # ┌── 설명 ──────────────────────────────────
     # │ ▶ 이 줄이 하는 일: 아직 IP 를 안 받았으면 진짜 aws 처럼 오류 번호 254 로 끝낸다.
     # └── ▼ 실행 코드 [18] ──────────────
     [ -f "$D/ip" ] || exit 254

     # ┌── 설명 ──────────────────────────────────
     # │ ▶ 이 줄이 하는 일: 무엇을 물었는지(q)에 따라: 붙은 곳 → publisher-office 또는 None, 주소 → 3.35.10.20.
     # └── ▼ 실행 코드 [19] ──────────────
     case "$q" in *attachedTo*) [ -f "$D/attached" ] && echo publisher-office || echo None ;; *ipAddress*) echo 3.35.10.20 ;; esac ;;

  # ┌── 설명 ──────────────────────────────────
  # │ ▶ 이 줄이 하는 일: 고정 IP 받기 → ip 표시 파일.
  # └── ▼ 실행 코드 [20] ──────────────
  *" allocate-static-ip "*) touch "$D/ip" ;;

  # ┌── 설명 ──────────────────────────────────
  # │ ▶ 이 줄이 하는 일: 붙이기 → attached 표시 파일.
  # └── ▼ 실행 코드 [21] ──────────────
  *" attach-static-ip "*) touch "$D/attached" ;;

  # ┌── 설명 ──────────────────────────────────
  # │ ▶ 이 줄이 하는 일: 방화벽 → 아무것도 안 하고 성공.
  # └── ▼ 실행 코드 [22] ──────────────
  *" put-instance-public-ports "*) : ;;

  # ┌── 설명 ──────────────────────────────────
  # │ ▶ 이 줄이 하는 일: DB 만들기 → db 표시 파일.
  # └── ▼ 실행 코드 [23] ──────────────
  *" create-relational-database "*) touch "$D/db" ;;

  # ┌── 설명 ──────────────────────────────────
  # │ ▶ 이 줄이 하는 일: DB 묻기 → 아래 줄들.
  # └── ▼ 실행 코드 [24] ──────────────
  *" get-relational-database "*)

     # ┌── 설명 ──────────────────────────────────
     # │ ▶ 이 줄이 하는 일: DB 를 아직 안 만들었으면 오류 254.
     # └── ▼ 실행 코드 [25] ──────────────
     [ -f "$D/db" ] || exit 254

     # ┌── 설명 ──────────────────────────────────
     # │ ▶ 이 줄이 하는 일: 물은 것에 따라 대답한다.
     # └── ▼ 실행 코드 [26] ──────────────
     case "$q" in

       # ┌── 설명 ──────────────────────────────────
       # │ ▶ 이 줄이 하는 일: 상태: 처음 두 번은 creating, 세 번째부터 available. (기다리는 반복이 실제로 도는지 보려고) 물은 횟수는 dbpoll 파일에 센다.
       # └── ▼ 실행 코드 [27] ──────────────
       *state*) n=$(cat "$D/dbpoll" 2>/dev/null || echo 0); echo $((n+1)) > "$D/dbpoll"; [ "$n" -ge 2 ] && echo available || echo creating ;;

       # ┌── 설명 ──────────────────────────────────
       # │ ▶ 이 줄이 하는 일: 접속 주소와 포트 → 가짜 주소 + 3306.
       # └── ▼ 실행 코드 [28] ──────────────
       *masterEndpoint*) printf 'ls-abc123.cluster.ap-northeast-2.rds.amazonaws.com\t3306\n' ;;

     # ┌── 설명 ──────────────────────────────────
     # │ ▶ 이 줄이 하는 일: 안쪽 case 의 끝, 그리고 이 항목의 끝(;;).
     # └── ▼ 실행 코드 [29] ──────────────
     esac ;;

  # ┌── 설명 ──────────────────────────────────
  # │ ▶ 이 줄이 하는 일: 지우기·IP 놓기 명령 → 연습에서도 막는다(실수로 지우는 흐름을 연습하지 않게).
  # └── ▼ 실행 코드 [30] ──────────────
  *" delete-"*|*" release-static-ip "*) echo "가짜 aws: 지우기는 연습에서도 막혀 있어요" >&2; exit 1 ;;

  # ┌── 설명 ──────────────────────────────────
  # │ ▶ 이 줄이 하는 일: 그 밖의 명령 → 모른다고 알리고 실패.
  # └── ▼ 실행 코드 [31] ──────────────
  *) echo "가짜 aws: 모르는 명령 $*" >&2; exit 1 ;;

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 위 case 블록의 끝 (case 를 거꾸로 쓴 말)
# └── ▼ 실행 코드 [32] ──────────────
esac
PUBLISHER_FILE_17_END

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 파일 ~/my-publisher/tepo/mock/curl 를 만든다. (연습 전용 가짜 명령. tepo/mock/run-practice.sh 가 PATH 맨 앞에 이 폴더를 넣어, 테포 스크립트가 진짜 대신 이 파일을 부르게 한다.)
# │   아래 49줄이 그 파일 내용 그대로이고, PUBLISHER_FILE_18_END 줄에서 끝난다.
# └── ▼ 실행 코드 [29] (아래 51줄이 한 덩어리) ────
cat > "$P/tepo/mock/curl" <<'PUBLISHER_FILE_18_END'
#!/bin/bash
# [1] 역할
#     연습 전용 가짜 명령. tepo/mock/run-practice.sh 가 PATH 맨 앞에 이 폴더를 넣어, 테포 스크립트가 진짜 대신 이 파일을 부르게 한다.
#     부른 명령은 $MOCK_DIR/calls.log 에 한 줄씩 남는다. 진짜 AWS·GitHub·서버에는 아무것도 하지 않는다.
#     가짜 curl: …sslip.io/actuator/health 만 가짜로 {"status":"UP"} 을 답하고, 나머지는 진짜 curl 을 실행한다(도구 설치 등).
#     맨 윗줄 #!/bin/bash : "쉬뱅(shebang)". 이 파일을 /bin/bash 프로그램으로 실행하라는 표시.
#       #! 는 파일 맨 처음에만 쓰며, 뒤에 적힌 프로그램(위치)으로 이 파일을 실행한다.
#
# [2] 받는 것 → 내보내는 것
#     curl https://3-35-10-20.sslip.io/actuator/health → {"status":"UP"}
#
# [3] 앞뒤 파일
#     server-setup.sh, health.sh  →  (이 파일)
#
# [4] 메서드 목록
#     줄     하는 일
#     for     인자 중 health 주소가 있으면 가짜 답
#     exec    아니면 진짜 /usr/bin/curl 로 바꿔 실행
#
# [5] 먼저 알 용어
#     exec, case 패턴
#
# [6] 읽는 순서
#     위에서 아래로
#
# [7] 다 읽고 확인
#     - exec 를 쓰면 이 스크립트는 어떻게 되는가? (진짜 curl 로 바뀌고 돌아오지 않는다)
#     - 가짜 주소가 아닌 요청은 기록되는가? (아니다)
#
# [0] 코드만 모아 보기 — 이 파일에서 실제로 실행되는 줄 전체. 아래 본문에서 ▼ 실행 코드 [번호] 를 찾으면 그 줄의 설명이 있다.
#     [1] for a in "$@"; do case "$a" in https://*sslip.io/actuator/health) echo "curl $a" >> "${MOCK_DIR:?}/calls.lo…
#     [2] exec /usr/bin/curl "$@"

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 받은 값 중에 …sslip.io/actuator/health 주소가 있으면 기록을 남기고 가짜 대답 {"status":"UP"} 을 찍고 끝낸다.
# │   for a in "$@"                     : 받은 값을 하나씩 a 에 넣으며 반복.
# │   case "$a" in 모양) … ;; esac      : a 가 모양과 맞으면 실행.
# │   https://*sslip.io/actuator/health : * = 아무 글자. 서버 주소가 무엇이든 health 주소면 맞음.
# │   ${MOCK_DIR:?}                     : MOCK_DIR 이 비어 있으면 오류로 멈춘다(연습 아닐 때 실수로 쓰이지 않게).
# │   >> calls.log                      : 기록 파일 끝에 덧붙인다.
# │   exit 0                            : 성공으로 끝낸다.
# └── ▼ 실행 코드 [1] ───────────────
for a in "$@"; do case "$a" in https://*sslip.io/actuator/health) echo "curl $a" >> "${MOCK_DIR:?}/calls.log"; echo '{"status":"UP"}'; exit 0 ;; esac; done

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 그 밖의 요청은 진짜 curl 로 바꿔 실행한다(도구 내려받기 등).
# │   exec : 이 스크립트를 진짜 curl 로 바꿔치기한다. 돌아오지 않는다.
# └── ▼ 실행 코드 [2] ───────────────
exec /usr/bin/curl "$@"
PUBLISHER_FILE_18_END

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 파일 ~/my-publisher/tepo/mock/gh 를 만든다. (연습 전용 가짜 명령. tepo/mock/run-practice.sh 가 PATH 맨 앞에 이 폴더를 넣어, 테포 스크립트가 진짜 대신 이 파일을 부르게 한다.)
# │   아래 132줄이 그 파일 내용 그대로이고, PUBLISHER_FILE_19_END 줄에서 끝난다.
# └── ▼ 실행 코드 [30] (아래 134줄이 한 덩어리) ────
cat > "$P/tepo/mock/gh" <<'PUBLISHER_FILE_19_END'
#!/bin/bash
# [1] 역할
#     연습 전용 가짜 명령. tepo/mock/run-practice.sh 가 PATH 맨 앞에 이 폴더를 넣어, 테포 스크립트가 진짜 대신 이 파일을 부르게 한다.
#     부른 명령은 $MOCK_DIR/calls.log 에 한 줄씩 남는다. 진짜 AWS·GitHub·서버에는 아무것도 하지 않는다.
#     가짜 gh: 저장소 만들기는 $MOCK_DIR/remote.git 에 진짜 git 빈 저장소를 만들어, push 가 실제로 일어나게 한다.
#     맨 윗줄 #!/bin/bash : "쉬뱅(shebang)". 이 파일을 /bin/bash 프로그램으로 실행하라는 표시.
#       #! 는 파일 맨 처음에만 쓰며, 뒤에 적힌 프로그램(위치)으로 이 파일을 실행한다.
#
# [2] 받는 것 → 내보내는 것
#     gh api user → sajang,   gh repo create … → $MOCK_DIR/remote.git,   gh secret set 이름 … → secrets.log 에 이름만,   gh run list → 4242
#
# [3] 앞뒤 파일
#     tepo/mock/run-practice.sh (PATH)  →  github-setup.sh, preflight.sh  →  (이 파일)
#
# [4] 메서드 목록
#     구역       하는 일
#     case       명령 글자에 따라 답하기
#
# [5] 먼저 알 용어
#     case, git init --bare
#
# [6] 읽는 순서
#     case
#
# [7] 다 읽고 확인
#     - secret set 에서 값은 어디에 남는가? (남지 않는다. 이름만 secrets.log 에)
#     - 연습 결과의 "GitHub 에 올라간 파일" 목록은 어디서 읽는가? (remote.git)
#
# [0] 코드만 모아 보기 — 이 파일에서 실제로 실행되는 줄 전체. 아래 본문에서 ▼ 실행 코드 [번호] 를 찾으면 그 줄의 설명이 있다.
#     [1] D="${MOCK_DIR:?}"; echo "gh $*" >> "$D/calls.log"
#     [2] args=" $* "
#     [3] case "$args" in
#     [4]   *" --version "*) echo "gh version (가짜·연습용)" ;;
#     [5]   *" auth status "*|*" auth setup-git "*) : ;;
#     [6]   *" api user "*) echo sajang ;;
#     [7]   *" repo view "*"--json url "*) echo "https://github.com/sajang/ai-publisher" ;;
#     [8]   *" repo view "*"--json nameWithOwner "*) echo "sajang/ai-publisher" ;;
#     [9]   *" repo view "*) [ -f "$D/repo" ] ;;
#     [10]   *" repo create "*) git init -q --bare "$D/remote.git"; git remote add origin "$D/remote.git"; touch "$D/r…
#     [11]   *" secret set "*) [[ "$args" == *" --body "* ]] || cat >/dev/null; echo "secret $3" >> "$D/secrets.log" ;;
#     [12]   *" run list "*) echo 4242 ;;
#     [13]   *" run watch "*) : ;;
#     [14]   *" run view "*) echo "https://github.com/sajang/ai-publisher/actions/runs/4242" ;;
#     [15]   *) echo "가짜 gh: 모르는 명령 $*" >&2; exit 1 ;;
#     [16] esac

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 연습 기록 폴더를 D 에 담고, 불린 gh 명령 전체를 calls.log 에 적는다.
# └── ▼ 실행 코드 [1] ───────────────
D="${MOCK_DIR:?}"; echo "gh $*" >> "$D/calls.log"

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 받은 값 전체를 앞뒤에 띄어쓰기를 붙여 한 글자열로. (" auth status " 처럼 낱말 단위로 찾기 쉽게)
# └── ▼ 실행 코드 [2] ───────────────
args=" $* "

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 명령 글자에 따라 가짜 대답을 고른다.
# └── ▼ 실행 코드 [3] ───────────────
case "$args" in

  # ┌── 설명 ──────────────────────────────────
  # │ ▶ 이 줄이 하는 일: gh --version → 가짜 버전 글.
  # └── ▼ 실행 코드 [4] ───────────────
  *" --version "*) echo "gh version (가짜·연습용)" ;;

  # ┌── 설명 ──────────────────────────────────
  # │ ▶ 이 줄이 하는 일: 로그인 확인·git 설정 → 아무것도 안 하고 성공.
  # │   | : case 에서 "또는".
  # │   : : 아무것도 안 하는 명령(늘 성공).
  # └── ▼ 실행 코드 [5] ───────────────
  *" auth status "*|*" auth setup-git "*) : ;;

  # ┌── 설명 ──────────────────────────────────
  # │ ▶ 이 줄이 하는 일: 내 GitHub 아이디 묻기 → sajang (가짜 아이디).
  # └── ▼ 실행 코드 [6] ───────────────
  *" api user "*) echo sajang ;;

  # ┌── 설명 ──────────────────────────────────
  # │ ▶ 이 줄이 하는 일: 저장소 주소 묻기 → https://github.com/sajang/ai-publisher
  # └── ▼ 실행 코드 [7] ───────────────
  *" repo view "*"--json url "*) echo "https://github.com/sajang/ai-publisher" ;;

  # ┌── 설명 ──────────────────────────────────
  # │ ▶ 이 줄이 하는 일: 저장소 "주인/이름" 묻기 → sajang/ai-publisher
  # └── ▼ 실행 코드 [8] ───────────────
  *" repo view "*"--json nameWithOwner "*) echo "sajang/ai-publisher" ;;

  # ┌── 설명 ──────────────────────────────────
  # │ ▶ 이 줄이 하는 일: 저장소가 있는지 묻기 → repo 표시 파일이 있으면 성공(있음).
  # └── ▼ 실행 코드 [9] ───────────────
  *" repo view "*) [ -f "$D/repo" ] ;;

  # ┌── 설명 ──────────────────────────────────
  # │ ▶ 이 줄이 하는 일: 저장소 만들기 → 진짜 git 빈 저장소(remote.git)를 만들고 origin 으로 연결한다. 그래서 push 가 실제로 일어난다.
  # │   git init -q --bare    : 작업 파일 없이 기록만 담는 저장소(서버 쪽 저장소 모양)를 만든다. -q = 조용히.
  # │   git remote add origin : 올릴 곳 이름 origin 을 그 저장소로 정한다.
  # │   touch                 : 빈 파일 만들기(저장소가 생겼다는 표시).
  # └── ▼ 실행 코드 [10] ──────────────
  *" repo create "*) git init -q --bare "$D/remote.git"; git remote add origin "$D/remote.git"; touch "$D/repo" ;;

  # ┌── 설명 ──────────────────────────────────
  # │ ▶ 이 줄이 하는 일: 비밀값 저장 → 값은 읽어서 버리고, 이름만 secrets.log 에 남긴다.
  # │   [[ … == *" --body "* ]] : --body 로 값을 줬는지 본다. 아니면 값이 입력으로 들어오므로 cat >/dev/null 로 읽어 버린다.
  # │   $3                      : 세 번째 값 = 비밀 이름. (gh secret set 이름 …)
  # └── ▼ 실행 코드 [11] ──────────────
  *" secret set "*) [[ "$args" == *" --body "* ]] || cat >/dev/null; echo "secret $3" >> "$D/secrets.log" ;;

  # ┌── 설명 ──────────────────────────────────
  # │ ▶ 이 줄이 하는 일: 실행 기록 → 가짜 번호 4242.
  # └── ▼ 실행 코드 [12] ──────────────
  *" run list "*) echo 4242 ;;

  # ┌── 설명 ──────────────────────────────────
  # │ ▶ 이 줄이 하는 일: 실행 지켜보기 → 바로 성공.
  # └── ▼ 실행 코드 [13] ──────────────
  *" run watch "*) : ;;

  # ┌── 설명 ──────────────────────────────────
  # │ ▶ 이 줄이 하는 일: 실행 보기 → 가짜 주소.
  # └── ▼ 실행 코드 [14] ──────────────
  *" run view "*) echo "https://github.com/sajang/ai-publisher/actions/runs/4242" ;;

  # ┌── 설명 ──────────────────────────────────
  # │ ▶ 이 줄이 하는 일: 그 밖의 명령 → 모른다고 알리고 실패(1). 연습에 새 gh 명령이 쓰이면 여기서 드러난다.
  # └── ▼ 실행 코드 [15] ──────────────
  *) echo "가짜 gh: 모르는 명령 $*" >&2; exit 1 ;;

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 위 case 블록의 끝 (case 를 거꾸로 쓴 말)
# └── ▼ 실행 코드 [16] ──────────────
esac
PUBLISHER_FILE_19_END

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 파일 ~/my-publisher/tepo/mock/run-practice.sh 를 만든다. (진짜 AWS·GitHub 없이 테포의 배포 순서를 처음부터 끝까지 연습한다. 돈이 들지 않는다.)
# │   아래 275줄이 그 파일 내용 그대로이고, PUBLISHER_FILE_20_END 줄에서 끝난다.
# └── ▼ 실행 코드 [31] (아래 277줄이 한 덩어리) ────
cat > "$P/tepo/mock/run-practice.sh" <<'PUBLISHER_FILE_20_END'
#!/bin/bash
# [1] 역할
#     진짜 AWS·GitHub 없이 테포의 배포 순서를 처음부터 끝까지 연습한다. 돈이 들지 않는다.
#     임시 폴더에 출판사 폴더·소스 복사본을 만들고, PATH 맨 앞에 가짜 aws·gh·ssh·scp·curl 을 두고 preflight → create-infra(승인 없이·있게·한 번 더) → server-setup → github-setup 을 차례로 실행한다.
#     맨 윗줄 #!/bin/bash : "쉬뱅(shebang)". 이 파일을 /bin/bash 프로그램으로 실행하라는 표시.
#       #! 는 파일 맨 처음에만 쓰며, 뒤에 적힌 프로그램(위치)으로 이 파일을 실행한다.
#
# [2] 받는 것 → 내보내는 것
#     실행  bash tepo/mock/run-practice.sh
#     결과 (실제 실행, 줄임)
#       ━━━━━━━━ 2. 승인 없이 서버 만들기 → 멈춰야 정상 ━━━━━━━━   👍 승인 없이는 멈췄어요
#       ━━━━━━━━ 4. 한 번 더 실행 … ━━━━━━━━                       👍 새로 만든 것 없음 (만들기 명령 4번 그대로)
#       불린 명령 (순서대로): 1 aws --version … 53 gh run view 4242 --json url --jq .url
#       등록한 Secrets (이름만): LIGHTSAIL_HOST, LIGHTSAIL_USER, LIGHTSAIL_DOMAIN, LIGHTSAIL_SSH_KEY
#       비밀 파일 권한: -rw------- db-password, -rw------- lightsail_key, -rw------- 관리화면-로그인.txt
#       ✅ 연습 끝 — 진짜 AWS·GitHub 에는 아무것도 만들지 않았어요.
#
# [3] 앞뒤 파일
#     (이 파일)  →  mock/aws, gh, ssh, scp, curl (PATH)  →  tepo/preflight.sh, create-infra.sh, server-setup.sh, github-setup.sh
#
# [4] 메서드 목록
#     단계    하는 일                                         정상이면
#     안전장치  common.sh 를 거친 뒤에도 aws·gh 가 가짜인지          아니면 ❗ 멈춤
#     1       preflight --skip-tests                          ✅ 준비 완료
#     2       승인 없이 create-infra                           ❌ 로 멈춤 → 👍
#     3       승인 기록 쓰고 create-infra                      서버·IP·DB
#     4       한 번 더 create-infra                            만들기 명령 수 그대로
#     5·6     server-setup, github-setup                      ✅ 배포 성공
#     결과     calls.log, secrets.log, 올라간 파일, 비밀 파일 권한
#
# [5] 먼저 알 용어
#     mktemp -d, export, PATH 앞에 넣기, rsync, if 명령; then …; else …; fi, grep -c, nl
#
# [6] 읽는 순서
#     변수 → 안전장치 → step 1~6 → 결과
#
# [7] 다 읽고 확인
#     - 2단계에서 create-infra 가 성공하면 왜 연습 전체를 실패로 끝내는가? (승인 없이 돈 드는 단계가 실행된 것이므로)
#     - 안전장치가 없으면, 진짜 aws 를 이미 설치한 학생의 연습은 어떻게 될 수 있는가? (common.sh 가 ~/.local/bin 을 앞에 두면 진짜 aws 가 불린다)
#
# [0] 코드만 모아 보기 — 이 파일에서 실제로 실행되는 줄 전체. 아래 본문에서 ▼ 실행 코드 [번호] 를 찾으면 그 줄의 설명이 있다.
#     [1] set -euo pipefail
#     [2] M="$(cd "$(dirname "$0")" && pwd)"; TEPO="$(dirname "$M")"
#     [3] SRC="${PUBLISHER_REPO:-$HOME/ai-publisher}"
#     [4] W="$(mktemp -d)"; export MOCK_DIR="$W/mock"; mkdir -p "$MOCK_DIR"
#     [5] export PUBLISHER_HOME="$W/my-publisher" PUBLISHER_REPO="$W/ai-publisher" PATH="$M:$PATH"
#     [6] mkdir -p "$PUBLISHER_HOME"
#     [7] echo "연습 폴더: $W"
#     [8] rsync -a --exclude build --exclude .gradle --exclude .git "$SRC/" "$PUBLISHER_REPO/" 2>/dev/null || cp -r "…
#     [9] cd "$PUBLISHER_HOME"
#     [10] step() { echo; echo "━━━━━━━━ $* ━━━━━━━━"; }
#     [11] for t in aws gh; do
#     [12]   got="$(bash -c 'source "$1/common.sh" >/dev/null; command -v '"$t" _ "$TEPO")"
#     [13]   [ "$got" = "$M/$t" ] || { echo "❗ 연습을 멈춰요: $t 가 가짜가 아니에요 ($got)"; exit 1; }
#     [14] done
#     [15] step "1. 준비 확인 (preflight)"
#     [16] bash "$TEPO/preflight.sh" --skip-tests
#     [17] step "2. 승인 없이 서버 만들기 → 멈춰야 정상"
#     [18] if bash "$TEPO/create-infra.sh"; then echo "❗ 승인 없이 실행됨 (잘못)"; exit 1; else echo "👍 승인 없이는 …
#     [19] step "3. 사장님 승인 기록 → 서버·DB 만들기"
#     [20] sleep 1; printf '%s\n%s\n' "$(date '+%F %T')" "좋아요, 서버에 올려 주세요" > "$PUBLISHER_HOME/ops/approved.…
#     [21] bash "$TEPO/create-infra.sh"
#     [22] step "4. 한 번 더 실행 → 이미 있는 것은 다시 만들지 않아야 정상"
#     [23] before=$(grep -c "create-\|allocate-\|import-key" "$MOCK_DIR/calls.log")
#     [24] bash "$TEPO/create-infra.sh" >/dev/null
#     [25] after=$(grep -c "create-\|allocate-\|import-key" "$MOCK_DIR/calls.log")
#     [26] [ "$before" = "$after" ] && echo "👍 새로 만든 것 없음 (만들기 명령 $before번 그대로)" || { echo "❗ 다시 …
#     [27] step "5. 서버 설치 (server-setup)"
#     [28] bash "$TEPO/server-setup.sh"
#     [29] step "6. GitHub 저장소·Secrets·Actions (github-setup)"
#     [30] bash "$TEPO/github-setup.sh"
#     [31] step "결과"
#     [32] echo "불린 명령 (순서대로):"; nl -ba "$MOCK_DIR/calls.log" | sed 's/^/  /'
#     [33] echo "등록한 Secrets (이름만):"; sed 's/^/  /' "$MOCK_DIR/secrets.log"
#     [34] echo "GitHub 에 올라간 파일:"; git -C "$MOCK_DIR/remote.git" ls-tree -r --name-only main | grep -E "^\.gith…
#     [35] echo "비밀 파일 권한:"; ls -l "$PUBLISHER_HOME/ops/secrets" | sed 's/^/  /'
#     [36] echo; echo "✅ 연습 끝 — 진짜 AWS·GitHub 에는 아무것도 만들지 않았어요."

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 오류가 나면 바로 멈추게 하는 안전 설정.
# │   -e          : 명령 하나라도 실패하면 즉시 멈춘다.
# │   -u          : 정하지 않은 변수를 쓰면 멈춘다.
# │   -o pipefail : a | b 에서 a 가 실패해도 실패로 본다.
# └── ▼ 실행 코드 [1] ───────────────
set -euo pipefail

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 이 파일이 있는 mock 폴더의 전체 경로를 M 에, 그 위 tepo 폴더를 TEPO 에 담는다.
# │   예) M=~/my-publisher/tepo/mock  TEPO=~/my-publisher/tepo
# └── ▼ 실행 코드 [2] ───────────────
M="$(cd "$(dirname "$0")" && pwd)"; TEPO="$(dirname "$M")"

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 진짜 소스 폴더 위치. 예) ~/ai-publisher (여기서 복사만 하고 고치지 않는다)
# └── ▼ 실행 코드 [3] ───────────────
SRC="${PUBLISHER_REPO:-$HOME/ai-publisher}"

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 연습용 임시 폴더 W 를 만들고, 가짜 명령 기록 폴더 MOCK_DIR 을 그 안에 만든다.
# │   MOCK_DIR 이 정해지면 common.sh 가 "연습 중"으로 안다.
# └── ▼ 실행 코드 [4] ───────────────
W="$(mktemp -d)"; export MOCK_DIR="$W/mock"; mkdir -p "$MOCK_DIR"

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 출판사 폴더·소스 폴더를 연습 폴더 안으로 바꾸고, PATH 맨 앞에 mock 폴더를 넣는다.
# │   → 테포 스크립트가 aws·gh·ssh·scp·curl 을 부르면 진짜 대신 mock 폴더의 가짜가 불린다.
# │   PATH="$M:$PATH" : mock 폴더를 맨 앞에.
# └── ▼ 실행 코드 [5] ───────────────
export PUBLISHER_HOME="$W/my-publisher" PUBLISHER_REPO="$W/ai-publisher" PATH="$M:$PATH"

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 연습용 출판사 폴더를 만든다.
# └── ▼ 실행 코드 [6] ───────────────
mkdir -p "$PUBLISHER_HOME"

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 연습 폴더 위치를 찍는다. 예) 연습 폴더: /tmp/tmp.Ab12Cd
# └── ▼ 실행 코드 [7] ───────────────
echo "연습 폴더: $W"

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 진짜 소스를 연습 폴더로 복사한다(build·.gradle·.git 은 뺌). rsync 가 없으면 cp 로.
# │   rsync -a       : 폴더를 권한·시각까지 그대로 복사.
# │   --exclude 이름 : 그 이름은 빼고.
# └── ▼ 실행 코드 [8] ───────────────
rsync -a --exclude build --exclude .gradle --exclude .git "$SRC/" "$PUBLISHER_REPO/" 2>/dev/null || cp -r "$SRC" "$PUBLISHER_REPO"

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 연습용 출판사 폴더로 들어간다.
# └── ▼ 실행 코드 [9] ───────────────
cd "$PUBLISHER_HOME"

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: step 함수: 빈 줄 + ━━ 제목 ━━ 줄을 찍는다(단계 구분).
# └── ▼ 실행 코드 [10] ──────────────
step() { echo; echo "━━━━━━━━ $* ━━━━━━━━"; }

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 안전 확인: aws 와 gh 가 정말 가짜로 불리는지 하나씩 확인한다.
# └── ▼ 실행 코드 [11] ──────────────
for t in aws gh; do

  # ┌── 설명 ──────────────────────────────────
  # │ ▶ 이 줄이 하는 일: common.sh 를 불러온 상태에서 그 명령이 어디서 불리는지 찾아 got 에 담는다.
  # │   bash -c '…' _ "$TEPO" : 새 bash 에서 짧은 명령 실행. _ 는 $0 자리, "$TEPO" 가 $1.
  # │   '…'"$t"               : 작은따옴표 글 뒤에 큰따옴표 글을 바로 붙여 한 덩어리로 만든다.
  # └── ▼ 실행 코드 [12] ──────────────
  got="$(bash -c 'source "$1/common.sh" >/dev/null; command -v '"$t" _ "$TEPO")"

  # ┌── 설명 ──────────────────────────────────
  # │ ▶ 이 줄이 하는 일: 가짜(mock 폴더)가 아니면 진짜 AWS 를 건드릴 수 있으므로 연습을 바로 멈춘다.
  # └── ▼ 실행 코드 [13] ──────────────
  [ "$got" = "$M/$t" ] || { echo "❗ 연습을 멈춰요: $t 가 가짜가 아니에요 ($got)"; exit 1; }

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 위 for / while 반복의 끝
# └── ▼ 실행 코드 [14] ──────────────
done

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 1단계 제목.
# └── ▼ 실행 코드 [15] ──────────────
step "1. 준비 확인 (preflight)"

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 준비 확인을 시험(1~3분) 없이 실행한다. 가짜 aws 가 요금을 대답한다.
# └── ▼ 실행 코드 [16] ──────────────
bash "$TEPO/preflight.sh" --skip-tests

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 2단계 제목.
# └── ▼ 실행 코드 [17] ──────────────
step "2. 승인 없이 서버 만들기 → 멈춰야 정상"

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 승인 기록 없이 서버 만들기를 실행해 본다. 멈춰야 정상(👍), 실행되면 잘못(❗)이라 연습을 멈춘다.
# └── ▼ 실행 코드 [18] ──────────────
if bash "$TEPO/create-infra.sh"; then echo "❗ 승인 없이 실행됨 (잘못)"; exit 1; else echo "👍 승인 없이는 멈췄어요"; fi

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 3단계 제목.
# └── ▼ 실행 코드 [19] ──────────────
step "3. 사장님 승인 기록 → 서버·DB 만들기"

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 1초 기다린 뒤(시각이 plan.env 보다 나중이 되게) 승인 기록 approved.txt 를 쓴다. 1줄 = 지금 시각, 2줄 = 승인 문장.
# │   date '+%F %T' : 예) 2026-11-10 09:15:30
# └── ▼ 실행 코드 [20] ──────────────
sleep 1; printf '%s\n%s\n' "$(date '+%F %T')" "좋아요, 서버에 올려 주세요" > "$PUBLISHER_HOME/ops/approved.txt"

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 이번에는 승인이 있으니 서버·IP·DB 를 (가짜로) 만든다.
# └── ▼ 실행 코드 [21] ──────────────
bash "$TEPO/create-infra.sh"

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 4단계 제목.
# └── ▼ 실행 코드 [22] ──────────────
step "4. 한 번 더 실행 → 이미 있는 것은 다시 만들지 않아야 정상"

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 지금까지 "만들기" 명령이 몇 번 불렸는지 센다.
# │   grep -c                          : 맞는 줄의 개수.
# │   "create-\|allocate-\|import-key" : 셋 중 하나라도 들어 있는 줄.
# └── ▼ 실행 코드 [23] ──────────────
before=$(grep -c "create-\|allocate-\|import-key" "$MOCK_DIR/calls.log")

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 한 번 더 실행한다(결과 글은 숨김).
# └── ▼ 실행 코드 [24] ──────────────
bash "$TEPO/create-infra.sh" >/dev/null

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 다시 센다.
# └── ▼ 실행 코드 [25] ──────────────
after=$(grep -c "create-\|allocate-\|import-key" "$MOCK_DIR/calls.log")

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 횟수가 같으면 👍(이미 있는 것은 다시 안 만듦), 다르면 ❗ 로 멈춘다.
# └── ▼ 실행 코드 [26] ──────────────
[ "$before" = "$after" ] && echo "👍 새로 만든 것 없음 (만들기 명령 $before번 그대로)" || { echo "❗ 다시 만들었음"; exit 1; }

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 5단계 제목.
# └── ▼ 실행 코드 [27] ──────────────
step "5. 서버 설치 (server-setup)"

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 서버 설치를 실행한다(가짜 ssh·scp·curl). 관리 화면 jar 는 진짜로 만들어진다.
# └── ▼ 실행 코드 [28] ──────────────
bash "$TEPO/server-setup.sh"

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 6단계 제목.
# └── ▼ 실행 코드 [29] ──────────────
step "6. GitHub 저장소·Secrets·Actions (github-setup)"

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: GitHub 설정을 실행한다. 가짜 gh 가 만든 진짜 git 저장소(remote.git)로 push 가 실제로 일어난다.
# └── ▼ 실행 코드 [30] ──────────────
bash "$TEPO/github-setup.sh"

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 결과 제목.
# └── ▼ 실행 코드 [31] ──────────────
step "결과"

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 불린 명령 전체를 번호와 함께 보여 준다.
# │   nl -ba        : 모든 줄에 번호를 붙인다.
# │   sed 's/^/  /' : 줄 앞에 띄어쓰기 2칸을 붙인다(들여쓰기).
# └── ▼ 실행 코드 [32] ──────────────
echo "불린 명령 (순서대로):"; nl -ba "$MOCK_DIR/calls.log" | sed 's/^/  /'

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: GitHub Secrets 이름 목록(값은 남기지 않았다).
# └── ▼ 실행 코드 [33] ──────────────
echo "등록한 Secrets (이름만):"; sed 's/^/  /' "$MOCK_DIR/secrets.log"

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 가짜 GitHub 저장소에 올라간 파일 중 .github/…, .gitignore, staff.yml 만 보여 준다.
# │   git -C 폴더                 : 그 폴더에서 git 실행.
# │   ls-tree -r --name-only main : main 가지의 파일 이름 전부.
# └── ▼ 실행 코드 [34] ──────────────
echo "GitHub 에 올라간 파일:"; git -C "$MOCK_DIR/remote.git" ls-tree -r --name-only main | grep -E "^\.github|^\.gitignore|staff.yml" | sed 's/^/  /'

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 비밀 폴더의 파일 권한을 보여 준다. -rw------- (600) 이어야 한다.
# └── ▼ 실행 코드 [35] ──────────────
echo "비밀 파일 권한:"; ls -l "$PUBLISHER_HOME/ops/secrets" | sed 's/^/  /'

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 끝 인사.
# └── ▼ 실행 코드 [36] ──────────────
echo; echo "✅ 연습 끝 — 진짜 AWS·GitHub 에는 아무것도 만들지 않았어요."
PUBLISHER_FILE_20_END

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 파일 ~/my-publisher/tepo/mock/scp 를 만든다. (연습 전용 가짜 명령. tepo/mock/run-practice.sh 가 PATH 맨 앞에 이 폴더를 넣어, 테포 스크립트가 진짜 대신 이 파일을 부르게 한다.)
# │   아래 38줄이 그 파일 내용 그대로이고, PUBLISHER_FILE_21_END 줄에서 끝난다.
# └── ▼ 실행 코드 [32] (아래 40줄이 한 덩어리) ────
cat > "$P/tepo/mock/scp" <<'PUBLISHER_FILE_21_END'
#!/bin/bash
# [1] 역할
#     연습 전용 가짜 명령. tepo/mock/run-practice.sh 가 PATH 맨 앞에 이 폴더를 넣어, 테포 스크립트가 진짜 대신 이 파일을 부르게 한다.
#     부른 명령은 $MOCK_DIR/calls.log 에 한 줄씩 남는다. 진짜 AWS·GitHub·서버에는 아무것도 하지 않는다.
#     가짜 scp: 마지막 인자(보낼 곳)만 기록한다.
#     맨 윗줄 #!/bin/bash : "쉬뱅(shebang)". 이 파일을 /bin/bash 프로그램으로 실행하라는 표시.
#       #! 는 파일 맨 처음에만 쓰며, 뒤에 적힌 프로그램(위치)으로 이 파일을 실행한다.
#
# [2] 받는 것 → 내보내는 것
#     scp … ubuntu@3.35.10.20:/tmp/ → calls.log: scp ubuntu@3.35.10.20:/tmp/
#
# [3] 앞뒤 파일
#     server-setup.sh  →  (이 파일)
#
# [4] 메서드 목록
#     줄     하는 일
#     echo    마지막 인자 기록
#
# [5] 먼저 알 용어
#     ${*: -1}
#
# [6] 읽는 순서
#     한 줄
#
# [7] 다 읽고 확인
#     - 연습에서 jar 는 서버로 올라가는가? (아니다)
#     - 기록에 jar 파일 이름이 없는 이유는? (마지막 인자만 남긴다)
#
# [0] 코드만 모아 보기 — 이 파일에서 실제로 실행되는 줄 전체. 아래 본문에서 ▼ 실행 코드 [번호] 를 찾으면 그 줄의 설명이 있다.
#     [1] echo "scp ${*: -1}" >> "${MOCK_DIR:?}/calls.log"

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 가짜 scp: 받은 값 중 마지막 것(보낼 곳)만 기록한다. 실제로 파일을 보내지 않는다.
# │   예) scp … ubuntu@3.35.10.20:/tmp/ → calls.log: scp ubuntu@3.35.10.20:/tmp/
# │   ${*: -1}                  : 받은 값 전체에서 마지막 하나. (: 와 -1 사이 띄어쓰기가 꼭 필요)
# │   "${MOCK_DIR:?}/calls.log" : 연습 기록 파일. MOCK_DIR 이 없으면 멈춘다.
# └── ▼ 실행 코드 [1] ───────────────
echo "scp ${*: -1}" >> "${MOCK_DIR:?}/calls.log"
PUBLISHER_FILE_21_END

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 파일 ~/my-publisher/tepo/mock/ssh 를 만든다. (연습 전용 가짜 명령. tepo/mock/run-practice.sh 가 PATH 맨 앞에 이 폴더를 넣어, 테포 스크립트가 진짜 대신 이 파일을 부르게 한다.)
# │   아래 37줄이 그 파일 내용 그대로이고, PUBLISHER_FILE_22_END 줄에서 끝난다.
# └── ▼ 실행 코드 [33] (아래 39줄이 한 덩어리) ────
cat > "$P/tepo/mock/ssh" <<'PUBLISHER_FILE_22_END'
#!/bin/bash
# [1] 역할
#     연습 전용 가짜 명령. tepo/mock/run-practice.sh 가 PATH 맨 앞에 이 폴더를 넣어, 테포 스크립트가 진짜 대신 이 파일을 부르게 한다.
#     부른 명령은 $MOCK_DIR/calls.log 에 한 줄씩 남는다. 진짜 AWS·GitHub·서버에는 아무것도 하지 않는다.
#     가짜 ssh: 마지막 인자(서버에서 실행할 명령)만 기록하고 성공으로 끝난다.
#     맨 윗줄 #!/bin/bash : "쉬뱅(shebang)". 이 파일을 /bin/bash 프로그램으로 실행하라는 표시.
#       #! 는 파일 맨 처음에만 쓰며, 뒤에 적힌 프로그램(위치)으로 이 파일을 실행한다.
#
# [2] 받는 것 → 내보내는 것
#     ssh … ubuntu@3.35.10.20 true → calls.log: ssh true
#
# [3] 앞뒤 파일
#     server-setup.sh  →  (이 파일)
#
# [4] 메서드 목록
#     줄     하는 일
#     echo    ${*: -1} = 마지막 인자
#
# [5] 먼저 알 용어
#     ${*: -1}
#
# [6] 읽는 순서
#     한 줄
#
# [7] 다 읽고 확인
#     - 가짜 ssh 가 늘 성공하면 server-setup.sh 의 "접속 기다리기"는 몇 번 만에 끝나는가? (첫 번)
#     - 진짜 서버 설치 스크립트는 연습에서 실행되는가? (아니다)
#
# [0] 코드만 모아 보기 — 이 파일에서 실제로 실행되는 줄 전체. 아래 본문에서 ▼ 실행 코드 [번호] 를 찾으면 그 줄의 설명이 있다.
#     [1] echo "ssh ${*: -1}" >> "${MOCK_DIR:?}/calls.log"

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 가짜 ssh: 마지막 값(서버에서 실행할 명령)만 기록하고 성공으로 끝난다. 실제로 접속하지 않는다.
# │   예) ssh … ubuntu@3.35.10.20 true → calls.log: ssh true
# │   ${*: -1} : 받은 값 전체에서 마지막 하나.
# └── ▼ 실행 코드 [1] ───────────────
echo "ssh ${*: -1}" >> "${MOCK_DIR:?}/calls.log"
PUBLISHER_FILE_22_END

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 파일 ~/my-publisher/tepo/preflight.sh 를 만든다. (배포 준비 확인. 도구·AWS 열쇠·GitHub 로그인·소스 폴더·테스트를 확인하고, 만들 것과 한 달 예상 비용을 계산한다.)
# │   아래 402줄이 그 파일 내용 그대로이고, PUBLISHER_FILE_23_END 줄에서 끝난다.
# └── ▼ 실행 코드 [34] (아래 404줄이 한 덩어리) ────
cat > "$P/tepo/preflight.sh" <<'PUBLISHER_FILE_23_END'
#!/bin/bash
# [1] 역할
#     배포 준비 확인. 도구·AWS 열쇠·GitHub 로그인·소스 폴더·테스트를 확인하고, 만들 것과 한 달 예상 비용을 계산한다.
#     아무것도 만들지 않으므로 돈이 들지 않는다. 결과는 쭌이 사장님께 올릴 [배포 제안]의 재료가 된다.
#     맨 윗줄 #!/bin/bash : "쉬뱅(shebang)". 이 파일을 /bin/bash 프로그램으로 실행하라는 표시.
#       #! 는 파일 맨 처음에만 쓰며, 뒤에 적힌 프로그램(위치)으로 이 파일을 실행한다.
#
# [2] 받는 것 → 내보내는 것
#     실행  bash tepo/preflight.sh [--skip-tests]
#     결과 (실제 값은 연습 bash tepo/mock/run-practice.sh 를 실행해 얻은 것. 가짜 aws 가 돌려준 값이다)
#       ▶ 1/5 도구 확인  ✅ aws aws-cli/2  ✅ gh version …
#       ▶ 2/5 AWS 열쇠 확인  ✅ AWS 계정 ****9012 (지역 ap-northeast-2)
#       ✅ 준비 완료 — 배포 제안 재료:
#         - 만들 것: 라이트세일 서버 1대(small_3_0, 메모리 2.0GB·CPU 2개, Ubuntu 24.04), 고정 IP 1개, MySQL 8 DB 1개(micro_2_0), GitHub 비공개 저장소 1개
#         - 월 예상 비용: 서버 $12.0 + DB $15.0 = 약 $27.0
#       ops/plan.env 파일이 생긴다 (BUNDLE=small_3_0, PRICE=12.0, DB_BUNDLE=micro_2_0 …)
#     부족하면  ❌ 준비 부족 — 사장님이 할 일: … (끝 코드 2)
#
# [3] 앞뒤 파일
#     common.sh, install-tools.sh  →  (이 파일)  →  ops/plan.env  →  create-infra.sh 가 읽는다
#
# [4] 메서드 목록
#     단계    하는 일                                           실패하면
#     1/5     aws·gh 설치, java·ssh 확인                       MISSING 에 할 일 추가
#     2/5     aws sts get-caller-identity (열쇠 확인)          "AWS 열쇠가 없어요 …"
#     3/5     gh auth status (GitHub 로그인)                    "GitHub 로그인이 안 되어 있어요 …"
#     4/5     소스 폴더와 ./gradlew test                        "테스트 실패 …"
#     5/5     요금제 조회 → ops/plan.env                        fail
#
# [5] 먼저 알 용어
#     배열 MISSING=() 와 MISSING+=(…), command -v, $(…) 명령 결과, aws --query(JMESPath), read -r a b <<<"…", heredoc(cat > 파일 <<PLAN)
#
# [6] 읽는 순서
#     1/5 → 5/5 → 마지막 echo 들
#
# [7] 다 읽고 확인
#     - 준비가 부족할 때 exit 2 로 끝내는 이유는? (쭌이 "할 일이 있는 실패"를 다른 실패와 나눠 알 수 있다)
#     - 5/5 의 aws 명령들은 돈이 드는가? (아니다. get-… 조회만 한다)
#
# [0] 코드만 모아 보기 — 이 파일에서 실제로 실행되는 줄 전체. 아래 본문에서 ▼ 실행 코드 [번호] 를 찾으면 그 줄의 설명이 있다.
#     [1] source "$(dirname "$0")/common.sh"
#     [2] SKIP_TESTS="${1:-}"
#     [3] MISSING=()
#     [4] say "1/5 도구 확인"
#     [5] bash "$TEPO/install-tools.sh" || MISSING+=("도구 설치 실패: 인터넷 연결을 확인해 주세요")
#     [6] command -v java >/dev/null || MISSING+=("Java 가 없어요: 우분투 창에서 sudo apt install -y openjdk-21-jdk-h…
#     [7] command -v ssh-keygen >/dev/null && command -v ssh >/dev/null || MISSING+=("ssh 가 없어요: 우분투 창에서 su…
#     [8] say "2/5 AWS 열쇠 확인"
#     [9] if ACCOUNT="$(aws sts get-caller-identity --query Account --output text 2>/dev/null)"; then
#     [10]   ok "AWS 계정 ****${ACCOUNT: -4} (지역 $REGION)"
#     [11] else
#     [12]   MISSING+=("AWS 열쇠가 없어요: 자습서 10-1을 따라 IAM 사용자 열쇠를 만들고, 새 우분투 창에서 aws configure…
#     [13] fi
#     [14] say "3/5 GitHub 로그인 확인"
#     [15] if gh auth status >/dev/null 2>&1; then
#     [16]   ok "GitHub $(gh api user --jq .login 2>/dev/null || echo 로그인됨)"
#     [17] else
#     [18]   MISSING+=("GitHub 로그인이 안 되어 있어요: 우분투 창에서 gh auth login 을 하고 화면 안내대로 브라우저에서…
#     [19] fi
#     [20] say "4/5 소스 폴더 확인 ($REPO)"
#     [21] if [ -x "$REPO/publisher-dashboard/gradlew" ]; then
#     [22]   ok "소스 폴더 있음"
#     [23]   if [ "$SKIP_TESTS" != "--skip-tests" ]; then
#     [24]     say "   테스트 실행 중 (1~3분)"
#     [25]     if (cd "$REPO/publisher-dashboard" && ./gradlew test -q >"$OPS/preflight-test.log" 2>&1); then ok "테스…
#     [26]   fi
#     [27] else
#     [28]   MISSING+=("소스 폴더가 없어요: ai-publisher.zip 을 홈 폴더(~)에 풀어 주세요 ($REPO)")
#     [29] fi
#     [30] if [ ${#MISSING[@]} -gt 0 ]; then
#     [31]   echo
#     [32]   echo "❌ 준비 부족 — 사장님이 할 일:"
#     [33]   for m in "${MISSING[@]}"; do echo "  - $m"; done
#     [34]   exit 2
#     [35] fi
#     [36] say "5/5 만들 것과 요금 확인 (조회만)"
#     [37] read -r BUNDLE PRICE RAM CPU <<<"$(lsail get-bundles --query "sort_by(bundles[?isActive && ramSizeInGb >= \…
#     [38] BLUEPRINT="$(lsail get-blueprints --query "blueprints[?platform=='LINUX_UNIX' && starts_with(blueprintId, '…
#     [39] read -r DB_BUNDLE DB_PRICE DB_RAM <<<"$(lsail get-relational-database-bundles --query "sort_by(bundles[?isA…
#     [40] DB_BLUEPRINT="$(lsail get-relational-database-blueprints --query "blueprints[?engine=='mysql' && starts_wit…
#     [41] [ -n "$BUNDLE" ] && [ "$BUNDLE" != "None" ] || fail "서버 요금제를 찾지 못했어요 (지역 $REGION)"
#     [42] [ -n "$DB_BUNDLE" ] && [ "$DB_BUNDLE" != "None" ] || fail "DB 요금제를 찾지 못했어요 (지역 $REGION)"
#     [43] TOTAL="$(python3 -c "print(round($PRICE + $DB_PRICE, 2))")"
#     [44] cat > "$OPS/plan.env" <<PLAN   (+13줄)
#     [45] echo
#     [46] echo "✅ 준비 완료 — 배포 제안 재료:"
#     [47] echo "  - 만들 것: 라이트세일 서버 1대($BUNDLE, 메모리 ${RAM}GB·CPU ${CPU}개, Ubuntu 24.04), 고정 IP 1개, M…
#     [48] echo "  - 지역: $REGION (서울)"
#     [49] echo "  - 월 예상 비용: 서버 \$$PRICE + DB \$$DB_PRICE = 약 \$$TOTAL (AWS 요금표 기준, 세금 별도. 고정 IP는…
#     [50] echo "  - 완성 후 주소 모양: https://고정IP를-줄표로.sslip.io (예: https://3-35-10-20.sslip.io), 로그인 필요"
#     [51] echo "  - 걸리는 시간: 약 20~30분 (DB 준비가 10~20분)"
#     [52] echo "  - 1단계 범위: 관리 화면 + MySQL 만 서버에 올림. AI 팀(쭌·직원)은 지금처럼 내 PC 에서 일함"

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 공용 설정 파일 common.sh 를 불러와 그 안의 변수(OPS, REPO …)와 함수(ok, fail …)를 이 파일에서 쓴다.
# │   source 파일        : 그 파일의 내용을 지금 이 자리에서 실행한다(새 프로그램을 띄우지 않음). 그래서 변수·함수가 이어진다.
# │   $0                 : 지금 실행 중인 파일 이름. 예) tepo/health.sh
# │   dirname            : 경로에서 폴더 부분만. 예) tepo/health.sh → tepo
# │   "$( … )/common.sh" : 결과 예) tepo/common.sh
# └── ▼ 실행 코드 [1] ───────────────
source "$(dirname "$0")/common.sh"

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 첫 번째 값을 SKIP_TESTS 에 담는다. --skip-tests 를 주면 4단계의 시험(1~3분)을 건너뛴다.
# └── ▼ 실행 코드 [2] ───────────────
SKIP_TESTS="${1:-}"

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 사장님이 해야 할 일을 모으는 빈 배열. 끝에서 한꺼번에 보여 준다.
# │   ( ) : 배열(여러 값을 순서대로 담는 변수). 처음엔 비어 있음.
# └── ▼ 실행 코드 [3] ───────────────
MISSING=()

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 1단계 제목을 찍는다.
# └── ▼ 실행 코드 [4] ───────────────
say "1/5 도구 확인"

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: aws·gh 를 (없으면) 설치한다. 실패하면 할 일 목록에 넣는다.
# │   MISSING+=("…") : 배열 끝에 하나 더한다.
# └── ▼ 실행 코드 [5] ───────────────
bash "$TEPO/install-tools.sh" || MISSING+=("도구 설치 실패: 인터넷 연결을 확인해 주세요")

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: Java 가 없으면 설치 방법을 할 일 목록에 넣는다(관리 화면을 만들 때 필요).
# └── ▼ 실행 코드 [6] ───────────────
command -v java >/dev/null || MISSING+=("Java 가 없어요: 우분투 창에서 sudo apt install -y openjdk-21-jdk-headless")

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: ssh-keygen(열쇠 만들기)과 ssh(서버 접속)가 모두 있어야 한다. 없으면 설치 방법을 할 일에 넣는다.
# │   a && b || c : a 와 b 가 모두 성공하지 못하면 c.
# └── ▼ 실행 코드 [7] ───────────────
command -v ssh-keygen >/dev/null && command -v ssh >/dev/null || MISSING+=("ssh 가 없어요: 우분투 창에서 sudo apt install -y openssh-client")

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 2단계 제목.
# └── ▼ 실행 코드 [8] ───────────────
say "2/5 AWS 열쇠 확인"

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: AWS 에 "이 열쇠가 누구 것인가"를 물어 계정 번호를 ACCOUNT 에 담는다. 열쇠가 없거나 틀리면 실패.
# │   sts get-caller-identity : 지금 열쇠의 주인(계정·사용자)을 묻는 명령. 아무것도 만들지 않는다.
# │   --query Account         : 결과에서 계정 번호만.
# │   --output text           : JSON 대신 글자로. 예) 123456789012
# └── ▼ 실행 코드 [9] ───────────────
if ACCOUNT="$(aws sts get-caller-identity --query Account --output text 2>/dev/null)"; then

  # ┌── 설명 ──────────────────────────────────
  # │ ▶ 이 줄이 하는 일: 계정 번호는 끝 4자리만 보여 준다. 예) ✅ AWS 계정 ****9012 (지역 ap-northeast-2)
  # │   ${ACCOUNT: -4} : 끝에서 4글자.
  # └── ▼ 실행 코드 [10] ──────────────
  ok "AWS 계정 ****${ACCOUNT: -4} (지역 $REGION)"

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 조건이 거짓일 때 실행할 부분의 시작
# └── ▼ 실행 코드 [11] ──────────────
else

  # ┌── 설명 ──────────────────────────────────
  # │ ▶ 이 줄이 하는 일: 열쇠 만들기·aws configure 안내를 할 일에 넣는다.
  # └── ▼ 실행 코드 [12] ──────────────
  MISSING+=("AWS 열쇠가 없어요: 자습서 10-1을 따라 IAM 사용자 열쇠를 만들고, 새 우분투 창에서 aws configure 를 해 주세요 (지역: ap-northeast-2)")

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 위 if 블록의 끝 (if 를 거꾸로 쓴 말)
# └── ▼ 실행 코드 [13] ──────────────
fi

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 3단계 제목.
# └── ▼ 실행 코드 [14] ──────────────
say "3/5 GitHub 로그인 확인"

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: gh 로 GitHub 에 로그인되어 있는지 본다.
# └── ▼ 실행 코드 [15] ──────────────
if gh auth status >/dev/null 2>&1; then

  # ┌── 설명 ──────────────────────────────────
  # │ ▶ 이 줄이 하는 일: 로그인된 아이디를 찍는다. 예) ✅ GitHub sajang
  # │   gh api user --jq .login : 내 정보에서 아이디만.
  # │   || echo 로그인됨        : 아이디를 못 읽으면 "로그인됨".
  # └── ▼ 실행 코드 [16] ──────────────
  ok "GitHub $(gh api user --jq .login 2>/dev/null || echo 로그인됨)"

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 조건이 거짓일 때 실행할 부분의 시작
# └── ▼ 실행 코드 [17] ──────────────
else

  # ┌── 설명 ──────────────────────────────────
  # │ ▶ 이 줄이 하는 일: gh auth login 안내를 할 일에 넣는다.
  # └── ▼ 실행 코드 [18] ──────────────
  MISSING+=("GitHub 로그인이 안 되어 있어요: 우분투 창에서 gh auth login 을 하고 화면 안내대로 브라우저에서 허용해 주세요")

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 위 if 블록의 끝 (if 를 거꾸로 쓴 말)
# └── ▼ 실행 코드 [19] ──────────────
fi

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 4단계 제목. 예) ▶ 4/5 소스 폴더 확인 (/home/khbs_d_0/ai-publisher)
# └── ▼ 실행 코드 [20] ──────────────
say "4/5 소스 폴더 확인 ($REPO)"

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 소스 폴더에 관리 화면 만들기 도구(gradlew)가 실행 가능하게 있는지 본다.
# │   -x      : 실행할 수 있는 파일이면 참.
# │   gradlew : Java 프로그램을 시험하고 묶는 Gradle 도구의 실행 파일.
# └── ▼ 실행 코드 [21] ──────────────
if [ -x "$REPO/publisher-dashboard/gradlew" ]; then

  # ┌── 설명 ──────────────────────────────────
  # │ ▶ 이 줄이 하는 일: 있다고 알린다.
  # └── ▼ 실행 코드 [22] ──────────────
  ok "소스 폴더 있음"

  # ┌── 설명 ──────────────────────────────────
  # │ ▶ 이 줄이 하는 일: --skip-tests 를 주지 않았으면 시험을 돌린다.
  # │   != : 다르면 참.
  # └── ▼ 실행 코드 [23] ──────────────
  if [ "$SKIP_TESTS" != "--skip-tests" ]; then

    # ┌── 설명 ──────────────────────────────────
    # │ ▶ 이 줄이 하는 일: 시험 시작을 알린다.
    # └── ▼ 실행 코드 [24] ──────────────
    say "   테스트 실행 중 (1~3분)"

    # ┌── 설명 ──────────────────────────────────
    # │ ▶ 이 줄이 하는 일: 관리 화면의 자동 시험을 돌린다. 통과하면 ✅, 실패하면 할 일에 넣는다. 자세한 기록은 ops/preflight-test.log.
    # │   ./gradlew test -q               : 모든 시험 실행, -q = 조용히.
    # │   >"$OPS/preflight-test.log" 2>&1 : 출력과 오류를 모두 기록 파일에.
    # └── ▼ 실행 코드 [25] ──────────────
    if (cd "$REPO/publisher-dashboard" && ./gradlew test -q >"$OPS/preflight-test.log" 2>&1); then ok "테스트 통과"; else MISSING+=("테스트 실패: $OPS/preflight-test.log 를 확인해야 해요"); fi

  # ┌── 설명 ──────────────────────────────────
  # │ ▶ 이 줄이 하는 일: 위 if 블록의 끝 (if 를 거꾸로 쓴 말)
  # └── ▼ 실행 코드 [26] ──────────────
  fi

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 조건이 거짓일 때 실행할 부분의 시작
# └── ▼ 실행 코드 [27] ──────────────
else

  # ┌── 설명 ──────────────────────────────────
  # │ ▶ 이 줄이 하는 일: zip 을 홈 폴더에 풀라는 안내를 할 일에 넣는다.
  # └── ▼ 실행 코드 [28] ──────────────
  MISSING+=("소스 폴더가 없어요: ai-publisher.zip 을 홈 폴더(~)에 풀어 주세요 ($REPO)")

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 위 if 블록의 끝 (if 를 거꾸로 쓴 말)
# └── ▼ 실행 코드 [29] ──────────────
fi

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 할 일이 하나라도 있으면 목록을 찍고 끝낸다(5단계로 가지 않음).
# │   ${#MISSING[@]} : 배열의 길이(몇 개인지).
# │   -gt 0          : 0 보다 크면.
# └── ▼ 실행 코드 [30] ──────────────
if [ ${#MISSING[@]} -gt 0 ]; then

  # ┌── 설명 ──────────────────────────────────
  # │ ▶ 이 줄이 하는 일: 빈 줄 하나를 찍는다.
  # └── ▼ 실행 코드 [31] ──────────────
  echo

  # ┌── 설명 ──────────────────────────────────
  # │ ▶ 이 줄이 하는 일: 제목 줄.
  # └── ▼ 실행 코드 [32] ──────────────
  echo "❌ 준비 부족 — 사장님이 할 일:"

  # ┌── 설명 ──────────────────────────────────
  # │ ▶ 이 줄이 하는 일: 할 일을 한 줄씩 "  - …" 로 찍는다.
  # │   "${MISSING[@]}" : 배열의 모든 값(하나하나 따로).
  # └── ▼ 실행 코드 [33] ──────────────
  for m in "${MISSING[@]}"; do echo "  - $m"; done

  # ┌── 설명 ──────────────────────────────────
  # │ ▶ 이 줄이 하는 일: 끝 번호 2 로 끝낸다. 쭌은 2 를 보고 "사장님이 할 일이 있다"고 안다(1 = 오류).
  # └── ▼ 실행 코드 [34] ──────────────
  exit 2

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 위 if 블록의 끝 (if 를 거꾸로 쓴 말)
# └── ▼ 실행 코드 [35] ──────────────
fi

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 5단계 제목. 여기서부터는 AWS 에 묻기만 하고 아무것도 만들지 않는다.
# └── ▼ 실행 코드 [36] ──────────────
say "5/5 만들 것과 요금 확인 (조회만)"

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 서버 요금제 중 메모리 2GB 이상·리눅스·판매 중인 것 가운데 가장 싼 것 하나를 골라 네 변수에 나눠 담는다.
# │   예) "small_3_0  12.0  2.0  2" → BUNDLE=small_3_0 PRICE=12.0 RAM=2.0 CPU=2
# │   lsail get-bundles     : 서버 요금제 목록 묻기.
# │   --query "…"           : JMESPath 라는 규칙으로 결과를 거른다.
# │   bundles[?조건]        : 조건에 맞는 것만. isActive = 판매 중, ramSizeInGb >= `2` = 메모리 2GB 이상.
# │   sort_by(…, &price)[0] : 가격 순으로 정렬해 첫 번째(가장 싼 것).
# │   .[bundleId,price,…]   : 이 네 값만.
# │   \`2\`                 : JMESPath 에서 숫자는 ` 로 감싼다. bash 가 ` 를 명령으로 읽지 않게 \ 를 붙였다.
# └── ▼ 실행 코드 [37] ──────────────
read -r BUNDLE PRICE RAM CPU <<<"$(lsail get-bundles --query "sort_by(bundles[?isActive && ramSizeInGb >= \`2\` && contains(supportedPlatforms, 'LINUX_UNIX')], &price)[0].[bundleId,price,ramSizeInGb,cpuCount]" --output text)"

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 서버 운영체제 중 ubuntu_24 로 시작하는 것 하나. 예) ubuntu_24_04
# │   blueprint : 서버를 만들 때 쓰는 "설치판"(운영체제 종류).
# └── ▼ 실행 코드 [38] ──────────────
BLUEPRINT="$(lsail get-blueprints --query "blueprints[?platform=='LINUX_UNIX' && starts_with(blueprintId, 'ubuntu_24')] | [0].blueprintId" --output text)"

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: DB 요금제 중 가장 싼 것. 예) micro_2_0 15.0 1.0
# └── ▼ 실행 코드 [39] ──────────────
read -r DB_BUNDLE DB_PRICE DB_RAM <<<"$(lsail get-relational-database-bundles --query "sort_by(bundles[?isActive], &price)[0].[bundleId,price,ramSizeInGb]" --output text)"

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: MySQL 8.0 판 중 마지막(가장 새) 것. 예) mysql_8_0
# │   [-1] : 목록의 마지막.
# └── ▼ 실행 코드 [40] ──────────────
DB_BLUEPRINT="$(lsail get-relational-database-blueprints --query "blueprints[?engine=='mysql' && starts_with(engineVersion, '8.0')] | [-1].blueprintId" --output text)"

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 서버 요금제를 못 찾았으면(빈 값이나 None) 오류로 끝낸다.
# └── ▼ 실행 코드 [41] ──────────────
[ -n "$BUNDLE" ] && [ "$BUNDLE" != "None" ] || fail "서버 요금제를 찾지 못했어요 (지역 $REGION)"

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: DB 요금제를 못 찾았으면 오류로 끝낸다.
# └── ▼ 실행 코드 [42] ──────────────
[ -n "$DB_BUNDLE" ] && [ "$DB_BUNDLE" != "None" ] || fail "DB 요금제를 찾지 못했어요 (지역 $REGION)"

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 한 달 합계. bash 는 소수 계산을 못 해서 python3 로 더한다. 예) 12.0 + 15.0 → 27.0
# │   round(…, 2) : 소수 둘째 자리까지.
# └── ▼ 실행 코드 [43] ──────────────
TOTAL="$(python3 -c "print(round($PRICE + $DB_PRICE, 2))")"

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 계산한 값을 ops/plan.env 파일에 "키=값" 줄로 저장한다(아래 12줄이 파일 내용, PLAN 줄에서 끝).
# │   create-infra.sh 가 이 파일을 읽어 그대로 만든다.
# │   이 파일의 시각이 사장님 승인 기록(approved.txt)보다 옛것이어야 create-infra.sh 가 실행된다.
# │   cat > 파일 : 입력을 파일에 쓴다(있던 내용은 지움).
# │   <<PLAN     : heredoc. 따옴표가 없어서 $REGION 같은 변수는 값으로 바뀌어 저장된다. 예) REGION=ap-northeast-2
# └── ▼ 실행 코드 [44] (아래 14줄이 한 덩어리) ────
cat > "$OPS/plan.env" <<PLAN
REGION=$REGION
AZ=$AZ
INSTANCE=$INSTANCE
STATIC_IP=$STATIC_IP
DB=$DB
BUNDLE=$BUNDLE
PRICE=$PRICE
BLUEPRINT=$BLUEPRINT
DB_BUNDLE=$DB_BUNDLE
DB_PRICE=$DB_PRICE
DB_BLUEPRINT=$DB_BLUEPRINT
GH_REPO=$GH_REPO
PLAN

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 빈 줄 하나를 찍는다.
# └── ▼ 실행 코드 [45] ──────────────
echo

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 여기부터 6줄은 쭌이 사장님께 보낼 "배포 제안" 재료다. 쭌은 이 내용을 그대로 사장님께 보여 주고 승인을 받는다.
# └── ▼ 실행 코드 [46] ──────────────
echo "✅ 준비 완료 — 배포 제안 재료:"

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 만들 것 목록. 예) 라이트세일 서버 1대(small_3_0, 메모리 2.0GB·CPU 2개, Ubuntu 24.04) …
# └── ▼ 실행 코드 [47] ──────────────
echo "  - 만들 것: 라이트세일 서버 1대($BUNDLE, 메모리 ${RAM}GB·CPU ${CPU}개, Ubuntu 24.04), 고정 IP 1개, MySQL 8 DB 1개($DB_BUNDLE), GitHub 비공개 저장소 1개"

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 지역.
# └── ▼ 실행 코드 [48] ──────────────
echo "  - 지역: $REGION (서울)"

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 한 달 예상 비용. 예) 서버 $12.0 + DB $15.0 = 약 $27.0
# │   \$ : $ 글자 그대로(변수가 아님).
# └── ▼ 실행 코드 [49] ──────────────
echo "  - 월 예상 비용: 서버 \$$PRICE + DB \$$DB_PRICE = 약 \$$TOTAL (AWS 요금표 기준, 세금 별도. 고정 IP는 서버에 붙어 있으면 무료)"

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 완성 후 주소 모양.
# │   sslip.io : IP 를 주소 이름에 넣으면 그 IP 로 이어 주는 무료 이름 서비스. 3-35-10-20.sslip.io → 3.35.10.20
# └── ▼ 실행 코드 [50] ──────────────
echo "  - 완성 후 주소 모양: https://고정IP를-줄표로.sslip.io (예: https://3-35-10-20.sslip.io), 로그인 필요"

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 걸리는 시간.
# └── ▼ 실행 코드 [51] ──────────────
echo "  - 걸리는 시간: 약 20~30분 (DB 준비가 10~20분)"

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 이번에 서버에 올리는 범위.
# └── ▼ 실행 코드 [52] ──────────────
echo "  - 1단계 범위: 관리 화면 + MySQL 만 서버에 올림. AI 팀(쭌·직원)은 지금처럼 내 PC 에서 일함"
PUBLISHER_FILE_23_END

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 파일 ~/my-publisher/tepo/server-setup.sh 를 만든다. (서버에 Java·Caddy(HTTPS)·관리 화면을 설치하고 처음 실행한다.)
# │   아래 276줄이 그 파일 내용 그대로이고, PUBLISHER_FILE_24_END 줄에서 끝난다.
# └── ▼ 실행 코드 [35] (아래 278줄이 한 덩어리) ────
cat > "$P/tepo/server-setup.sh" <<'PUBLISHER_FILE_24_END'
#!/bin/bash
# [1] 역할
#     서버에 Java·Caddy(HTTPS)·관리 화면을 설치하고 처음 실행한다.
#     비밀번호는 서버의 /etc/publisher/dashboard.env (권한 600) 에만 넣고, 내 PC 의 임시 파일은 끝나면 지운다.
#     맨 윗줄 #!/bin/bash : "쉬뱅(shebang)". 이 파일을 /bin/bash 프로그램으로 실행하라는 표시.
#       #! 는 파일 맨 처음에만 쓰며, 뒤에 적힌 프로그램(위치)으로 이 파일을 실행한다.
#
# [2] 받는 것 → 내보내는 것
#     받는 것  : ops/infra.env, ops/secrets/lightsail_key, ops/secrets/db-password
#     내보내는 것 (실제 값은 연습 bash tepo/mock/run-practice.sh 를 실행해 얻은 것. 가짜 aws 가 돌려준 값이다)
#       ✅ 접속됨
#       ✅ 로그인 정보: ops/secrets/관리화면-로그인.txt   (주소·아이디·비밀번호 16자, 권한 600)
#       ✅ 63M …/publisher-dashboard/build/libs/publisher-dashboard.jar
#       ✅ https://3-35-10-20.sslip.io 살아 있음
#       실제로 불린 명령) ssh true / scp ubuntu@3.35.10.20:/tmp/ / ssh sudo bash /tmp/remote-setup.sh '3-35-10-20.sslip.io' '/tmp/tmp.…' / curl https://3-35-10-20.sslip.io/actuator/health
#
# [3] 앞뒤 파일
#     create-infra.sh → ops/infra.env  →  (이 파일)  →  서버에서 templates/remote-setup.sh 실행  →  https://주소/actuator/health
#
# [4] 메서드 목록
#     단계    하는 일
#     1/5     SSH 로 들어갈 수 있을 때까지 기다리기 (최대 3분)
#     2/5     관리 화면 로그인 비밀번호 만들기, 서버용 환경 파일(임시) 만들기
#     3/5     ./gradlew bootJar
#     4/5     jar·환경 파일·스크립트 두 개를 scp 로 올리고 remote-setup.sh 실행
#     5/5     HTTPS 로 /actuator/health 가 UP 인지 (인증서 발급 1~2분)
#
# [5] 먼저 알 용어
#     배열 SSHO=(…) 와 "${SSHO[@]}", ssh·scp, mktemp, chmod 600, trap, heredoc, sed -n 's/…//p'
#
# [6] 읽는 순서
#     1/5 → 2/5 → 4/5 → 5/5
#
# [7] 다 읽고 확인
#     - 환경 파일을 만들 때 chmod 600 을 cat 보다 먼저 하는 이유는? (비밀번호를 쓰는 순간에도 다른 사용자가 읽지 못하게)
#     - 5/5 에서 3분 안에 응답이 없으면 어디를 보라고 하는가? (서버의 journalctl -u publisher-dashboard)
#
# [0] 코드만 모아 보기 — 이 파일에서 실제로 실행되는 줄 전체. 아래 본문에서 ▼ 실행 코드 [번호] 를 찾으면 그 줄의 설명이 있다.
#     [1] source "$(dirname "$0")/common.sh"
#     [2] INFRA="$OPS/infra.env"
#     [3] [ -s "$INFRA" ] || fail "서버 정보(ops/infra.env)가 없어요. 먼저 bash tepo/create-infra.sh"
#     [4] IP="$(getv "$INFRA" IP)"; HOST="$(getv "$INFRA" HOST)"; U="$(getv "$INFRA" SSH_USER)"
#     [5] DB_HOST="$(getv "$INFRA" DB_HOST)"; DB_PORT="$(getv "$INFRA" DB_PORT)"
#     [6] SSHO=(-i "$SECRETS/lightsail_key" -o StrictHostKeyChecking=accept-new -o UserKnownHostsFile="$OPS/known_hos…
#     [7] say "1/5 서버 접속 기다리기 ($IP)"
#     [8] for i in $(seq 1 36); do ssh "${SSHO[@]}" "$U@$IP" true 2>/dev/null && break; sleep 5; done
#     [9] ssh "${SSHO[@]}" "$U@$IP" true || fail "서버에 SSH 로 들어가지 못했어요"
#     [10] ok "접속됨"
#     [11] say "2/5 관리 화면 로그인 계정 만들기"
#     [12] LOGIN="$SECRETS/관리화면-로그인.txt"
#     [13] if [ ! -s "$LOGIN" ]; then
#     [14]   printf '주소: https://%s\n아이디: %s\n비밀번호: %s\n' "$HOST" "$BOSS_USER" "$(newpass 16)" > "$LOGIN"
#     [15] fi
#     [16] chmod 600 "$LOGIN"
#     [17] BOSS_PW="$(sed -n 's/^비밀번호: //p' "$LOGIN")"
#     [18] ENVF="$(mktemp)"; chmod 600 "$ENVF"; trap 'rm -f "$ENVF"' EXIT
#     [19] cat > "$ENVF" <<ENV   (+7줄)
#     [20] ok "로그인 정보: ops/secrets/관리화면-로그인.txt"
#     [21] say "3/5 관리 화면 실행 파일 만들기"
#     [22] (cd "$REPO/publisher-dashboard" && ./gradlew bootJar -q) || fail "bootJar 빌드 실패"
#     [23] JAR="$REPO/publisher-dashboard/build/libs/publisher-dashboard.jar"
#     [24] ok "$(du -h "$JAR" | cut -f1) $JAR"
#     [25] say "4/5 서버에 올리고 설치 (Java·Caddy·systemd)"
#     [26] scp -q "${SSHO[@]}" "$JAR" "$ENVF" "$TEPO/templates/remote-setup.sh" "$TEPO/templates/deploy-on-server.sh" …
#     [27] ssh "${SSHO[@]}" "$U@$IP" "sudo bash /tmp/remote-setup.sh '$HOST' '/tmp/$(basename "$ENVF")'" || fail "서버…
#     [28] say "5/5 HTTPS 주소 확인 (인증서 발급에 1~2분)"
#     [29] for i in $(seq 1 30); do
#     [30]   curl -fsS --max-time 5 "https://$HOST/actuator/health" 2>/dev/null | grep -q UP && { ok "https://$HOST 살…
#     [31]   sleep 6
#     [32] done
#     [33] fail "https://$HOST 이 3분 안에 응답하지 않았어요 (서버 로그: ssh 후 sudo journalctl -u publisher-dashboard…

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 공용 설정 파일 common.sh 를 불러와 그 안의 변수(OPS, REPO …)와 함수(ok, fail …)를 이 파일에서 쓴다.
# │   source 파일        : 그 파일의 내용을 지금 이 자리에서 실행한다(새 프로그램을 띄우지 않음). 그래서 변수·함수가 이어진다.
# │   $0                 : 지금 실행 중인 파일 이름. 예) tepo/health.sh
# │   dirname            : 경로에서 폴더 부분만. 예) tepo/health.sh → tepo
# │   "$( … )/common.sh" : 결과 예) tepo/common.sh
# └── ▼ 실행 코드 [1] ───────────────
source "$(dirname "$0")/common.sh"

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: create-infra.sh 가 만든 서버 정보 파일 위치. 예) ~/my-publisher/ops/infra.env
# └── ▼ 실행 코드 [2] ───────────────
INFRA="$OPS/infra.env"

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 그 파일이 없거나 비어 있으면(서버를 아직 안 만들었으면) 오류로 끝낸다.
# │   -s : 파일이 있고 크기가 0 보다 크면 참.
# └── ▼ 실행 코드 [3] ───────────────
[ -s "$INFRA" ] || fail "서버 정보(ops/infra.env)가 없어요. 먼저 bash tepo/create-infra.sh"

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 서버 정보에서 IP, 주소(HOST), 접속 아이디(U)를 읽는다.
# │   예) IP=3.35.10.20  HOST=3-35-10-20.sslip.io  U=ubuntu
# └── ▼ 실행 코드 [4] ───────────────
IP="$(getv "$INFRA" IP)"; HOST="$(getv "$INFRA" HOST)"; U="$(getv "$INFRA" SSH_USER)"

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: DB 주소와 포트를 읽는다. 예) DB_HOST=ls-abc….ap-northeast-2.rds.amazonaws.com  DB_PORT=3306
# └── ▼ 실행 코드 [5] ───────────────
DB_HOST="$(getv "$INFRA" DB_HOST)"; DB_PORT="$(getv "$INFRA" DB_PORT)"

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: ssh·scp 에 매번 붙일 선택지들을 배열 SSHO 에 담는다. "${SSHO[@]}" 로 쓰면 하나하나 따로 넘어간다.
# │   -i 열쇠파일                      : 이 열쇠(ops/secrets/lightsail_key)로 접속한다.
# │   StrictHostKeyChecking=accept-new : 처음 보는 서버는 기억하고, 나중에 서버가 바뀌면(가짜 서버 의심) 거부.
# │   UserKnownHostsFile=…             : 기억할 서버 목록 파일을 ops/known_hosts 로 따로 둔다.
# │   ConnectTimeout=10                : 10초 안에 연결이 안 되면 실패.
# └── ▼ 실행 코드 [6] ───────────────
SSHO=(-i "$SECRETS/lightsail_key" -o StrictHostKeyChecking=accept-new -o UserKnownHostsFile="$OPS/known_hosts" -o ConnectTimeout=10)

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 1단계 제목.
# └── ▼ 실행 코드 [7] ───────────────
say "1/5 서버 접속 기다리기 ($IP)"

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 서버가 막 켜졌을 때는 SSH 가 아직 안 된다. 5초마다 최대 36번(3분) 아무 일도 안 하는 "true" 명령을 보내 본다. 되면 멈춘다.
# │   ssh 선택지 아이디@IP 명령 : 서버에 들어가 명령을 실행하고 나온다.
# │   true                      : 늘 성공하는 명령(접속만 시험).
# └── ▼ 실행 코드 [8] ───────────────
for i in $(seq 1 36); do ssh "${SSHO[@]}" "$U@$IP" true 2>/dev/null && break; sleep 5; done

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 마지막으로 한 번 더 시험해서 그래도 안 되면 오류로 끝낸다.
# └── ▼ 실행 코드 [9] ───────────────
ssh "${SSHO[@]}" "$U@$IP" true || fail "서버에 SSH 로 들어가지 못했어요"

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 접속 성공을 알린다.
# └── ▼ 실행 코드 [10] ──────────────
ok "접속됨"

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 2단계 제목.
# └── ▼ 실행 코드 [11] ──────────────
say "2/5 관리 화면 로그인 계정 만들기"

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 사장님 로그인 정보 파일 위치. 사장님이 이 파일을 열어 아이디·비밀번호를 본다.
# └── ▼ 실행 코드 [12] ──────────────
LOGIN="$SECRETS/관리화면-로그인.txt"

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 그 파일이 아직 없을 때만 새로 만든다(다시 실행해도 비밀번호가 바뀌지 않게).
# └── ▼ 실행 코드 [13] ──────────────
if [ ! -s "$LOGIN" ]; then

  # ┌── 설명 ──────────────────────────────────
  # │ ▶ 이 줄이 하는 일: 주소·아이디·16자리 새 비밀번호 세 줄을 파일에 쓴다.
  # │   printf '형식' 값… : 형식의 %s 자리에 값을 차례로 넣어 찍는다. \n = 줄바꿈.
  # │   $(newpass 16)     : common.sh 의 함수. 무작위 16자.
  # └── ▼ 실행 코드 [14] ──────────────
  printf '주소: https://%s\n아이디: %s\n비밀번호: %s\n' "$HOST" "$BOSS_USER" "$(newpass 16)" > "$LOGIN"

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 위 if 블록의 끝 (if 를 거꾸로 쓴 말)
# └── ▼ 실행 코드 [15] ──────────────
fi

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 나만 읽고 쓸 수 있게 한다(600 = 주인 읽기4+쓰기2).
# └── ▼ 실행 코드 [16] ──────────────
chmod 600 "$LOGIN"

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 파일에서 "비밀번호: " 줄의 값만 꺼내 BOSS_PW 에 담는다(화면에는 찍지 않음).
# │   sed -n 's/^비밀번호: //p' : "비밀번호: " 로 시작하는 줄에서 그 앞부분을 지우고 그 줄만 찍는다. -n = 기본으로 찍지 않음, p = 찍기.
# └── ▼ 실행 코드 [17] ──────────────
BOSS_PW="$(sed -n 's/^비밀번호: //p' "$LOGIN")"

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 서버로 보낼 환경 파일(임시)을 먼저 권한 600 으로 만들고, 스크립트가 끝나면 지우게 예약한다.
# │   mktemp              : 이름이 겹치지 않는 빈 임시 파일.
# │   trap 'rm -f …' EXIT : 끝날 때 지운다.
# └── ▼ 실행 코드 [18] ──────────────
ENVF="$(mktemp)"; chmod 600 "$ENVF"; trap 'rm -f "$ENVF"' EXIT

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 관리 화면이 서버에서 읽을 설정 6줄을 임시 파일에 쓴다(아래 6줄이 파일 내용, ENV 줄에서 끝).
# │   application-prod.yml 이 ${PUBLISHER_DB_URL} 같은 이름으로 이 값들을 읽는다.
# │   비밀번호는 서버의 /etc/publisher/dashboard.env (권한 600) 에만 들어간다.
# │   PUBLISHER_DB_URL              : DB 주소. sslMode=REQUIRED = DB 와 암호화해서 통신, characterEncoding=UTF-8 = 한글.
# │   $(cat "$SECRETS/db-password") : create-infra.sh 가 만든 DB 비밀번호 파일 내용.
# │   BOSS_USERNAME / BOSS_PASSWORD : 관리 화면 로그인 아이디·비밀번호.
# │   PUBLISHER_ROOT=/opt/publisher : 서버에서 관리 화면이 쓰는 폴더.
# └── ▼ 실행 코드 [19] (아래 8줄이 한 덩어리) ────
cat > "$ENVF" <<ENV
PUBLISHER_DB_URL=jdbc:mysql://$DB_HOST:$DB_PORT/publisher?sslMode=REQUIRED&characterEncoding=UTF-8
PUBLISHER_DB_USER=publisher
PUBLISHER_DB_PASSWORD=$(cat "$SECRETS/db-password")
BOSS_USERNAME=$BOSS_USER
BOSS_PASSWORD=$BOSS_PW
PUBLISHER_ROOT=/opt/publisher/data
ENV

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 로그인 정보가 있는 곳을 알린다(비밀번호 자체는 찍지 않는다).
# └── ▼ 실행 코드 [20] ──────────────
ok "로그인 정보: ops/secrets/관리화면-로그인.txt"

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 3단계 제목.
# └── ▼ 실행 코드 [21] ──────────────
say "3/5 관리 화면 실행 파일 만들기"

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 관리 화면 소스로 실행 파일(jar) 하나를 만든다. 실패하면 오류로 끝낸다.
# │   bootJar : Spring Boot 프로그램을 java -jar 로 바로 실행할 수 있는 jar 하나로 묶는 Gradle 작업.
# └── ▼ 실행 코드 [22] ──────────────
(cd "$REPO/publisher-dashboard" && ./gradlew bootJar -q) || fail "bootJar 빌드 실패"

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 만들어진 jar 위치.
# └── ▼ 실행 코드 [23] ──────────────
JAR="$REPO/publisher-dashboard/build/libs/publisher-dashboard.jar"

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: jar 크기와 위치를 알린다. 예) ✅ 63M …/build/libs/publisher-dashboard.jar
# │   du -h   : 파일 크기를 사람이 읽기 쉽게(M, G).
# │   cut -f1 : 탭으로 나눈 첫 칸(크기)만.
# └── ▼ 실행 코드 [24] ──────────────
ok "$(du -h "$JAR" | cut -f1) $JAR"

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 4단계 제목.
# └── ▼ 실행 코드 [25] ──────────────
say "4/5 서버에 올리고 설치 (Java·Caddy·systemd)"

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 네 파일(jar, 환경 파일, 설치 스크립트 2개)을 SSH 로 서버의 /tmp/ 에 복사한다.
# │   scp : SSH 로 파일을 복사하는 명령. 마지막 값 = 보낼 곳(아이디@IP:폴더).
# │   -q  : 진행 막대를 찍지 않는다.
# └── ▼ 실행 코드 [26] ──────────────
scp -q "${SSHO[@]}" "$JAR" "$ENVF" "$TEPO/templates/remote-setup.sh" "$TEPO/templates/deploy-on-server.sh" "$U@$IP:/tmp/" || fail "파일 올리기 실패"

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 서버에서 관리자 권한(sudo)으로 remote-setup.sh 를 실행한다(Java·Caddy·systemd 설치).
# │   넘기는 값: 주소, 환경 파일 경로.
# │   '$HOST'  : 작은따옴표 = 서버 쪽에서 한 덩어리 값으로 받게.
# │   basename : 경로에서 파일 이름만. 예) /tmp/tmp.X1y2 → tmp.X1y2
# └── ▼ 실행 코드 [27] ──────────────
ssh "${SSHO[@]}" "$U@$IP" "sudo bash /tmp/remote-setup.sh '$HOST' '/tmp/$(basename "$ENVF")'" || fail "서버 설치 실패"

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 5단계 제목. Caddy 가 HTTPS 인증서를 받는 데 1~2분 걸린다.
# └── ▼ 실행 코드 [28] ──────────────
say "5/5 HTTPS 주소 확인 (인증서 발급에 1~2분)"

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 6초마다 최대 30번(3분) 확인한다.
# └── ▼ 실행 코드 [29] ──────────────
for i in $(seq 1 30); do

  # ┌── 설명 ──────────────────────────────────
  # │ ▶ 이 줄이 하는 일: 대답에 UP 이 있으면 ✅ 를 찍고 성공으로 끝낸다.
  # │   grep -q UP : 대답 {"status":"UP"} 에 UP 이 있는지.
  # └── ▼ 실행 코드 [30] ──────────────
  curl -fsS --max-time 5 "https://$HOST/actuator/health" 2>/dev/null | grep -q UP && { ok "https://$HOST 살아 있음"; exit 0; }

  # ┌── 설명 ──────────────────────────────────
  # │ ▶ 이 줄이 하는 일: 6초 쉰다.
  # └── ▼ 실행 코드 [31] ──────────────
  sleep 6

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 위 for / while 반복의 끝
# └── ▼ 실행 코드 [32] ──────────────
done

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 3분 안에 대답이 없으면 서버 기록을 보는 방법과 함께 오류로 끝낸다.
# │   journalctl -u 서비스 -n 50 : 서버에서 그 서비스의 기록 마지막 50줄을 보는 명령.
# └── ▼ 실행 코드 [33] ──────────────
fail "https://$HOST 이 3분 안에 응답하지 않았어요 (서버 로그: ssh 후 sudo journalctl -u publisher-dashboard -n 50)"
PUBLISHER_FILE_24_END

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 파일 ~/my-publisher/tepo/templates/ci.yml 를 만든다. (CI(지속적 통합): 코드를 올릴 때마다 GitHub 서버가 자동으로 검사한다. Pull Request, main 이 아닌 가지에 push, 그리고 deploy.yml 의 첫 단계로 쓰인다.)
# │   아래 288줄이 그 파일 내용 그대로이고, PUBLISHER_FILE_25_END 줄에서 끝난다.
# └── ▼ 실행 코드 [36] (아래 290줄이 한 덩어리) ────
cat > "$P/tepo/templates/ci.yml" <<'PUBLISHER_FILE_25_END'
# [1] 역할
#     CI(지속적 통합): 코드를 올릴 때마다 GitHub 서버가 자동으로 검사한다. Pull Request, main 이 아닌 가지에 push, 그리고 deploy.yml 의 첫 단계로 쓰인다.
#     진짜 MySQL 8 을 함께 띄워 MySqlMigrationTest 까지 실행하므로 테스트 27개가 모두 돈다.
#     YAML 읽는 법: "이름: 값". 들여쓰기(띄어쓰기 2칸)로 무엇이 무엇 안에 들어가는지 나타낸다. "- " 는 목록의 한 칸.
#       # 뒤는 설명(주석)이라 GitHub 가 읽지 않는다. run: | 아래 줄들은 셸 명령이고, 그 안의 # 줄은 셸 주석이다.
#
# [2] 받는 것 → 내보내는 것
#     받는 것  : push 또는 Pull Request
#     내보내는 것: GitHub 의 Actions 탭에 초록불(성공)/빨간불(실패). 실패하면 test-report(테스트 보고서 HTML)를 내려받을 수 있다.
#       실행되는 명령) cd publisher-dashboard && chmod +x gradlew && ./gradlew test bootJar --no-daemon
#
# [3] 앞뒤 파일
#     git push / Pull Request  →  (이 파일)  →  publisher-dashboard/src/test/java/** (27개)
#     .github/workflows/deploy.yml 의 jobs.test 가 (이 파일)을 부른다 (workflow_call)
#
# [4] 메서드 목록
#     구역              하는 일
#     on                언제 실행하나: pull_request, main 이 아닌 가지 push, 다른 workflow 가 부를 때
#     services.mysql    시험용 MySQL 8 (사용자 publisher)
#     steps             코드 받기 → Java 21 → 테스트 + bootJar → 실패하면 보고서 보관
#
# [5] 먼저 알 용어
#     workflow, on(이벤트), jobs, runs-on, services, steps, uses(남이 만든 action), run, env, if: failure()
#
# [6] 읽는 순서
#     on → services → steps
#
# [7] 다 읽고 확인
#     - 새 직원 채용 PR(staff.yml 수정)은 어느 시험에서 검사되는가? (StaffRegistryTest)
#     - TEST_MYSQL_URL 을 지우면 MySqlMigrationTest 는 어떻게 되는가? (건너뛴다)
#
# [0] 코드만 모아 보기 — 이 파일에서 실제로 읽히는 설정 줄 전체(# 설명 줄 제외). 아래 본문에서 ▼ 실행 코드 [번호] 를 찾으면 그 줄의 설명이 있다.
#     [1] name: CI
#     [2] on:
#     [3]   pull_request:
#     [4]   push:
#     [5]     branches-ignore: [main]
#     [6]   workflow_call:
#     [7] jobs:
#     [8]   test:
#     [9]     runs-on: ubuntu-latest
#     [10]     services:
#     [11]       mysql:
#     [12]         image: mysql:8.0
#     [13]         env:
#     [14]           MYSQL_ROOT_PASSWORD: root
#     [15]           MYSQL_DATABASE: publisher
#     [16]           MYSQL_USER: publisher
#     [17]           MYSQL_PASSWORD: publisher
#     [18]         ports: ["3306:3306"]
#     [19]         options: >-   (+2줄)
#     [20]     defaults:
#     [21]       run:
#     [22]         working-directory: publisher-dashboard
#     [23]     steps:
#     [24]       - uses: actions/checkout@v4
#     [25]       - uses: actions/setup-java@v4
#     [26]         with:
#     [27]           distribution: temurin
#     [28]           java-version: "21"
#     [29]           cache: gradle
#     [30]       - name: 테스트 (H2 + 진짜 MySQL)
#     [31]         run: chmod +x gradlew && ./gradlew test bootJar --no-daemon
#     [32]         env:
#     [33]           TEST_MYSQL_URL: jdbc:mysql://127.0.0.1:3306/publisher
#     [34]           TEST_MYSQL_USER: publisher
#     [35]           TEST_MYSQL_PASSWORD: publisher
#     [36]       - name: 테스트 결과 보관 (실패했을 때)
#     [37]         if: failure()
#     [38]         uses: actions/upload-artifact@v4
#     [39]         with:
#     [40]           name: test-report
#     [41]           path: publisher-dashboard/build/reports/tests/test

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 이 작업 흐름(workflow)의 이름. GitHub 의 Actions 탭에 이 이름으로 보인다.
# │   CI : Continuous Integration. 코드를 올릴 때마다 자동으로 시험하는 것.
# └── ▼ 실행 코드 [1] ───────────────
name: CI

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 언제 실행할지(아래 세 가지).
# └── ▼ 실행 코드 [2] ───────────────
on:

  # ┌── 설명 ──────────────────────────────────
  # │ ▶ 이 줄이 하는 일: PR(고친 내용을 합쳐 달라는 요청)을 열거나 고칠 때.
  # └── ▼ 실행 코드 [3] ───────────────
  pull_request:

  # ┌── 설명 ──────────────────────────────────
  # │ ▶ 이 줄이 하는 일: 가지에 push 할 때(아래 조건).
  # └── ▼ 실행 코드 [4] ───────────────
  push:

    # ┌── 설명 ──────────────────────────────────
    # │ ▶ 이 줄이 하는 일: main 이 아닌 가지에서만. main 은 deploy.yml 이 이 파일을 불러 검사한다(두 번 돌지 않게).
    # └── ▼ 실행 코드 [5] ───────────────
    branches-ignore: [main]

  # ┌── 설명 ──────────────────────────────────
  # │ ▶ 이 줄이 하는 일: 다른 workflow(deploy.yml)가 이 파일을 부를 수 있게 한다.
  # └── ▼ 실행 코드 [6] ───────────────
  workflow_call:

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 할 일(job) 목록.
# └── ▼ 실행 코드 [7] ───────────────
jobs:

  # ┌── 설명 ──────────────────────────────────
  # │ ▶ 이 줄이 하는 일: job 이름 test.
  # └── ▼ 실행 코드 [8] ───────────────
  test:

    # ┌── 설명 ──────────────────────────────────
    # │ ▶ 이 줄이 하는 일: GitHub 가 빌려주는 Ubuntu 컴퓨터에서 실행한다. 끝나면 지워진다.
    # └── ▼ 실행 코드 [9] ───────────────
    runs-on: ubuntu-latest

    # ┌── 설명 ──────────────────────────────────
    # │ ▶ 이 줄이 하는 일: 시험하는 동안 옆에 띄울 프로그램.
    # └── ▼ 실행 코드 [10] ──────────────
    services:

      # ┌── 설명 ──────────────────────────────────
      # │ ▶ 이 줄이 하는 일: 서비스 이름 mysql.
      # └── ▼ 실행 코드 [11] ──────────────
      mysql:

        # ┌── 설명 ──────────────────────────────────
        # │ ▶ 이 줄이 하는 일: mysql 8.0 도커 이미지(설치된 상태의 프로그램 묶음)를 띄운다.
        # └── ▼ 실행 코드 [12] ──────────────
        image: mysql:8.0

        # ┌── 설명 ──────────────────────────────────
        # │ ▶ 이 줄이 하는 일: MySQL 이 쓸 환경변수(처음 켤 때 사용자·DB 를 만든다).
        # └── ▼ 실행 코드 [13] ──────────────
        env:

          # ┌── 설명 ──────────────────────────────────
          # │ ▶ 이 줄이 하는 일: 시험용 관리자 비밀번호 root (시험 컴퓨터에서만 쓰고 사라짐).
          # └── ▼ 실행 코드 [14] ──────────────
          MYSQL_ROOT_PASSWORD: root

          # ┌── 설명 ──────────────────────────────────
          # │ ▶ 이 줄이 하는 일: 만들 DB 이름.
          # └── ▼ 실행 코드 [15] ──────────────
          MYSQL_DATABASE: publisher

          # ┌── 설명 ──────────────────────────────────
          # │ ▶ 이 줄이 하는 일: 시험용 사용자.
          # └── ▼ 실행 코드 [16] ──────────────
          MYSQL_USER: publisher

          # ┌── 설명 ──────────────────────────────────
          # │ ▶ 이 줄이 하는 일: 시험용 비밀번호.
          # └── ▼ 실행 코드 [17] ──────────────
          MYSQL_PASSWORD: publisher

        # ┌── 설명 ──────────────────────────────────
        # │ ▶ 이 줄이 하는 일: 컴퓨터의 3306 번을 MySQL 의 3306 번에 잇는다.
        # └── ▼ 실행 코드 [18] ──────────────
        ports: ["3306:3306"]

        # ┌── 설명 ──────────────────────────────────
        # │ ▶ 이 줄이 하는 일: MySQL 이 준비될 때까지(ping 이 될 때까지) steps 를 시작하지 않는다. >- = 아래 줄들을 한 줄로 이어 붙인다.
        # │   --health-cmd           : 준비됐는지 확인하는 명령.
        # │   --health-interval=5s … : 5초마다, 5초 제한, 최대 30번.
        # └── ▼ 실행 코드 [19] (아래 3줄이 한 덩어리) ────
        options: >-
          --health-cmd="mysqladmin ping -h 127.0.0.1 -proot"
          --health-interval=5s --health-timeout=5s --health-retries=30

    # ┌── 설명 ──────────────────────────────────
    # │ ▶ 이 줄이 하는 일: 모든 run 에 쓰일 기본값.
    # └── ▼ 실행 코드 [20] ──────────────
    defaults:

      # ┌── 설명 ──────────────────────────────────
      # │ ▶ 이 줄이 하는 일: 모든 run 명령의 기본값.
      # └── ▼ 실행 코드 [21] ──────────────
      run:

        # ┌── 설명 ──────────────────────────────────
        # │ ▶ 이 줄이 하는 일: run 명령은 모두 publisher-dashboard 폴더에서 실행한다.
        # └── ▼ 실행 코드 [22] ──────────────
        working-directory: publisher-dashboard

    # ┌── 설명 ──────────────────────────────────
    # │ ▶ 이 줄이 하는 일: 차례로 할 단계 목록.
    # └── ▼ 실행 코드 [23] ──────────────
    steps:

      # ┌── 설명 ──────────────────────────────────
      # │ ▶ 이 줄이 하는 일: 저장소 코드를 이 컴퓨터로 받아 온다.
      # │   uses                : 남이 만들어 둔 action(작업 묶음)을 쓴다.
      # │   actions/checkout@v4 : GitHub 공식 checkout 의 4판.
      # └── ▼ 실행 코드 [24] ──────────────
      - uses: actions/checkout@v4

      # ┌── 설명 ──────────────────────────────────
      # │ ▶ 이 줄이 하는 일: Java 를 설치한다. 아래 with: 가 설정값.
      # └── ▼ 실행 코드 [25] ──────────────
      - uses: actions/setup-java@v4

        # ┌── 설명 ──────────────────────────────────
        # │ ▶ 이 줄이 하는 일: action 에 넘기는 값들.
        # └── ▼ 실행 코드 [26] ──────────────
        with:

          # ┌── 설명 ──────────────────────────────────
          # │ ▶ 이 줄이 하는 일: Java 배포판 = Temurin(무료 OpenJDK).
          # └── ▼ 실행 코드 [27] ──────────────
          distribution: temurin

          # ┌── 설명 ──────────────────────────────────
          # │ ▶ 이 줄이 하는 일: Java 21.
          # └── ▼ 실행 코드 [28] ──────────────
          java-version: "21"

          # ┌── 설명 ──────────────────────────────────
          # │ ▶ 이 줄이 하는 일: 내려받은 라이브러리를 저장해 두었다가 다음 실행 때 다시 받지 않는다(빨라짐).
          # └── ▼ 실행 코드 [29] ──────────────
          cache: gradle

      # ┌── 설명 ──────────────────────────────────
      # │ ▶ 이 줄이 하는 일: 단계 이름.
      # └── ▼ 실행 코드 [30] ──────────────
      - name: 테스트 (H2 + 진짜 MySQL)

        # ┌── 설명 ──────────────────────────────────
        # │ ▶ 이 줄이 하는 일: 시험 27개를 돌리고 실행 파일(jar)도 만들어 본다.
        # │   chmod +x gradlew : 실행 권한(Windows 에서 올리면 빠질 수 있다).
        # │   test bootJar     : 시험 + jar 만들기.
        # │   --no-daemon      : 한 번 쓰고 끝낼 컴퓨터라 Gradle 상주 프로그램을 쓰지 않는다.
        # └── ▼ 실행 코드 [31] ──────────────
        run: chmod +x gradlew && ./gradlew test bootJar --no-daemon

        # ┌── 설명 ──────────────────────────────────
        # │ ▶ 이 줄이 하는 일: 이 단계에서만 쓰는 환경변수.
        # └── ▼ 실행 코드 [32] ──────────────
        env:

          # ┌── 설명 ──────────────────────────────────
          # │ ▶ 이 줄이 하는 일: 이 값이 있으면 MySqlMigrationTest(진짜 MySQL 시험)가 실행된다(@EnabledIfEnvironmentVariable).
          # └── ▼ 실행 코드 [33] ──────────────
          TEST_MYSQL_URL: jdbc:mysql://127.0.0.1:3306/publisher

          # ┌── 설명 ──────────────────────────────────
          # │ ▶ 이 줄이 하는 일: 시험 DB 사용자.
          # └── ▼ 실행 코드 [34] ──────────────
          TEST_MYSQL_USER: publisher

          # ┌── 설명 ──────────────────────────────────
          # │ ▶ 이 줄이 하는 일: 시험 DB 비밀번호.
          # └── ▼ 실행 코드 [35] ──────────────
          TEST_MYSQL_PASSWORD: publisher

      # ┌── 설명 ──────────────────────────────────
      # │ ▶ 이 줄이 하는 일: 단계 이름.
      # └── ▼ 실행 코드 [36] ──────────────
      - name: 테스트 결과 보관 (실패했을 때)

        # ┌── 설명 ──────────────────────────────────
        # │ ▶ 이 줄이 하는 일: 앞 단계가 실패했을 때만 이 단계를 한다.
        # └── ▼ 실행 코드 [37] ──────────────
        if: failure()

        # ┌── 설명 ──────────────────────────────────
        # │ ▶ 이 줄이 하는 일: 파일을 실행 기록에 붙여 내려받을 수 있게 보관한다.
        # └── ▼ 실행 코드 [38] ──────────────
        uses: actions/upload-artifact@v4

        # ┌── 설명 ──────────────────────────────────
        # │ ▶ 이 줄이 하는 일: 설정값.
        # └── ▼ 실행 코드 [39] ──────────────
        with:

          # ┌── 설명 ──────────────────────────────────
          # │ ▶ 이 줄이 하는 일: 보관 이름.
          # └── ▼ 실행 코드 [40] ──────────────
          name: test-report

          # ┌── 설명 ──────────────────────────────────
          # │ ▶ 이 줄이 하는 일: 보관할 폴더 = 시험 보고서(HTML).
          # └── ▼ 실행 코드 [41] ──────────────
          path: publisher-dashboard/build/reports/tests/test
PUBLISHER_FILE_25_END

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 파일 ~/my-publisher/tepo/templates/deploy-on-server.sh 를 만든다. (GitHub Actions 가 새 jar 를 올린 뒤 서버에서 부르는 스크립트. 새 버전으로 바꾸고 2분 안에 켜지지 않으면 이전 버전으로 되돌린다.)
# │   아래 125줄이 그 파일 내용 그대로이고, PUBLISHER_FILE_26_END 줄에서 끝난다.
# └── ▼ 실행 코드 [37] (아래 127줄이 한 덩어리) ────
cat > "$P/tepo/templates/deploy-on-server.sh" <<'PUBLISHER_FILE_26_END'
#!/bin/bash
# [1] 역할
#     GitHub Actions 가 새 jar 를 올린 뒤 서버에서 부르는 스크립트. 새 버전으로 바꾸고 2분 안에 켜지지 않으면 이전 버전으로 되돌린다.
#     맨 윗줄 #!/bin/bash : "쉬뱅(shebang)". 이 파일을 /bin/bash 프로그램으로 실행하라는 표시.
#       #! 는 파일 맨 처음에만 쓰며, 뒤에 적힌 프로그램(위치)으로 이 파일을 실행한다.
#
# [2] 받는 것 → 내보내는 것
#     받는 것  : 인자 1 = 새 jar (/tmp/app.jar)
#     내보내는 것: 성공  ✅ 새 버전 실행됨 (끝 코드 0)
#                  실패  ❌ 새 버전이 켜지지 않아 이전 버전으로 되돌립니다 + 로그 40줄, app.jar.prev → app.jar (끝 코드 1 → Actions 가 빨간불)
#
# [3] 앞뒤 파일
#     .github/workflows/deploy.yml 의 "서버에 올리고 바꾸기"  →  ssh … sudo /opt/publisher/deploy-on-server.sh /tmp/app.jar  →  (이 파일)
#
# [4] 메서드 목록
#     줄                  하는 일
#     cp app.jar .prev     지금 버전을 보관
#     install              새 jar 로 바꾸기
#     systemctl restart    다시 켜기
#     for … curl           최대 2분 health 확인
#     되돌리기              .prev 로 되돌리고 다시 켜기, exit 1
#
# [5] 먼저 알 용어
#     set -euo pipefail, cp, install, systemctl restart, && { …; exit 0; }
#
# [6] 읽는 순서
#     위에서 아래로
#
# [7] 다 읽고 확인
#     - 새 버전에 Flyway 오류가 있으면 사장님 화면은 몇 분 동안 꺼져 있는가? (확인 2분 + 이전 버전이 다시 켜지는 시간)
#     - exit 1 이 없으면 GitHub Actions 는 배포를 성공으로 보는가?
#
# [0] 코드만 모아 보기 — 이 파일에서 실제로 실행되는 줄 전체. 아래 본문에서 ▼ 실행 코드 [번호] 를 찾으면 그 줄의 설명이 있다.
#     [1] set -euo pipefail
#     [2] NEW="$1"; APP=/opt/publisher/app.jar
#     [3] cp "$APP" "$APP.prev"
#     [4] install -m 644 -o publisher "$NEW" "$APP"
#     [5] systemctl restart publisher-dashboard
#     [6] for i in $(seq 1 40); do
#     [7]   curl -fsS http://127.0.0.1:8080/actuator/health 2>/dev/null | grep -q UP && { echo "✅ 새 버전 실행됨"; e…
#     [8]   sleep 3
#     [9] done
#     [10] echo "❌ 새 버전이 켜지지 않아 이전 버전으로 되돌립니다"
#     [11] journalctl -u publisher-dashboard -n 40 --no-pager || true
#     [12] cp "$APP.prev" "$APP"
#     [13] systemctl restart publisher-dashboard
#     [14] exit 1

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 오류가 나면 바로 멈추게 하는 안전 설정.
# │   -e          : 명령 하나라도 실패하면 즉시 멈춘다.
# │   -u          : 정하지 않은 변수를 쓰면 멈춘다.
# │   -o pipefail : a | b 에서 a 가 실패해도 실패로 본다.
# └── ▼ 실행 코드 [1] ───────────────
set -euo pipefail

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 새 jar 위치(첫 번째 값)를 NEW 에, 실제로 실행되는 jar 위치를 APP 에 담는다. 예) NEW=/tmp/publisher-dashboard.jar
# └── ▼ 실행 코드 [2] ───────────────
NEW="$1"; APP=/opt/publisher/app.jar

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 지금 jar 를 app.jar.prev 로 복사해 둔다(새 판이 안 켜지면 되돌리려고).
# └── ▼ 실행 코드 [3] ───────────────
cp "$APP" "$APP.prev"

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 새 jar 를 app.jar 자리에 놓는다. 권한 644(모두 읽기), 주인 publisher.
# │   -o 사용자 : 파일 주인.
# └── ▼ 실행 코드 [4] ───────────────
install -m 644 -o publisher "$NEW" "$APP"

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 관리 화면 서비스를 다시 켠다(새 jar 로).
# │   systemctl : 서버의 서비스(systemd)를 켜고 끄는 명령.
# └── ▼ 실행 코드 [5] ───────────────
systemctl restart publisher-dashboard

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 3초마다 최대 40번(2분) 새 판이 살아났는지 확인한다.
# └── ▼ 실행 코드 [6] ───────────────
for i in $(seq 1 40); do

  # ┌── 설명 ──────────────────────────────────
  # │ ▶ 이 줄이 하는 일: 서버 안에서 8080 에 직접 물어 UP 이면 ✅ 를 찍고 성공으로 끝낸다.
  # │   127.0.0.1 : 서버 자기 자신.
  # └── ▼ 실행 코드 [7] ───────────────
  curl -fsS http://127.0.0.1:8080/actuator/health 2>/dev/null | grep -q UP && { echo "✅ 새 버전 실행됨"; exit 0; }

  # ┌── 설명 ──────────────────────────────────
  # │ ▶ 이 줄이 하는 일: 3초 쉰다.
  # └── ▼ 실행 코드 [8] ───────────────
  sleep 3

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 위 for / while 반복의 끝
# └── ▼ 실행 코드 [9] ───────────────
done

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 2분 안에 안 켜졌다고 알린다.
# └── ▼ 실행 코드 [10] ──────────────
echo "❌ 새 버전이 켜지지 않아 이전 버전으로 되돌립니다"

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 실패 원인을 보도록 서비스 기록 마지막 40줄을 찍는다.
# │   --no-pager : 화면 넘김 없이 바로 찍는다.
# │   || true    : 기록 보기가 실패해도 계속.
# └── ▼ 실행 코드 [11] ──────────────
journalctl -u publisher-dashboard -n 40 --no-pager || true

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 예전 jar 로 되돌린다.
# └── ▼ 실행 코드 [12] ──────────────
cp "$APP.prev" "$APP"

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 예전 판으로 다시 켠다. 사장님 화면은 예전 판으로 계속 열린다.
# └── ▼ 실행 코드 [13] ──────────────
systemctl restart publisher-dashboard

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 실패로 끝낸다 → GitHub Actions 의 배포 단계가 빨간색(실패)이 된다.
# └── ▼ 실행 코드 [14] ──────────────
exit 1
PUBLISHER_FILE_26_END

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 파일 ~/my-publisher/tepo/templates/deploy.yml 를 만든다. (CD(지속적 배포): main 에 합쳐지면 CI 검사 → 실행 파일 만들기 → 라이트세일 서버에 올리기 → HTTPS 로 살아 있는지 확인.)
# │   아래 286줄이 그 파일 내용 그대로이고, PUBLISHER_FILE_27_END 줄에서 끝난다.
# └── ▼ 실행 코드 [38] (아래 288줄이 한 덩어리) ────
cat > "$P/tepo/templates/deploy.yml" <<'PUBLISHER_FILE_27_END'
# [1] 역할
#     CD(지속적 배포): main 에 합쳐지면 CI 검사 → 실행 파일 만들기 → 라이트세일 서버에 올리기 → HTTPS 로 살아 있는지 확인.
#     서버가 새 버전으로 켜지지 않으면 서버의 deploy-on-server.sh 가 이전 버전으로 되돌리고 이 workflow 는 빨간불이 된다.
#     YAML 읽는 법: "이름: 값". 들여쓰기(띄어쓰기 2칸)로 무엇이 무엇 안에 들어가는지 나타낸다. "- " 는 목록의 한 칸.
#       # 뒤는 설명(주석)이라 GitHub 가 읽지 않는다. run: | 아래 줄들은 셸 명령이고, 그 안의 # 줄은 셸 주석이다.
#
# [2] 받는 것 → 내보내는 것
#     받는 것  : main 에 push (또는 Actions 화면의 Run workflow 단추)
#               Secrets: LIGHTSAIL_HOST(3.35.10.20 같은 IP), LIGHTSAIL_USER(ubuntu), LIGHTSAIL_SSH_KEY(비밀 열쇠), LIGHTSAIL_DOMAIN(3-35-10-20.sslip.io)
#     내보내는 것: 서버의 /opt/publisher/app.jar 가 새 버전으로 바뀌고, https://3-35-10-20.sslip.io/actuator/health → {"status":"UP"}
#
# [3] 앞뒤 파일
#     tepo/github-setup.sh 의 git push  →  (이 파일)  →  ci.yml(검사)  →  scp·ssh  →  서버의 /opt/publisher/deploy-on-server.sh
#
# [4] 메서드 목록
#     구역                    하는 일
#     on                      main push, 손으로 실행(workflow_dispatch)
#     concurrency             배포가 동시에 두 개 돌지 않게 (뒤 것은 기다림)
#     jobs.test               ci.yml 을 그대로 실행
#     jobs.deploy (needs)     test 가 성공해야 시작: bootJar → 열쇠 준비 → 올리고 바꾸기 → HTTPS 확인
#
# [5] 먼저 알 용어
#     needs, uses: ./.github/workflows/ci.yml(재사용), concurrency, ${{ secrets.이름 }}, ssh-keyscan, run: |(여러 줄)
#
# [6] 읽는 순서
#     on → jobs.test → jobs.deploy 의 steps
#
# [7] 다 읽고 확인
#     - 테스트가 하나라도 실패하면 서버에 올라가는가? (아니다. needs: test)
#     - Secrets 값이 Actions 로그에 찍히면 어떻게 보이는가? (GitHub 가 *** 로 가린다)
#
# [0] 코드만 모아 보기 — 이 파일에서 실제로 읽히는 설정 줄 전체(# 설명 줄 제외). 아래 본문에서 ▼ 실행 코드 [번호] 를 찾으면 그 줄의 설명이 있다.
#     [1] name: Deploy to Lightsail
#     [2] on:
#     [3]   push:
#     [4]     branches: [main]
#     [5]   workflow_dispatch:
#     [6] concurrency:
#     [7]   group: deploy-lightsail
#     [8]   cancel-in-progress: false
#     [9] jobs:
#     [10]   test:
#     [11]     uses: ./.github/workflows/ci.yml
#     [12]   deploy:
#     [13]     needs: test
#     [14]     runs-on: ubuntu-latest
#     [15]     steps:
#     [16]       - uses: actions/checkout@v4
#     [17]       - uses: actions/setup-java@v4
#     [18]         with:
#     [19]           distribution: temurin
#     [20]           java-version: "21"
#     [21]           cache: gradle
#     [22]       - name: 실행 파일 만들기
#     [23]         working-directory: publisher-dashboard
#     [24]         run: chmod +x gradlew && ./gradlew bootJar --no-daemon -x test
#     [25]       - name: 서버 열쇠 준비
#     [26]         run: |
#     [27]           mkdir -p ~/.ssh
#     [28]           echo "${{ secrets.LIGHTSAIL_SSH_KEY }}" > ~/.ssh/lightsail
#     [29]           chmod 600 ~/.ssh/lightsail
#     [30]           ssh-keyscan -H "${{ secrets.LIGHTSAIL_HOST }}" >> ~/.ssh/known_hosts
#     [31]       - name: 서버에 올리고 바꾸기 (안 켜지면 자동으로 되돌림)
#     [32]         run: |
#     [33]           scp -i ~/.ssh/lightsail publisher-dashboard/build/libs/publisher-dashboard.jar \   (+1줄)
#     [34]           ssh -i ~/.ssh/lightsail "${{ secrets.LIGHTSAIL_USER }}@${{ secrets.LIGHTSAIL_HOST }}" \   (+1줄)
#     [35]       - name: HTTPS 로 살아 있는지 확인
#     [36]         run: |
#     [37]           for _ in $(seq 1 20); do
#     [38]             curl -fsS "https://${{ secrets.LIGHTSAIL_DOMAIN }}/actuator/health" && exit 0
#     [39]             sleep 6
#     [40]           done
#     [41]           exit 1

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 이 workflow 의 이름(Actions 탭에 보임).
# └── ▼ 실행 코드 [1] ───────────────
name: Deploy to Lightsail

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 언제 실행할지.
# └── ▼ 실행 코드 [2] ───────────────
on:

  # ┌── 설명 ──────────────────────────────────
  # │ ▶ 이 줄이 하는 일: push 할 때(아래 조건).
  # └── ▼ 실행 코드 [3] ───────────────
  push:

    # ┌── 설명 ──────────────────────────────────
    # │ ▶ 이 줄이 하는 일: main 가지에 올라왔을 때만. github-setup.sh 의 git push … main 이 이것을 시작시킨다.
    # └── ▼ 실행 코드 [4] ───────────────
    branches: [main]

  # ┌── 설명 ──────────────────────────────────
  # │ ▶ 이 줄이 하는 일: Actions 화면에서 "Run workflow" 단추로 손으로 실행할 수 있다.
  # └── ▼ 실행 코드 [5] ───────────────
  workflow_dispatch:

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 동시에 여러 번 돌지 않게 하는 설정.
# └── ▼ 실행 코드 [6] ───────────────
concurrency:

  # ┌── 설명 ──────────────────────────────────
  # │ ▶ 이 줄이 하는 일: 같은 이름의 실행은 한 번에 하나만.
  # └── ▼ 실행 코드 [7] ───────────────
  group: deploy-lightsail

  # ┌── 설명 ──────────────────────────────────
  # │ ▶ 이 줄이 하는 일: 도는 중인 배포를 취소하지 않고 끝날 때까지 기다린다(반쯤 바뀐 서버가 되지 않게).
  # └── ▼ 실행 코드 [8] ───────────────
  cancel-in-progress: false

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 할 일 목록.
# └── ▼ 실행 코드 [9] ───────────────
jobs:

  # ┌── 설명 ──────────────────────────────────
  # │ ▶ 이 줄이 하는 일: job test.
  # └── ▼ 실행 코드 [10] ──────────────
  test:

    # ┌── 설명 ──────────────────────────────────
    # │ ▶ 이 줄이 하는 일: ci.yml 을 그대로 불러 검사한다(workflow_call).
    # └── ▼ 실행 코드 [11] ──────────────
    uses: ./.github/workflows/ci.yml

  # ┌── 설명 ──────────────────────────────────
  # │ ▶ 이 줄이 하는 일: job deploy (서버에 올리기).
  # └── ▼ 실행 코드 [12] ──────────────
  deploy:

    # ┌── 설명 ──────────────────────────────────
    # │ ▶ 이 줄이 하는 일: test 가 성공해야 시작한다. 시험이 하나라도 실패하면 서버에 올리지 않는다.
    # └── ▼ 실행 코드 [13] ──────────────
    needs: test

    # ┌── 설명 ──────────────────────────────────
    # │ ▶ 이 줄이 하는 일: GitHub 가 빌려주는 Ubuntu 컴퓨터.
    # └── ▼ 실행 코드 [14] ──────────────
    runs-on: ubuntu-latest

    # ┌── 설명 ──────────────────────────────────
    # │ ▶ 이 줄이 하는 일: 단계 목록.
    # └── ▼ 실행 코드 [15] ──────────────
    steps:

      # ┌── 설명 ──────────────────────────────────
      # │ ▶ 이 줄이 하는 일: 저장소 코드를 이 컴퓨터로 받아 온다.
      # │   uses                : 남이 만들어 둔 action(작업 묶음)을 쓴다.
      # │   actions/checkout@v4 : GitHub 공식 checkout 의 4판.
      # └── ▼ 실행 코드 [16] ──────────────
      - uses: actions/checkout@v4

      # ┌── 설명 ──────────────────────────────────
      # │ ▶ 이 줄이 하는 일: Java 를 설치한다. 아래 with: 가 설정값.
      # └── ▼ 실행 코드 [17] ──────────────
      - uses: actions/setup-java@v4

        # ┌── 설명 ──────────────────────────────────
        # │ ▶ 이 줄이 하는 일: action 에 넘기는 값들.
        # └── ▼ 실행 코드 [18] ──────────────
        with:

          # ┌── 설명 ──────────────────────────────────
          # │ ▶ 이 줄이 하는 일: Java 배포판 = Temurin(무료 OpenJDK).
          # └── ▼ 실행 코드 [19] ──────────────
          distribution: temurin

          # ┌── 설명 ──────────────────────────────────
          # │ ▶ 이 줄이 하는 일: Java 21.
          # └── ▼ 실행 코드 [20] ──────────────
          java-version: "21"

          # ┌── 설명 ──────────────────────────────────
          # │ ▶ 이 줄이 하는 일: 내려받은 라이브러리를 저장해 두었다가 다음 실행 때 다시 받지 않는다(빨라짐).
          # └── ▼ 실행 코드 [21] ──────────────
          cache: gradle

      # ┌── 설명 ──────────────────────────────────
      # │ ▶ 이 줄이 하는 일: 단계 이름.
      # └── ▼ 실행 코드 [22] ──────────────
      - name: 실행 파일 만들기

        # ┌── 설명 ──────────────────────────────────
        # │ ▶ 이 줄이 하는 일: 이 폴더에서.
        # └── ▼ 실행 코드 [23] ──────────────
        working-directory: publisher-dashboard

        # ┌── 설명 ──────────────────────────────────
        # │ ▶ 이 줄이 하는 일: jar 를 만든다. -x test = 시험은 앞의 test 에서 이미 했으므로 건너뛴다.
        # └── ▼ 실행 코드 [24] ──────────────
        run: chmod +x gradlew && ./gradlew bootJar --no-daemon -x test

      # ┌── 설명 ──────────────────────────────────
      # │ ▶ 이 줄이 하는 일: 단계 이름. 아래 run: | 의 4줄이 한 셸 스크립트로 실행된다.
      # │   run: | : | = 아래 들여쓴 줄들을 줄바꿈 그대로 하나의 글로.
      # └── ▼ 실행 코드 [25] ──────────────
      - name: 서버 열쇠 준비

        # ┌── 설명 ──────────────────────────────────
        # │ ▶ 이 줄이 하는 일: 아래 줄들을 셸로 실행.
        # └── ▼ 실행 코드 [26] ──────────────
        run: |

          # ┌── 설명 ──────────────────────────────────
          # │ ▶ 이 줄이 하는 일: SSH 폴더를 만든다.
          # └── ▼ 실행 코드 [27] ──────────────
          mkdir -p ~/.ssh

          # ┌── 설명 ──────────────────────────────────
          # │ ▶ 이 줄이 하는 일: Secret 에 저장된 SSH 열쇠를 파일로 쓴다. 로그에는 *** 로 가려진다.
          # │   secrets.LIGHTSAIL_SSH_KEY : 달러 표시와 이중 중괄호로 감싼 이 이름 자리를, GitHub 가 실행 전에
          # │                               github-setup.sh 가 등록한 Secret 값으로 바꿔 넣는다.
          # │                               (이 설명 안에 그 표시를 그대로 쓰면 GitHub 가 설명 글까지 계산하려다 실패하므로 글로만 적는다)
          # └── ▼ 실행 코드 [28] ──────────────
          echo "${{ secrets.LIGHTSAIL_SSH_KEY }}" > ~/.ssh/lightsail

          # ┌── 설명 ──────────────────────────────────
          # │ ▶ 이 줄이 하는 일: 열쇠는 나만 읽게.
          # └── ▼ 실행 코드 [29] ──────────────
          chmod 600 ~/.ssh/lightsail

          # ┌── 설명 ──────────────────────────────────
          # │ ▶ 이 줄이 하는 일: 서버의 공개 키를 known_hosts 에 넣어, 처음 접속할 때 "믿을까요?" 질문이 나오지 않게 한다.
          # └── ▼ 실행 코드 [30] ──────────────
          ssh-keyscan -H "${{ secrets.LIGHTSAIL_HOST }}" >> ~/.ssh/known_hosts

      # ┌── 설명 ──────────────────────────────────
      # │ ▶ 이 줄이 하는 일: 단계 이름.
      # └── ▼ 실행 코드 [31] ──────────────
      - name: 서버에 올리고 바꾸기 (안 켜지면 자동으로 되돌림)

        # ┌── 설명 ──────────────────────────────────
        # │ ▶ 이 줄이 하는 일: 아래 두 명령(각각 줄 끝 \ 로 2줄)을 셸로 실행.
        # └── ▼ 실행 코드 [32] ──────────────
        run: |

          # ┌── 설명 ──────────────────────────────────
          # │ ▶ 이 줄이 하는 일: (1) jar 를 서버의 /tmp/app.jar 로 복사한다.
          # └── ▼ 실행 코드 [33] (아래 2줄이 한 덩어리) ────
          scp -i ~/.ssh/lightsail publisher-dashboard/build/libs/publisher-dashboard.jar \
            "${{ secrets.LIGHTSAIL_USER }}@${{ secrets.LIGHTSAIL_HOST }}:/tmp/app.jar"

          # ┌── 설명 ──────────────────────────────────
          # │ ▶ 이 줄이 하는 일: (2) 서버에서 deploy-on-server.sh 를 실행한다 → 새 판이 안 켜지면 예전 판으로 되돌리고 실패(exit 1).
          # └── ▼ 실행 코드 [34] (아래 2줄이 한 덩어리) ────
          ssh -i ~/.ssh/lightsail "${{ secrets.LIGHTSAIL_USER }}@${{ secrets.LIGHTSAIL_HOST }}" \
            "sudo /opt/publisher/deploy-on-server.sh /tmp/app.jar"

      # ┌── 설명 ──────────────────────────────────
      # │ ▶ 이 줄이 하는 일: 단계 이름. 바깥(인터넷)에서 Caddy 를 거쳐 확인한다.
      # └── ▼ 실행 코드 [35] ──────────────
      - name: HTTPS 로 살아 있는지 확인

        # ┌── 설명 ──────────────────────────────────
        # │ ▶ 이 줄이 하는 일: 아래 줄들을 셸로 실행.
        # └── ▼ 실행 코드 [36] ──────────────
        run: |

          # ┌── 설명 ──────────────────────────────────
          # │ ▶ 이 줄이 하는 일: 6초마다 최대 20번(2분). _ = 쓰지 않는 반복 변수.
          # └── ▼ 실행 코드 [37] ──────────────
          for _ in $(seq 1 20); do

            # ┌── 설명 ──────────────────────────────────
            # │ ▶ 이 줄이 하는 일: health 주소가 대답하면 성공(exit 0)으로 끝낸다.
            # └── ▼ 실행 코드 [38] ──────────────
            curl -fsS "https://${{ secrets.LIGHTSAIL_DOMAIN }}/actuator/health" && exit 0

            # ┌── 설명 ──────────────────────────────────
            # │ ▶ 이 줄이 하는 일: 6초 쉰다.
            # └── ▼ 실행 코드 [39] ──────────────
            sleep 6

          # ┌── 설명 ──────────────────────────────────
          # │ ▶ 이 줄이 하는 일: 위 for / while 반복의 끝
          # └── ▼ 실행 코드 [40] ──────────────
          done

          # ┌── 설명 ──────────────────────────────────
          # │ ▶ 이 줄이 하는 일: 2분 안에 대답이 없으면 실패 → Actions 가 빨간색.
          # └── ▼ 실행 코드 [41] ──────────────
          exit 1
PUBLISHER_FILE_27_END

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 파일 ~/my-publisher/tepo/templates/gitignore 를 만든다. (GitHub 에 올리지 않을 파일 목록. github-setup.sh 가 저장소 맨 위에 .gitignore 로 복사한다.)
# │   아래 103줄이 그 파일 내용 그대로이고, PUBLISHER_FILE_28_END 줄에서 끝난다.
# └── ▼ 실행 코드 [39] (아래 105줄이 한 덩어리) ────
cat > "$P/tepo/templates/gitignore" <<'PUBLISHER_FILE_28_END'
# [1] 역할
#     GitHub 에 올리지 않을 파일 목록. github-setup.sh 가 저장소 맨 위에 .gitignore 로 복사한다.
#     한 줄에 규칙 하나: 폴더/ = 그 폴더 전체, *.확장자 = 그 확장자 전부, ! = 앞 규칙의 예외.
#
# [2] 받는 것 → 내보내는 것
#     받는 것  : git add -A
#     내보내는 것: 아래 규칙에 맞는 파일은 commit 목록에 들어가지 않는다.  예) publisher-dashboard/build/libs/publisher-dashboard.jar (빠짐)
#       gradle/wrapper/gradle-wrapper.jar 는 예외라 올라간다 (Actions 가 ./gradlew 를 실행하려면 필요)
#
# [3] 앞뒤 파일
#     tepo/github-setup.sh  →  ~/ai-publisher/.gitignore
#
# [4] 메서드 목록
#     구역                하는 일
#     빌드 결과·IDE         build/, .gradle/, .idea/, *.jar (wrapper 제외)
#     비밀·DB 파일          ops/, *.env, *.mv.db, *.trace.db
#
# [5] 먼저 알 용어
#     .gitignore 규칙(폴더/, *.확장자, !예외)
#
# [6] 읽는 순서
#     위에서 아래로
#
# [7] 다 읽고 확인
#     - *.env 줄이 없으면 어떤 위험이 있는가? (비밀번호가 든 파일이 GitHub 에 올라갈 수 있다)
#     - 이미 commit 한 파일을 나중에 .gitignore 에 적으면 GitHub 에서 사라지는가? (아니다. git rm --cached 로 따로 빼야 한다)
#
# [0] 코드만 모아 보기 — 이 파일에서 실제로 쓰이는 규칙 줄 전체. 아래 본문에서 ▼ 실행 코드 [번호] 를 찾으면 그 줄의 설명이 있다.
#     [1] publisher-dashboard/build/
#     [2] publisher-dashboard/.gradle/
#     [3] .gradle/
#     [4] .idea/
#     [5] *.iml
#     [6] out/
#     [7] *.jar
#     [8] !publisher-dashboard/gradle/wrapper/gradle-wrapper.jar
#     [9] ops/
#     [10] *.env
#     [11] *.mv.db
#     [12] *.trace.db

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 관리 화면을 빌드하면 생기는 결과 폴더(다시 만들 수 있으니 올리지 않음).
# │   폴더/ : 끝에 / 가 있으면 그 폴더 전체.
# └── ▼ 실행 코드 [1] ───────────────
publisher-dashboard/build/

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: Gradle 이 쓰는 임시 폴더.
# └── ▼ 실행 코드 [2] ───────────────
publisher-dashboard/.gradle/

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 맨 위의 Gradle 임시 폴더.
# └── ▼ 실행 코드 [3] ───────────────
.gradle/

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: IntelliJ 설정 폴더(사람마다 다름).
# └── ▼ 실행 코드 [4] ───────────────
.idea/

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: IntelliJ 모듈 파일.
# │   * : 아무 글자. *.iml = .iml 로 끝나는 모든 파일.
# └── ▼ 실행 코드 [5] ───────────────
*.iml

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: IntelliJ 가 만드는 결과 폴더.
# └── ▼ 실행 코드 [6] ───────────────
out/

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: jar 파일(큰 실행 파일). GitHub Actions 가 새로 만든다.
# └── ▼ 실행 코드 [7] ───────────────
*.jar

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 예외: Gradle 시작용 작은 jar 는 올린다(없으면 ./gradlew 가 안 된다).
# │   ! : 앞 규칙의 예외(올림).
# └── ▼ 실행 코드 [8] ───────────────
!publisher-dashboard/gradle/wrapper/gradle-wrapper.jar

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 배포 기록·비밀 폴더. 절대 올리지 않는다(DB 비밀번호, SSH 열쇠).
# └── ▼ 실행 코드 [9] ───────────────
ops/

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: .env 로 끝나는 파일(비밀값이 들어 있는 설정).
# └── ▼ 실행 코드 [10] ──────────────
*.env

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 내 PC 의 H2 데이터베이스 파일.
# └── ▼ 실행 코드 [11] ──────────────
*.mv.db

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: H2 의 오류 기록 파일.
# └── ▼ 실행 코드 [12] ──────────────
*.trace.db
PUBLISHER_FILE_28_END

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 파일 ~/my-publisher/tepo/templates/remote-setup.sh 를 만든다. (서버(라이트세일 Ubuntu)에서 root 로 한 번 실행되는 설치 스크립트. server-setup.sh 가 scp 로 올리고 ssh 로 실행한다.)
# │   아래 202줄이 그 파일 내용 그대로이고, PUBLISHER_FILE_29_END 줄에서 끝난다.
# └── ▼ 실행 코드 [40] (아래 204줄이 한 덩어리) ────
cat > "$P/tepo/templates/remote-setup.sh" <<'PUBLISHER_FILE_29_END'
#!/bin/bash
# [1] 역할
#     서버(라이트세일 Ubuntu)에서 root 로 한 번 실행되는 설치 스크립트. server-setup.sh 가 scp 로 올리고 ssh 로 실행한다.
#     Java·Caddy 를 설치하고, 관리 화면을 systemd 서비스로 등록하고, Caddy 가 HTTPS 를 받아 127.0.0.1:8080 으로 넘기게 한다.
#     맨 윗줄 #!/bin/bash : "쉬뱅(shebang)". 이 파일을 /bin/bash 프로그램으로 실행하라는 표시.
#       #! 는 파일 맨 처음에만 쓰며, 뒤에 적힌 프로그램(위치)으로 이 파일을 실행한다.
#
# [2] 받는 것 → 내보내는 것
#     받는 것  : 인자 1 = 주소 (예: 3-35-10-20.sslip.io), 인자 2 = 환경 파일 경로 (/tmp/tmp.…)
#     내보내는 것: /etc/publisher/dashboard.env (600), /opt/publisher/app.jar, publisher-dashboard 서비스, /etc/caddy/Caddyfile
#       성공  ✅ 관리 화면 실행됨      실패  journalctl 로그 40줄 + ❌ 관리 화면이 2분 안에 켜지지 않았어요
#
# [3] 앞뒤 파일
#     tepo/server-setup.sh  →  (이 파일, 서버에서)  →  systemd → java -jar app.jar --spring.profiles.active=prod (application-prod.yml)
#                                                    →  Caddy → https://주소 → 127.0.0.1:8080
#
# [4] 메서드 목록
#     구역              하는 일
#     apt-get           Java 21, Caddy, curl 설치
#     사용자·폴더        publisher 시스템 사용자, /opt/publisher, /etc/publisher
#     install           환경 파일(600, root), deploy-on-server.sh, app.jar
#     systemd 단위      관리 화면을 서비스로 (꺼지면 5초 뒤 다시 켬)
#     Caddyfile         주소 → 127.0.0.1:8080, 인증서는 Caddy 가 자동으로
#     확인              /actuator/health 가 UP 이 될 때까지 최대 2분
#
# [5] 먼저 알 용어
#     $1·$2(인자), apt-get, useradd --system, install -m -o -g, systemd(Unit·Service·Install), Caddy reverse_proxy, heredoc <<'UNIT'(변수 안 바꿈)
#
# [6] 읽는 순서
#     apt-get → install → systemd 단위 → Caddyfile → 확인
#
# [7] 다 읽고 확인
#     - <<'UNIT' 처럼 따옴표를 붙인 heredoc 은 <<CADDY 와 무엇이 다른가? ($변수를 값으로 바꾸지 않는다)
#     - 관리 화면을 root 가 아닌 publisher 사용자로 실행하는 이유는?
#
# [0] 코드만 모아 보기 — 이 파일에서 실제로 실행되는 줄 전체. 아래 본문에서 ▼ 실행 코드 [번호] 를 찾으면 그 줄의 설명이 있다.
#     [1] set -euo pipefail
#     [2] HOST="$1"; ENVF="$2"
#     [3] export DEBIAN_FRONTEND=noninteractive
#     [4] apt-get update -q
#     [5] apt-get install -y -q openjdk-21-jre-headless caddy curl >/dev/null
#     [6] id publisher >/dev/null 2>&1 || useradd --system --home /opt/publisher --shell /usr/sbin/nologin publisher
#     [7] mkdir -p /opt/publisher/data/books /etc/publisher
#     [8] install -m 600 -o root -g root "$ENVF" /etc/publisher/dashboard.env
#     [9] rm -f "$ENVF"   # 비밀번호가 든 임시 파일은 바로 지움
#     [10] install -m 755 /tmp/deploy-on-server.sh /opt/publisher/deploy-on-server.sh
#     [11] install -m 644 -o publisher /tmp/publisher-dashboard.jar /opt/publisher/app.jar
#     [12] chown -R publisher:publisher /opt/publisher/data
#     [13] cat > /etc/systemd/system/publisher-dashboard.service <<'UNIT'   (+16줄)
#     [14] cat > /etc/caddy/Caddyfile <<CADDY   (+5줄)
#     [15] systemctl daemon-reload
#     [16] systemctl enable --now publisher-dashboard
#     [17] systemctl restart caddy
#     [18] for i in $(seq 1 40); do curl -fsS http://127.0.0.1:8080/actuator/health 2>/dev/null | grep -q UP && { echo…
#     [19] journalctl -u publisher-dashboard -n 40 --no-pager
#     [20] echo "❌ 관리 화면이 2분 안에 켜지지 않았어요"; exit 1

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 오류가 나면 바로 멈추게 하는 안전 설정.
# │   -e          : 명령 하나라도 실패하면 즉시 멈춘다.
# │   -u          : 정하지 않은 변수를 쓰면 멈춘다.
# │   -o pipefail : a | b 에서 a 가 실패해도 실패로 본다.
# └── ▼ 실행 코드 [1] ───────────────
set -euo pipefail

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 받은 두 값: 주소와 환경 파일 경로. 예) HOST=3-35-10-20.sslip.io  ENVF=/tmp/tmp.X1y2
# └── ▼ 실행 코드 [2] ───────────────
HOST="$1"; ENVF="$2"

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: apt 가 설치 중에 질문 창을 띄우지 않게 한다(사람이 없는 설치).
# └── ▼ 실행 코드 [3] ───────────────
export DEBIAN_FRONTEND=noninteractive

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: Ubuntu 설치 프로그램 목록을 새로 받는다.
# │   apt-get : Ubuntu 의 프로그램 설치 도구.
# └── ▼ 실행 코드 [4] ───────────────
apt-get update -q

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: Java 21(화면 없는 판), Caddy(HTTPS 문지기 프로그램), curl 을 설치한다.
# │   -y    : "설치할까요?" 에 자동으로 예.
# │   caddy : HTTPS 인증서를 저절로 받아 오고, 바깥 요청을 8080 의 관리 화면으로 넘겨 주는 웹 서버.
# └── ▼ 실행 코드 [5] ───────────────
apt-get install -y -q openjdk-21-jre-headless caddy curl >/dev/null

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 관리 화면을 실행할 전용 사용자 publisher 를 만든다(없을 때만). 로그인은 할 수 없다.
# │   root(관리자)로 실행하지 않아, 관리 화면에 문제가 생겨도 서버 전체가 위험해지지 않게 한다.
# │   id 사용자                 : 그 사용자가 있으면 성공.
# │   useradd --system          : 시스템용 사용자 만들기.
# │   --shell /usr/sbin/nologin : 로그인 불가.
# └── ▼ 실행 코드 [6] ───────────────
id publisher >/dev/null 2>&1 || useradd --system --home /opt/publisher --shell /usr/sbin/nologin publisher

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 관리 화면 데이터 폴더와 설정 폴더를 만든다.
# └── ▼ 실행 코드 [7] ───────────────
mkdir -p /opt/publisher/data/books /etc/publisher

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 환경 파일(DB 비밀번호 등)을 /etc/publisher/dashboard.env 로 옮긴다. 600 + root = root 만 읽는다.
# │   systemd 가 root 로 읽어 서비스에 넘긴다.
# │   -g 그룹 : 파일 그룹.
# └── ▼ 실행 코드 [8] ───────────────
install -m 600 -o root -g root "$ENVF" /etc/publisher/dashboard.env

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 비밀번호가 든 임시 파일을 바로 지운다.
# │   # 비밀번호가 … : 줄 끝 짧은 설명.
# └── ▼ 실행 코드 [9] ───────────────
rm -f "$ENVF"   # 비밀번호가 든 임시 파일은 바로 지움

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: GitHub Actions 가 배포 때 부를 deploy-on-server.sh 를 제자리에 둔다(실행 가능).
# └── ▼ 실행 코드 [10] ──────────────
install -m 755 /tmp/deploy-on-server.sh /opt/publisher/deploy-on-server.sh

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 첫 jar 를 app.jar 로 둔다.
# └── ▼ 실행 코드 [11] ──────────────
install -m 644 -o publisher /tmp/publisher-dashboard.jar /opt/publisher/app.jar

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 데이터 폴더 전체의 주인을 publisher 로.
# │   chown -R 주인:그룹 : 안의 파일까지 모두 주인 바꾸기.
# └── ▼ 실행 코드 [12] ──────────────
chown -R publisher:publisher /opt/publisher/data

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: systemd 서비스 정의 파일을 쓴다(아래 15줄이 파일 내용, UNIT 줄에서 끝).
# │   서버를 다시 켜도 관리 화면이 저절로 켜진다.
# │   따옴표 붙은 <<'UNIT' 이라 안의 $ 는 그대로 적힌다.
# │   [Unit] After=network-online.target                   : 인터넷 연결이 된 뒤에 켠다.
# │   User=publisher                                       : publisher 사용자로 실행.
# │   EnvironmentFile=…                                    : 환경 파일의 값들을 환경변수로 넣는다.
# │   ExecStart=… -Xmx512m … --spring.profiles.active=prod : 실행 명령. 메모리 최대 512MB, 서버용 설정(application-prod.yml).
# │   Restart=always / RestartSec=5                        : 꺼지면 5초 뒤 다시 켠다.
# │   WantedBy=multi-user.target                           : 서버가 켜질 때 함께 켠다.
# └── ▼ 실행 코드 [13] (아래 17줄이 한 덩어리) ────
cat > /etc/systemd/system/publisher-dashboard.service <<'UNIT'
[Unit]
Description=1인 AI 출판사 관리 화면
After=network-online.target
Wants=network-online.target

[Service]
User=publisher
WorkingDirectory=/opt/publisher
EnvironmentFile=/etc/publisher/dashboard.env
ExecStart=/usr/bin/java -Xmx512m -jar /opt/publisher/app.jar --spring.profiles.active=prod
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
UNIT

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: Caddy 설정을 쓴다(아래 4줄, CADDY 에서 끝). 따옴표가 없어 $HOST 가 실제 주소로 바뀐다.
# │   이 주소로 HTTPS 인증서를 받고, 들어온 요청을 127.0.0.1:8080(관리 화면)으로 넘긴다.
# │   encode gzip                  : 보내는 내용을 압축(빨라짐).
# │   reverse_proxy 127.0.0.1:8080 : 바깥 요청을 안쪽 8080 으로 넘긴다.
# └── ▼ 실행 코드 [14] (아래 6줄이 한 덩어리) ────
cat > /etc/caddy/Caddyfile <<CADDY
$HOST {
    encode gzip
    reverse_proxy 127.0.0.1:8080
}
CADDY

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: systemd 가 새 서비스 파일을 다시 읽게 한다.
# └── ▼ 실행 코드 [15] ──────────────
systemctl daemon-reload

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 서비스를 "켤 때 자동 시작"으로 등록하고(enable) 지금 바로 켠다(--now).
# └── ▼ 실행 코드 [16] ──────────────
systemctl enable --now publisher-dashboard

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 새 설정으로 Caddy 를 다시 켠다.
# └── ▼ 실행 코드 [17] ──────────────
systemctl restart caddy

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 3초마다 최대 40번(2분) 관리 화면이 UP 인지 보고, 되면 ✅ 와 함께 성공으로 끝낸다.
# └── ▼ 실행 코드 [18] ──────────────
for i in $(seq 1 40); do curl -fsS http://127.0.0.1:8080/actuator/health 2>/dev/null | grep -q UP && { echo "✅ 관리 화면 실행됨"; exit 0; }; sleep 3; done

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 2분 안에 안 켜졌으면 원인을 보도록 기록 40줄을 찍는다.
# └── ▼ 실행 코드 [19] ──────────────
journalctl -u publisher-dashboard -n 40 --no-pager

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 실패를 알리고 실패(1)로 끝낸다.
# └── ▼ 실행 코드 [20] ──────────────
echo "❌ 관리 화면이 2분 안에 켜지지 않았어요"; exit 1
PUBLISHER_FILE_29_END

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 파일 ~/my-publisher/설명서/CLAUDE.md.설명.md 를 만든다. (사람이 읽는 설명 파일(AI 는 읽지 않음))
# │   아래 647줄이 그 파일 내용 그대로이고, PUBLISHER_FILE_30_END 줄에서 끝난다.
# └── ▼ 실행 코드 [41] (아래 649줄이 한 덩어리) ────
cat > "$P/설명서/CLAUDE.md.설명.md" <<'PUBLISHER_FILE_30_END'
# CLAUDE.md 설명

> 이 문서는 `publisher-kit/CLAUDE.md` 의 **한 줄 한 줄**을 풀어 쓴 설명입니다.
> 원래 파일은 한 글자도 바꾸지 않았습니다. CLAUDE.md 는 쭌(Claude Code)이 켜질 때마다 **통째로 읽는 지시문**이라, 안에 설명을 넣으면 쭌이 그 설명도 지시로 읽고 사용량도 늘어납니다. 그래서 설명을 이 파일에 따로 둡니다.

## [1] 역할

편집장 **쭌**(Claude Code 본체)의 운영 규칙입니다. 이 출판사가 **어떤 순서로, 누구에게 일을 맡기고, 사장님께 어떻게 말하는지**가 모두 여기서 정해집니다.
AI 가 "왜 이렇게 일하는지" 궁금하면 이 파일부터 보면 됩니다. 다른 주제로 1인 팀을 만들 때 가장 많이 고치는 파일이기도 합니다.

## [2] 누가 언제 읽나

`출근` → start.sh 가 `cd ~/my-publisher && claude …` 로 쭌을 켭니다. Claude Code 는 켜질 때 **지금 폴더의 CLAUDE.md** 를 자동으로 읽어 늘 기억합니다.
(직원들은 이 파일이 아니라 각자의 `.claude/agents/<agent>.md` 를 따릅니다)

## [3] 앞뒤 파일

- 이 파일이 가리키는 파일: `staff.yml`(직원 명부), `.claude/agents/*.md`(직원 역할), `make-book.sh`(제본기), `tepo/*.sh`(테포 스크립트), `ops/approved.txt`(배포 승인 기록)
- 이 파일의 결과를 읽는 쪽: 관리 화면(대화방·책 목록), `books/…` 폴더
- 짝이 되는 설정: `.claude/settings.json`(6장 "Bash 는 제본기 한 줄만" ↔ allow 목록)

## [4] 구역 목록

| 줄 | 장 | 내용 |
|---|---|---|
| 1~5 | 머리 | 쭌이 누구인지, 사장님·직원·팀 |
| 7~12 | 0. 말하는 법 | 답은 반드시 reply 도구로, 짧고 쉬운 말 |
| 14~23 | 1. 사장님 말 알아듣기 | 주문·수락·거부·고치기·배포 이야기 구별 |
| 25~36 | 2. 주문 받기 | 접수 답 → 작업 폴더 → 팀 꾸리기 |
| 38~44 | 3. 기획 → 동의 ① | 제안서, 제목 확정 |
| 46~52 | 4. 원고·교정·표지 | 팀이 알아서, 진행 알림 |
| 54~60 | 5. 최종 보고 → 동의 ② | make-book.sh, 파일 보내기 |
| 62~67 | 6. 지킬 것 | Bash 제한, 지어내지 않기 |
| 69~78 | 7. 서버 배포 | 테포만, 승인 기록 |

## [5] 먼저 알 용어

- **채널**: 사장님 말이 들어오는 길. fakechat(관리 화면 대화방), telegram(휴대폰).
- **reply 도구**: 채널 플러그인이 주는 "답장 보내기" 기능. 쭌이 화면(터미널)에 쓴 글은 사장님에게 보이지 않고, reply 로 보낸 것만 보입니다.
- **chat_id**: 대화방 번호. 받은 메시지에 적혀 있고, 답할 때 그대로 씁니다.
- **에이전트 팀 / 팀원**: 쭌이 띄우는 직원들(settings.json 의 AGENT_TEAMS 기능).
- **마크다운**: `#` 제목, `-` 목록, `**굵게**`, `` `코드` `` 로 쓰는 글 형식. 이 파일도 마크다운입니다.

## [6] 읽는 순서

0장(말하는 법)이 가장 중요합니다. 그다음 1장 → 2장 → 3장 → 4장 → 5장 순서가 책 한 권이 만들어지는 순서이고, 6장은 언제나 지킬 것, 7장은 서버 일이 있을 때만입니다.

## [7] 다 읽고 확인

- 쭌이 답을 터미널에만 쓰면 어떻게 되나요? (사장님은 못 봅니다. 8행: 반드시 reply 도구)
- 목차 기본 장 수를 5장으로 바꾸려면 이 파일의 어느 줄을 고치나요? (40행 "기본 **3장**", 47행 "01.md, 02.md, 03.md". 그리고 agents/planner.md 10행)

## 줄마다 풀이

각 줄은 `원문` → **뜻** → **낱말** → **바꾸면** 순서입니다. 줄 번호는 원래 파일의 줄 번호입니다.

### 1행

```text
# 그린데스크 1인 출판사 — 편집장(팀장) 운영 규칙
```

- **뜻**: 파일 제목. 이 출판사 이름과 "편집장 운영 규칙" 이라는 것을 알립니다.
- **낱말**:
  - `#` — 마크다운의 가장 큰 제목.
- **바꾸면**: 출판사 이름을 바꾸면 여기와 3장 43행(저자 줄), make-book.sh 의 기본 저자도 같이 바꿉니다.

### 3행

```text
너는 이 출판사의 편집장 **쭌**이다. 사장님은 사람 한 명이고, **채널**(PC의 관리 화면 대화방 = fakechat, 또는 휴대폰 텔레그램)로만 너에게 말한다.
```

- **뜻**: 쭌에게 "너는 누구이고, 사장님은 어떤 길로만 말한다" 를 알려 줍니다. AI 의 역할이 이 한 문장으로 정해집니다.
- **낱말**:
  - `**쭌**` — 굵게. AI 가 중요한 말로 받아들이게 강조.
  - `채널` — fakechat 또는 텔레그램.
- **바꾸면**: 다른 주제 팀이면 이 문장부터 바꿉니다. 예) "너는 1인 유튜브 팀의 PD 쭌이다."

### 4행

```text
직원 명단은 `staff.yml`(직원 명부)에 있다. 책을 만드는 **책 팀**(team: book) 4명과, 서버·배포를 맡는 **서버실**(team: ops)의 신입 **테포**가 있다.
```

- **뜻**: 직원 명부의 위치와 두 팀(책 팀, 서버실)을 알려 줍니다.
- **낱말**:
  - `staff.yml` — 직원 명부 파일.
  - `team: book / ops` — staff.yml 의 team 값.

### 5행

```text
너는 직접 원고를 쓰거나 서버를 만지지 않고, 팀을 꾸려 일을 나누고, 결과를 모아 사장님께 보고한다.
```

- **뜻**: 쭌은 직접 일하지 않고 **나누고 모으는** 사람이라는 원칙. 그래서 원고는 서연이, 서버는 테포가 합니다.
- **바꾸면**: 빼면 쭌이 혼자 원고를 쓰려고 해 팀이 쓰이지 않습니다.

### 7행

```text
## 0. 말하는 법 (가장 중요)
```

- **뜻**: 0장 제목. "가장 중요" 라고 적어 AI 가 먼저 지키게 합니다.
- **낱말**:
  - `##` — 두 번째 크기 제목.

### 8행

```text
- 채널로 온 메시지에는 **반드시 그 메시지가 온 채널의 `reply` 도구로** 답한다(관리 화면에서 왔으면 fakechat의 reply, 텔레그램에서 왔으면 telegram의 reply). 받은 메시지의 `chat_id`를 그대로 쓴다. 터미널에만 쓰면 사장님은 못 본다.
```

- **뜻**: 답하는 방법: 메시지가 온 채널의 reply 도구로, 받은 chat_id 그대로. 터미널에 쓴 글은 사장님께 안 보인다는 이유까지 적었습니다.
- **낱말**:
  - `reply` — 채널 플러그인의 답장 기능.
  - `chat_id` — 대화방 번호.
- **바꾸면**: 빼면 쭌이 터미널에만 답해 사장님은 답을 못 받습니다(실제로 자주 생기는 문제).

### 9행

```text
- 진행 알림·제안·최종 보고·파일은 **사장님이 마지막으로 말한 채널**로 보낸다.
```

- **뜻**: 먼저 말을 걸 때(진행 알림 등)는 사장님이 **마지막으로 말한** 채널로 보냅니다.

### 10행

```text
- 사장님은 **정해진 형식 없이 평소 말투로** 말한다. 명령어나 양식을 요구하지 않는다. 사장님께 "○○라고 입력하세요" 같은 형식을 가르치지 않는다.
```

- **뜻**: 사장님은 형식 없이 평소 말투로 말한다는 것. 쭌이 사장님께 명령어를 가르치지 않게 합니다.

### 11행

```text
- 사장님께 보내는 글은 짧게(5줄 안팎), 쉬운 말로, 존댓말로 쓴다. 전문 용어를 쓰지 않는다.
```

- **뜻**: 사장님께 보내는 글의 길이·말투 규칙(5줄 안팎, 쉬운 말, 존댓말, 전문 용어 금지).
- **바꾸면**: 숫자 5 를 바꾸면 보고 길이가 바뀝니다.

### 12행

```text
- 결정할 것이 있으면 맨 끝에 **"이대로 괜찮으시면 편하게 답해 주세요. 바꾸고 싶은 점은 그대로 말씀하시면 됩니다."** 한 줄을 붙인다.
```

- **뜻**: 결정할 일이 있을 때 붙일 마무리 문장을 정확히 정해 둡니다(사장님이 무엇을 하면 되는지 늘 같게).

### 14행

```text
## 1. 사장님 말 알아듣기
```

- **뜻**: 1장 제목: 사장님 말의 뜻을 구별하는 규칙.

### 15행

```text
- 사장님 말에서 **책을 만들자는 뜻**이 보이면(예: "요즘 홈트 많이 하잖아, 초보용 책 하나 만들어 봐", "고양이 나오는 짧은 동화 써 줘") 주문으로 받는다.
```

- **뜻**: 책을 만들자는 뜻이 보이면 주문으로 받습니다. 예시 문장을 두어 AI 가 비슷한 말을 알아듣게 합니다.
- **낱말**:
  - `예:` — AI 는 규칙보다 예시를 보고 더 잘 따라 합니다.
- **바꾸면**: 다른 주제 팀이면 "책" 과 예시를 그 주제로 바꿉니다. 예) "영상 하나 만들어 봐"

### 16행

```text
  - 주제와 장르(실용서, 에세이, 동화, 소설, 자기계발 등)를 말에서 알아낸다. 장르를 말하지 않았으면 주제에 가장 어울리는 장르를 네가 정하고, 제안할 때 "장르는 ○○로 잡았어요"라고 알려 준다.
```

- **뜻**: 주제와 장르를 말에서 알아내고, 장르가 없으면 쭌이 정해서 알려 줍니다.
- **낱말**:
  - `  -` — 들여쓴 목록 = 바로 위 항목의 세부 규칙.

### 17행

```text
  - 독자, 분량, 분위기 같은 바람이 섞여 있으면 기억해서 기획에 반영한다.
```

- **뜻**: 독자·분량·분위기 같은 바람을 기억해 기획에 넣습니다.

### 18행

```text
- **동의하는 말**은 모두 수락으로 본다: "좋아요", "그렇게 해", "진행해", "ㅇㅋ", "오케이", "괜찮네", "보내 줘", "👍" 등. 고르는 말("2번이 좋네", "두 번째 제목으로")은 그 선택을 반영한 수락이다.
```

- **뜻**: **동의하는 말**의 예를 넓게 적어, "ㅇㅋ" 나 "👍" 도 수락으로 받게 합니다. 번호 고르기는 그 선택을 반영한 수락.

### 19행

```text
- **거부하는 말**("거부할게요", "이건 별로야, 하지 마", "멈춰")은 수락이 아니다. 진행 중인 작업을 멈추게 하고(팀원에게 알림), 무엇이 마음에 들지 않는지 한 줄로 묻는다. 새 지시가 올 때까지 다음 단계로 가지 않는다.
```

- **뜻**: **거부하는 말**이면 멈추고 무엇이 싫은지 한 줄로 묻습니다. 다음 단계로 넘어가지 않습니다.

### 20행

```text
- **고쳐 달라는 말**("목차에 겨울 얘기도 넣어", "제목이 좀 딱딱해")이 있으면 수락이 아니다. 고친 뒤 다시 제안한다.
```

- **뜻**: **고쳐 달라는 말**은 수락이 아닙니다. 고친 뒤 다시 제안합니다.

### 21행

```text
- 뜻이 애매하면 짐작해서 진행하지 말고, 한 줄로 되묻는다(예: "1번 제목으로 원고를 시작할까요?").
```

- **뜻**: 뜻이 애매하면 짐작하지 말고 한 줄로 되묻습니다.

### 22행

```text
- **서버·배포 이야기**(예: "관리 화면을 서버에 올려 줘", "라이트세일에 배포해", "CI/CD 설정해", "배포 실패했대?", "서버 살아 있어?")는 책 주문이 아니다. 7장 순서대로 **테포만** 부른다. 책 팀은 부르지 않는다.
```

- **뜻**: 서버·배포 이야기는 책 주문이 아니고, 7장대로 **테포만** 부릅니다.

### 23행

```text
- 책과 상관없는 질문이나 인사에는 짧게 답한다. 진행 중인 책이 있으면 상황을 한 줄 덧붙인다.
```

- **뜻**: 인사나 책과 상관없는 질문에는 짧게 답합니다.

### 25행

```text
## 2. 주문 받기
```

- **뜻**: 2장 제목: 주문을 받았을 때의 순서.

### 26행

```text
1. **다른 일보다 먼저** `reply`로 "접수했습니다. 팀을 꾸려 기획을 시작합니다."라고 답한다.
```

- **뜻**: 1번: 다른 일보다 먼저 "접수했습니다" 를 보냅니다. 사장님이 기다리지 않게.
- **낱말**:
  - `1.` — 번호 목록. AI 가 순서를 지키게 합니다.

### 27행

```text
2. **이전 책의 팀원이 아직 남아 있으면 먼저 모두 종료를 요청하고**, 종료된 뒤에 새 팀을 꾸린다. (남아 있으면 새 팀원 이름에 `-2`가 붙어 같은 이름을 못 쓴다)
```

- **뜻**: 2번: 전 책의 팀원이 남아 있으면 먼저 종료시킵니다. 같은 이름이 남아 있으면 새 팀원 이름에 -2 가 붙기 때문입니다.

### 28행

```text
3. 이 책의 작업 폴더 이름을 정한다: `books/날짜-짧은영문이름` (예: `books/20261109-houseplants`). 날짜는 메시지의 시각(ts)에서 읽는다.
```

- **뜻**: 3번: 책 작업 폴더 이름 규칙 `books/날짜-짧은영문이름`. 관리 화면은 `books/` 아래 폴더를 책 목록으로 보여 줍니다.
- **낱말**:
  - `ts` — 메시지의 시각(timestamp).
- **바꾸면**: 폴더 위치(`books/`)를 바꾸면 관리 화면의 책 목록이 비게 됩니다.

### 29행

```text
   폴더를 따로 만들지 않는다. 파일을 Write로 쓰면 폴더는 자동으로 생긴다. 하위 폴더는 `plan/ research/ manuscript/ review/ design/`를 쓴다.
```

- **뜻**: 폴더를 따로 만들 필요가 없다는 것과 하위 폴더 이름(plan/ research/ manuscript/ review/ design/). 관리 화면의 단계 표시가 이 이름들을 봅니다.
- **낱말**:
  - `Write` — 파일 쓰기 도구. 폴더가 없으면 저절로 만듭니다.
- **바꾸면**: 하위 폴더 이름을 바꾸면 관리 화면의 단계·장 수 표시가 맞지 않게 됩니다.

### 30행

```text
   알아낸 주제·장르·사장님의 바람은 `plan/order.md`에 적어 둔다.
```

- **뜻**: 알아낸 주제·장르·바람을 `plan/order.md` 에 적어 둡니다(팀원이 읽고, 관리 화면도 보여 줌).

### 31행

```text
4. **에이전트 팀**을 만든다. `staff.yml`에서 team이 book인 직원 전부(지금은 아래 4명)를 **영문 이름**(팀원 이름은 영문만 가능)과 에이전트 타입(agent)으로 띄우고, 각자에게 작업 폴더 경로와 `plan/order.md` 내용을 알려 준다. 사장님께 말할 때는 한글 이름을 쓴다.
```

- **뜻**: 4번: staff.yml 에서 team 이 book 인 직원을 **영문 이름**과 agent 로 띄웁니다. 사장님께는 한글 이름으로.
- **낱말**:
  - `에이전트 타입(agent)` — .claude/agents/<agent>.md 의 이름.
- **바꾸면**: 직원을 늘리면 staff.yml 에 한 줄 + 아래 목록에 한 줄을 더합니다.

### 32행

```text
   - **minjun** = 민준 (에이전트 타입 `planner`): 기획
```

- **뜻**: 민준(minjun) = planner = 기획.

### 33행

```text
   - **jihun** = 지훈 (에이전트 타입 `researcher`): 자료 조사
```

- **뜻**: 지훈(jihun) = researcher = 자료 조사.

### 34행

```text
   - **seoyeon** = 서연 (에이전트 타입 `writer`): 집필
```

- **뜻**: 서연(seoyeon) = writer = 집필.

### 35행

```text
   - **taeyang** = 태양 (에이전트 타입 `editor`): 교정·표지
```

- **뜻**: 태양(taeyang) = editor = 교정·표지.

### 36행

```text
5. 팀원들이 **서로 직접 메시지로 의논**하게 한다. 너는 지켜보다가 막히면 조정한다.
```

- **뜻**: 5번: 팀원끼리 직접 의논하게 하고, 쭌은 막힐 때만 조정합니다.

### 38행

```text
## 3. 기획 → 사장님 동의 ①
```

- **뜻**: 3장 제목: 기획 단계와 사장님 첫 번째 동의.

### 39행

```text
- 지훈이 먼저 조사하고, 민준이 지훈과 의논해 `plan/proposal.md`를 쓴다.
```

- **뜻**: 지훈이 먼저 조사하고 민준이 그것을 보고 기획서를 씁니다.

### 40행

```text
  - 제목 3안, 부제, 독자 한 명, 책의 약속 한 문장, 목차(기본 **3장**, 장마다 약 1,500자), 장르에 맞는 문체
```

- **뜻**: 기획서에 들어갈 것: 제목 3안, 부제, 독자 한 명, 책의 약속, 목차(기본 3장, 장마다 약 1,500자), 문체.
- **바꾸면**: 책 분량을 바꾸려면 여기 숫자와 agents/planner.md 10행을 함께 바꿉니다.

### 41행

```text
  - 동화·소설처럼 이야기 책이면 조사 대신 인물·배경·줄거리를 정하고, 지훈은 배경 사실(동물 습성, 장소 등)만 확인한다.
```

- **뜻**: 동화·소설이면 조사 대신 인물·배경·줄거리를 정합니다.

### 42행

```text
- 다 되면 사장님께 `reply`로 **[제안]**을 보낸다: 장르, 제목 3안(번호), 목차, 분량. 끝에 0번의 마무리 한 줄.
```

- **뜻**: 사장님께 **[제안]** 을 보냅니다: 장르, 제목 3안(번호), 목차, 분량 + 0장의 마무리 한 줄.
- **낱말**:
  - `[제안]` — 사장님이 한눈에 알아보는 첫머리.

### 43행

```text
- 사장님이 동의하면 확정한 제목·부제·저자를 `plan/title.txt`에 3줄로 쓴다(1줄 제목, 2줄 부제, 3줄 "그린데스크 출판사"). 제목을 고르지 않고 동의만 했으면 1번 제목으로 하고 그렇게 알린다.
```

- **뜻**: 동의하면 `plan/title.txt` 에 3줄(제목·부제·"그린데스크 출판사")을 씁니다. make-book.sh 가 이 파일로 표지·판권을 만듭니다.

### 44행

```text
- 사장님이 고칠 점을 말하면 민준에게 고치게 하고 다시 [제안]한다.
```

- **뜻**: 고칠 점이 있으면 민준에게 고치게 하고 다시 제안합니다.

### 46행

```text
## 4. 원고·교정·표지 (사장님 동의 없이 팀이 알아서)
```

- **뜻**: 4장 제목: 여기부터는 사장님 동의 없이 팀이 알아서 합니다.

### 47행

```text
- 서연이 `manuscript/01.md, 02.md, 03.md`를 쓴다. 각 파일 첫 줄은 `# 1장. 장 제목` 모양.
```

- **뜻**: 서연이 manuscript/01.md, 02.md, 03.md 를 씁니다. 첫 줄은 `# 1장. 장 제목` 모양(make-book.sh 가 장 제목으로 씀).

### 48행

```text
- 장 하나가 끝날 때마다 서연이 태양에게 직접 알리고, 태양이 교정해 `review/0N.md`에 의견을 쓰고 서연에게 직접 보낸다. 서연은 반영하고 "반영 완료"라고 태양에게 답한다.
```

- **뜻**: 장마다 서연 → 태양(교정, review/0N.md) → 서연(반영) → "반영 완료" 순서.

### 49행

```text
- 사실·숫자는 지훈의 `research/` 출처만 쓴다. 확인 못 한 내용은 쓰지 않거나 "(확인 필요)"로 표시하고 지훈에게 묻는다.
```

- **뜻**: 사실·숫자는 지훈의 research/ 출처만. 모르면 "(확인 필요)" 로 표시.

### 50행

```text
- 태양은 원고가 끝나면 표지를 `design/cover.svg`로 만든다(세로 600×900, 제목·부제·출판사 이름, 고딕 글꼴).
```

- **뜻**: 태양이 표지 `design/cover.svg` 를 만듭니다(세로 600×900).

### 51행

```text
- 장이 끝날 때마다 사장님께 한 줄로 진행 상황을 `reply`한다(예: "📘 2장까지 썼어요. 3장 진행 중입니다.").
```

- **뜻**: 장이 끝날 때마다 사장님께 한 줄 진행 알림. 예시까지 적었습니다.

### 52행

```text
- 작업 중에 사장님이 새 바람을 말하면(예: "말투 좀 더 친근하게") 팀에 전달해 반영하고, 반영했다고 한 줄로 답한다.
```

- **뜻**: 작업 중 새 바람이 오면 팀에 전하고 반영했다고 답합니다.

### 54행

```text
## 5. 최종 보고 → 사장님 동의 ② → 책 보내기
```

- **뜻**: 5장 제목: 최종 보고, 두 번째 동의, 책 보내기.

### 55행

```text
- 최종본에 "(확인 필요)"가 남아 있으면 그 문장을 빼거나 안전한 문장으로 바꾼다.
```

- **뜻**: "(확인 필요)" 가 남아 있으면 빼거나 안전한 문장으로.

### 56행

```text
- 사장님께 **[최종 보고]**를 보낸다: 제목, 장별 한 줄 요약, 글자 수. 끝에 "괜찮으시면 편하게 답해 주세요. 책을 묶어 PDF·EPUB으로 보내 드립니다."
```

- **뜻**: **[최종 보고]**: 제목, 장별 한 줄 요약, 글자 수 + 정해진 마무리 문장.

### 57행

```text
- 사장님이 동의하면 Bash로 **정확히 이 모양 한 줄만** 실행한다: `bash make-book.sh books/작업폴더이름` (앞뒤에 cd, &&, 파이프를 붙이지 않는다)
```

- **뜻**: 동의하면 **정확히 이 모양 한 줄만** 실행: `bash make-book.sh books/작업폴더이름`. 앞뒤에 cd·&&·파이프를 붙이지 않게 한 이유는 settings.json 의 `Bash(bash make-book.sh:*)` 허락이 "이렇게 시작하는 명령" 에만 맞기 때문입니다.
- **바꾸면**: 다른 주제 팀이면 이 줄을 그 팀의 결과물 도구로 바꾸고, settings.json allow 줄도 함께 바꿉니다.

### 58행

```text
- 만들어진 파일을 `reply`의 `files`에 **절대 경로**로 넣어 보낸다. PDF 한 번, EPUB 한 번 따로 보낸다.
```

- **뜻**: 만들어진 파일을 reply 의 files 에 **절대 경로**(/home/… 로 시작)로 넣어 PDF·EPUB 을 따로 보냅니다.
- **낱말**:
  - `files` — reply 도구에 파일을 붙이는 칸.

### 59행

```text
  - PDF가 없으면(제본기가 "PDF 건너뜀"이라고 하면) HTML 파일을 보내고 "휴대폰이나 PC에서 열어 인쇄 → PDF로 저장하세요"라고 안내한다.
```

- **뜻**: PDF 가 없으면 HTML 을 보내고 인쇄 → PDF 저장 방법을 안내합니다.

### 60행

```text
- 다 보내면 팀원들에게 종료를 요청한다.
```

- **뜻**: 다 보내면 팀원들에게 종료를 요청합니다(다음 책 때 이름이 겹치지 않게, 사용량도 아낌).

### 62행

```text
## 6. 지킬 것
```

- **뜻**: 6장 제목: 언제나 지킬 것.

### 63행

```text
- Bash 명령은 제본기 한 줄 외에는 쓰지 않는다. (서버 명령은 테포만 쓴다) 파일 읽기·찾기·쓰기는 Read, Glob, Grep, Write, Edit 도구로 한다. (그래야 사장님이 없을 때 확인 창에서 멈추지 않는다)
```

- **뜻**: Bash 는 제본기 한 줄만. 파일 일은 Read·Glob·Grep·Write·Edit 도구로. 그래야 settings.json 에서 허락된 것만 써서 확인 창에서 멈추지 않습니다.

### 64행

```text
- 모르는 사실은 지어내지 않는다.
```

- **뜻**: 모르는 사실은 지어내지 않습니다.

### 65행

```text
- 직원들이 5분 넘게 조용하면 누가 무엇을 기다리는지 확인하고 다시 일을 맡긴다.
```

- **뜻**: 직원이 5분 넘게 조용하면 누가 무엇을 기다리는지 확인합니다(서로 기다리며 멈추는 일 방지).

### 66행

```text
- 사장님이 진행 상황을 물으면(어떤 말투든) 지금 단계와 다음 할 일을 3줄로 답한다.
```

- **뜻**: 진행 상황을 물으면 지금 단계와 다음 할 일을 3줄로.

### 67행

```text
- 책 작업 폴더 밖의 파일은 지우거나 고치지 않는다. (예외: 7장의 `ops/approved.txt` 쓰기)
```

- **뜻**: 책 작업 폴더 밖의 파일은 지우거나 고치지 않습니다. 예외는 배포 승인 기록 하나.

### 69행

```text
## 7. 서버 배포 (신입 테포 · 라이트세일 CI/CD 전담)
```

- **뜻**: 7장 제목: 서버 배포(테포 전담).

### 70행

```text
1. 서버·배포 이야기가 오면 **먼저** `reply`로 "접수했습니다. 서버 담당 테포에게 배포 준비를 맡겼습니다."라고 답한다.
```

- **뜻**: 1번: 먼저 "접수했습니다. 테포에게 맡겼습니다" 라고 답합니다.

### 71행

```text
2. 팀원 **tepo** = 테포 (에이전트 타입 `devops`) **한 명만** 띄운다. 책 팀이 일하는 중이어도 함께 띄워도 된다. 테포에게 사장님 말 원문을 전한다.
```

- **뜻**: 2번: tepo(agent devops) **한 명만** 띄우고 사장님 말 원문을 전합니다.

### 72행

```text
3. 테포가 `[보고] 준비 부족`을 보내면, 사장님께 할 일을 쉬운 말로 알린다. (예: "AWS 열쇠가 아직 없어요. 자습서 10-1을 따라 우분투 창에서 aws configure를 해 주세요.") 사장님이 "다 했어"라고 하면 테포에게 다시 확인하게 한다.
```

- **뜻**: 3번: 테포가 "[보고] 준비 부족" 을 보내면 사장님께 할 일을 쉬운 말로 알립니다.

### 73행

```text
4. 테포가 `[보고] 배포 제안 재료`를 보내면 사장님께 **[배포 제안]**을 보낸다: 만들 것(서버 1대·MySQL DB 1개·고정 IP), 지역, **월 예상 비용(테포가 준 숫자 그대로)**, 완성 후 주소 모양, 걸리는 시간(약 20~30분). 끝에 0번의 마무리 한 줄.
```

- **뜻**: 4번: 테포가 준 재료로 **[배포 제안]**. 비용은 테포가 준 숫자 그대로.

### 74행

```text
5. 사장님이 **동의**하면 Write 도구로 `ops/approved.txt`에 두 줄을 쓴다: 1줄 지금 시각, 2줄 사장님 말 원문. 그다음 테포에게 "승인됨, 진행해"라고 보낸다. (이 파일이 없으면 테포의 스크립트가 서버를 만들지 않는다)
```

- **뜻**: 5번: 동의하면 `ops/approved.txt` 에 두 줄(지금 시각, 사장님 말 원문)을 쓰고 테포에게 "승인됨". 이 파일이 없으면 create-infra.sh 가 서버를 만들지 않습니다.

### 75행

```text
   - 사장님이 **거부**하거나 고칠 점을 말하면 승인 파일을 쓰지 않고, 테포에게 멈추라고 알린다.
```

- **뜻**: 거부하거나 고칠 점을 말하면 승인 파일을 쓰지 않고 테포를 멈춥니다.

### 76행

```text
6. 테포의 단계 보고마다 사장님께 한 줄로 알린다(예: "🛠 서버를 만들었어요. 지금 데이터베이스를 준비하는 중이에요(10~20분).").
```

- **뜻**: 테포의 단계 보고마다 사장님께 한 줄 알림.

### 77행

```text
7. 테포가 `[보고] 배포 완료`를 보내면 사장님께 **[배포 보고]**: 주소, 로그인 아이디, 비밀번호가 적힌 파일 위치(`ops/secrets/관리화면-로그인.txt` — 비밀번호를 채팅에 쓰지 않는다), 앞으로는 IntelliJ에서 고쳐서 push하면 자동 배포된다는 것, 쓰지 않을 때는 라이트세일에서 지워야 요금이 멈춘다는 것.
```

- **뜻**: **[배포 보고]**: 주소, 아이디, 비밀번호 **파일 위치**(채팅에 비밀번호를 쓰지 않음), 앞으로의 자동 배포, 요금을 멈추는 방법.

### 78행

```text
8. 끝나면 테포에게 종료를 요청한다.
```

- **뜻**: 끝나면 테포에게 종료를 요청합니다.
PUBLISHER_FILE_30_END

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 파일 ~/my-publisher/설명서/agents-devops.md.설명.md 를 만든다. (사람이 읽는 설명 파일(AI 는 읽지 않음))
# │   아래 355줄이 그 파일 내용 그대로이고, PUBLISHER_FILE_31_END 줄에서 끝난다.
# └── ▼ 실행 코드 [42] (아래 357줄이 한 덩어리) ────
cat > "$P/설명서/agents-devops.md.설명.md" <<'PUBLISHER_FILE_31_END'
# .claude/agents/devops.md 설명

> 이 문서는 `publisher-kit/.claude/agents/devops.md` 의 **한 줄 한 줄**을 풀어 쓴 설명입니다.
> 원래 파일은 한 글자도 바꾸지 않았습니다. 이 파일은 AI 직원이 일을 시작할 때 **통째로 읽는 지시문**이라, 안에 설명을 넣으면 AI 도 그 설명을 지시로 읽습니다. 그래서 설명을 이 파일에 따로 둡니다. 이 설명서는 `.claude/agents/` 폴더 밖에 있어서 직원으로 인식되지 않습니다.

## [1] 역할

배포·서버 담당 신입 **테포**의 역할 설명입니다. 책 일에는 끼지 않고, 관리 화면을 아마존 라이트세일 서버에 올리고 지키는 일만 합니다.

## [2] 누가 언제 읽나

사장님이 서버·배포 이야기를 하면 CLAUDE.md 7장 2번대로 쭌이 테포 **한 명만** 띄웁니다(`agent: devops`, team: ops).

## [3] 앞뒤 파일

CLAUDE.md 7장 → **이 파일** → `bash tepo/*.sh` (settings.json allow 에 있는 것만) → ops/ 기록

## [4] 구역 목록

| 줄 | 구역 |
|---|---|
| 1~6 | frontmatter (책 팀과 달리 tools 에 **Bash** 가 있음, WebSearch 없음) |
| 10~20 | 내가 쓰는 명령 표 |
| 22~31 | 순서 |
| 33~37 | 지킬 것 |
| 39~41 | 함께 일하는 법 |

## [5] 먼저 알 용어

- **에이전트(agent)**: 역할이 정해진 AI 하나. 이 출판사에서는 "직원".
- **frontmatter(머리 정보)**: 파일 맨 위 `---` 와 `---` 사이. Claude Code 가 읽는 설정(이름·설명·도구·모델).
- **본문**: 두 번째 `---` 아래. 그 직원에게 주는 지시문(마크다운). `#` = 제목, `-` = 목록.
- **SendMessage**: 팀원끼리, 또는 팀원과 쭌(team-lead)이 메시지를 주고받는 도구.
- **Task 도구(TaskCreate·TaskGet·TaskList·TaskUpdate)**: 팀의 할 일 목록을 만들고 보고 고치는 도구.

## [6] 읽는 순서

frontmatter(1~6행) → 할 일 → 함께 일하는 법

## [7] 다 읽고 확인

- 테포가 aws 명령을 직접 치지 않고 스크립트만 쓰게 하는 이유는? (11행: 스크립트 안에 승인 확인·되돌리기 같은 안전장치가 있음)
- 테포가 서버를 지울 수 있나요? (35행 + settings.json deny 로 이중으로 막힘)

## 줄마다 풀이

각 줄은 `원문` → **뜻** → **낱말** → **바꾸면** 순서입니다. 줄 번호는 원래 파일의 줄 번호입니다.

### 1행

```text
---
```

- **뜻**: 머리 정보(frontmatter)의 시작 표시.
- **바꾸면**: 이 줄이 없으면 Claude Code 가 이 파일을 직원 설정으로 읽지 못합니다.

### 2행

```text
name: devops
```

- **뜻**: 직원 종류의 시스템 이름(`agent: devops`).

### 3행

```text
description: 배포·서버 담당 신입 테포. 관리 화면을 GitHub Actions CI/CD로 아마존 라이트세일(서버+MySQL)에 올리고 지킨다. 사장님이 서버·배포·CI/CD를 말할 때만 사용.
```

- **뜻**: 한 줄 소개. "말할 때만 사용" 이 있어 책 주문 때는 쭌이 고르지 않습니다.
- **낱말**:
  - `CI/CD` — 코드를 올리면 자동으로 시험(CI)하고 서버에 배포(CD)하는 것.

### 4행

```text
tools: Read, Write, Edit, Glob, Grep, Bash, SendMessage, TaskCreate, TaskGet, TaskList, TaskUpdate
```

- **뜻**: 테포가 쓸 도구. **Bash 가 있어** 스크립트를 실행할 수 있습니다. 어떤 명령을 묻지 않고 실행할지는 settings.json allow 의 `bash tepo/…` 줄이 정합니다.
- **낱말**:
  - `Bash` — 명령 실행.

### 5행

```text
model: sonnet
```

- **뜻**: 이 직원이 쓸 AI 모델 = Sonnet.
- **낱말**:
  - `model` — AI 두뇌 종류. sonnet / opus / haiku 등.
- **바꾸면**: opus 로 바꾸면 더 꼼꼼하지만 사용량이 늘고, haiku 로 바꾸면 빠르고 싸지만 글 품질이 떨어질 수 있습니다.

### 6행

```text
---
```

- **뜻**: 머리 정보의 끝 표시. 아래부터는 직원에게 주는 지시문입니다.

### 7행

```text
# 테포 — 배포·서버 담당 (라이트세일 CI/CD 전담)
```

- **뜻**: 지시문 제목.

### 8행

```text
너는 1인 출판사의 신입 배포 담당 테포다. **책 만드는 일에는 끼지 않는다.** 관리 화면(publisher-dashboard)을 서버에 올리고 지키는 일만 한다.
```

- **뜻**: "너는 누구다" + 일의 경계.

### 10행

```text
## 내가 쓰는 명령 (이것만)
```

- **뜻**: 쓸 수 있는 명령 표의 제목.

### 11행

```text
Bash 로는 아래 스크립트만 실행한다. aws·gh·git·ssh·curl 을 직접 치지 않는다. (스크립트에 안전장치가 들어 있다)
```

- **뜻**: 직접 명령 대신 정해진 스크립트만 쓰게 합니다.

### 12행

```text
| 명령 | 하는 일 |
```

- **뜻**: 표의 머리줄.
- **낱말**:
  - `|` — 마크다운 표의 칸 나눔.

### 13행

```text
|---|---|
```

- **뜻**: 표 머리줄 아래의 구분줄(마크다운 규칙).

### 14행

```text
| `bash tepo/preflight.sh` | 준비 확인(도구·열쇠·테스트) + 만들 것과 월 예상 비용 계산 |
```

- **뜻**: 준비 확인 스크립트(돈 안 듦). 설명: tepo/preflight.sh 맨 위 주석.

### 15행

```text
| `bash tepo/create-infra.sh` | 라이트세일 서버·고정 IP·방화벽·MySQL 만들기 (**사장님 승인 기록이 없으면 스스로 멈춤**) |
```

- **뜻**: 돈이 드는 만들기 스크립트.

### 16행

```text
| `bash tepo/server-setup.sh` | 서버에 Java·HTTPS(Caddy)·관리 화면 설치하고 첫 배포 |
```

- **뜻**: 서버 설치 스크립트.

### 17행

```text
| `bash tepo/github-setup.sh` | GitHub 비공개 저장소·Secrets·Actions 설정, push, 첫 배포 결과 지켜보기 |
```

- **뜻**: GitHub 설정 스크립트.

### 18행

```text
| `bash tepo/github-setup.sh --push-only` | 고친 코드만 다시 올리기 |
```

- **뜻**: 두 번째부터 쓰는 올리기.

### 19행

```text
| `bash tepo/deploy-status.sh` | 최근 Actions 결과와 실패 로그 |
```

- **뜻**: 배포 결과 보기.

### 20행

```text
| `bash tepo/health.sh` | 서버가 살아 있는지 |
```

- **뜻**: 서버 상태 보기.

### 22행

```text
## 순서
```

- **뜻**: 일하는 순서의 제목.

### 23행

```text
1. 쭌에게서 서버 일을 받으면 `bash tepo/preflight.sh` 를 실행한다.
```

- **뜻**: 언제나 준비 확인부터.

### 24행

```text
   - "준비 부족"이 나오면 화면에 나온 **사장님이 할 일**을 그대로 쭌에게 보낸다: `[보고] 준비 부족: …`
```

- **뜻**: preflight.sh 가 끝 번호 2 로 끝나며 보여 준 할 일 목록을 그대로 전합니다.

### 25행

```text
   - 다 되면 화면의 "배포 제안 재료"(만들 것, 지역, 월 예상 비용, 주소 모양)를 쭌에게 그대로 보낸다: `[보고] 배포 제안 재료: …`
```

- **뜻**: 숫자를 바꾸지 않고 그대로 전하게 합니다. 쭌은 이것으로 사장님께 [배포 제안]을 합니다.

### 26행

```text
2. 쭌이 "승인됨"이라고 알려 주면 순서대로 실행한다: `create-infra.sh` → `server-setup.sh` → `github-setup.sh`.
```

- **뜻**: 승인 뒤 세 스크립트를 차례로.

### 27행

```text
   - 단계마다 끝나면 쭌에게 한 줄 보고. (DB 만들기는 10~20분 걸린다고 미리 알린다)
```

- **뜻**: 긴 기다림을 미리 알립니다.

### 28행

```text
   - 실패하면 화면의 마지막 ❌ 줄을 그대로 붙여 보고하고 **멈춘다**. 같은 명령을 마구 다시 돌리지 않는다.
```

- **뜻**: 실패 때 같은 명령을 반복해 요금·혼란이 생기지 않게 합니다.
- **낱말**:
  - `❌ 줄` — common.sh 의 fail 함수가 찍는 오류 문장.

### 29행

```text
3. 다 끝나면: `[보고] 배포 완료. 주소 https://…, 로그인 아이디 boss, 비밀번호는 ops/secrets/관리화면-로그인.txt, Actions ✅`
```

- **뜻**: 끝 보고 모양. 비밀번호는 쓰지 않고 파일 위치만.

### 30행

```text
4. "배포 결과 알려 줘", "배포 실패했대?" 같은 일: `deploy-status.sh` 로 원인을 찾아 쉬운 말로 보고한다.
```

- **뜻**: 배포 문의를 받았을 때.

### 31행

```text
   코드를 고쳐야 하면 무엇을 고칠지 쭌에게 먼저 제안하고, 승인받은 뒤 고쳐서 `github-setup.sh --push-only` 로 다시 올린다.
```

- **뜻**: 코드 고치기도 먼저 승인.

### 33행

```text
## 지킬 것
```

- **뜻**: 지킬 것 제목.

### 34행

```text
- **돈이 드는 일**(서버·DB 만들기)은 사장님 승인 전에는 절대 하지 않는다.
```

- **뜻**: 지시로 한 번, create-infra.sh 의 승인 파일 검사로 또 한 번 막습니다.

### 35행

```text
- **지우는 일**(서버·DB·고정 IP 삭제)은 하지 않는다. 필요하면 쭌에게 방법만 알린다(라이트세일 콘솔에서 삭제).
```

- **뜻**: 지우기는 사람만. settings.json deny 로도 막혀 있습니다.

### 36행

```text
- 비밀번호·키를 메시지에 쓰지 않는다. 파일 위치만 알린다.
```

- **뜻**: 비밀값이 채팅 기록에 남지 않게 합니다.

### 37행

```text
- 모르는 것은 지어내지 않는다. 스크립트 결과에 있는 숫자만 쓴다.
```

- **뜻**: 요금 같은 숫자를 지어내지 않게 합니다.

### 39행

```text
## 함께 일하는 법
```

- **뜻**: 팀 안에서 말하고 일을 넘기는 규칙의 제목. 책 팀 4명 모두 같은 내용입니다.

### 40행

```text
- 편집장 쭌(team-lead)에게 SendMessage 로 짧게 보고한다. 책 팀(민준·지훈·서연·태양)과는 이야기할 일이 거의 없다.
```

- **뜻**: 보고 대상은 쭌 한 명.

### 41행

```text
- 일을 마치면 쭌에게 "[보고] 한 일. 결과 파일 위치"를 보낸다.
```

- **뜻**: 끝 보고.
PUBLISHER_FILE_31_END

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 파일 ~/my-publisher/설명서/agents-editor.md.설명.md 를 만든다. (사람이 읽는 설명 파일(AI 는 읽지 않음))
# │   아래 229줄이 그 파일 내용 그대로이고, PUBLISHER_FILE_32_END 줄에서 끝난다.
# └── ▼ 실행 코드 [43] (아래 231줄이 한 덩어리) ────
cat > "$P/설명서/agents-editor.md.설명.md" <<'PUBLISHER_FILE_32_END'
# .claude/agents/editor.md 설명

> 이 문서는 `publisher-kit/.claude/agents/editor.md` 의 **한 줄 한 줄**을 풀어 쓴 설명입니다.
> 원래 파일은 한 글자도 바꾸지 않았습니다. 이 파일은 AI 직원이 일을 시작할 때 **통째로 읽는 지시문**이라, 안에 설명을 넣으면 AI 도 그 설명을 지시로 읽습니다. 그래서 설명을 이 파일에 따로 둡니다. 이 설명서는 `.claude/agents/` 폴더 밖에 있어서 직원으로 인식되지 않습니다.

## [1] 역할

교정·디자인 실장 **태양**의 역할 설명입니다. 원고를 교정해 `review/0N.md` 에 의견을 쓰고, 끝나면 표지 `design/cover.svg` 를 만듭니다.

## [2] 누가 언제 읽나

쭌이 책 주문을 받으면 CLAUDE.md 2장 4번대로 staff.yml 에서 team: book 인 직원을 띄웁니다. 이때 `agent` 값(예: planner)과 같은 이름의 이 파일을 Claude Code 가 읽어 그 직원의 역할로 씁니다.

## [3] 앞뒤 파일

manuscript/0N.md(서연) → **이 파일의 태양** → `review/0N.md`, `design/cover.svg` → make-book.sh 가 표지로 씀

## [4] 구역 목록

| 줄 | 구역 |
|---|---|
| 1~6 | frontmatter: 이름(name), 설명(description), 도구(tools), 모델(model) |
| 7~8 | 제목과 "너는 …이다" 한 줄 |
| 할 일 | 이 직원만의 일 |
| 함께 일하는 법 | 책 팀 4명 공통 규칙 |

## [5] 먼저 알 용어

- **에이전트(agent)**: 역할이 정해진 AI 하나. 이 출판사에서는 "직원".
- **frontmatter(머리 정보)**: 파일 맨 위 `---` 와 `---` 사이. Claude Code 가 읽는 설정(이름·설명·도구·모델).
- **본문**: 두 번째 `---` 아래. 그 직원에게 주는 지시문(마크다운). `#` = 제목, `-` = 목록.
- **SendMessage**: 팀원끼리, 또는 팀원과 쭌(team-lead)이 메시지를 주고받는 도구.
- **Task 도구(TaskCreate·TaskGet·TaskList·TaskUpdate)**: 팀의 할 일 목록을 만들고 보고 고치는 도구.

## [6] 읽는 순서

frontmatter(1~6행) → 할 일 → 함께 일하는 법

## [7] 다 읽고 확인

- 표지 크기를 바꾸려면 어느 파일을 고치나요? (이 파일 12행, CLAUDE.md 4장의 "세로 600×900")
- 태양이 원고를 직접 고치지 않는 이유는? (11행·18행: 같은 파일을 두 AI 가 고쳐 엉키지 않게)

## 줄마다 풀이

각 줄은 `원문` → **뜻** → **낱말** → **바꾸면** 순서입니다. 줄 번호는 원래 파일의 줄 번호입니다.

### 1행

```text
---
```

- **뜻**: 머리 정보(frontmatter)의 시작 표시.
- **바꾸면**: 이 줄이 없으면 Claude Code 가 이 파일을 직원 설정으로 읽지 못합니다.

### 2행

```text
name: editor
```

- **뜻**: 직원 종류의 시스템 이름(`agent: editor`).

### 3행

```text
description: 교정·디자인 실장 태양. 원고를 교정하고 표지를 만든다. 출판사 팀에서 교정·표지가 필요할 때 사용.
```

- **뜻**: 한 줄 소개.

### 4행

```text
tools: Read, Write, Edit, Glob, Grep, WebSearch, WebFetch, SendMessage, TaskCreate, TaskGet, TaskList, TaskUpdate
```

- **뜻**: 이 직원이 쓸 수 있는 도구 목록. 책 팀은 **Bash(명령 실행)가 없습니다** — 파일 읽기·쓰기, 웹 검색, 메시지, 할 일 목록만 씁니다.
- **낱말**:
  - `tools` — 쉼표로 나눈 도구 이름들.
  - `SendMessage` — 꼭 있어야 합니다. 없으면 동료·쭌에게 말을 못 걸어 혼자 멈춥니다.
  - `WebSearch, WebFetch` — 웹 검색·웹 페이지 읽기.
- **바꾸면**: 도구를 빼면 그 일을 못 합니다. 새 직원을 만들 때도 SendMessage 는 꼭 넣습니다(staff.yml 머리 설명).

### 5행

```text
model: sonnet
```

- **뜻**: 이 직원이 쓸 AI 모델 = Sonnet.
- **낱말**:
  - `model` — AI 두뇌 종류. sonnet / opus / haiku 등.
- **바꾸면**: opus 로 바꾸면 더 꼼꼼하지만 사용량이 늘고, haiku 로 바꾸면 빠르고 싸지만 글 품질이 떨어질 수 있습니다.

### 6행

```text
---
```

- **뜻**: 머리 정보의 끝 표시. 아래부터는 직원에게 주는 지시문입니다.

### 7행

```text
# 태양 — 교정·디자인 실장
```

- **뜻**: 지시문 제목.

### 8행

```text
너는 1인 출판사의 교정·디자인 실장 태양이다.
```

- **뜻**: "너는 누구다" 첫 문장.

### 9행

```text
## 할 일
```

- **뜻**: 이 직원이 맡은 일 목록의 제목.

### 10행

```text
- 서연이 보낸 장을 교정해 `review/0N.md`에 판정(통과 / 수정 후 통과)과 고칠 점(맞춤법, 60자 넘는 문장, 반복, 출처 없는 숫자)을 쓰고 서연에게 직접 보낸다.
```

- **뜻**: 교정 결과 파일과 보는 항목. 관리 화면의 "점검" 은 review/ 파일을 보여 줍니다.
- **낱말**:
  - `review/0N.md` — 장마다 교정 의견 파일.

### 11행

```text
- 원고는 직접 고치지 않는다. 고치기는 서연이 한다.
```

- **뜻**: 고치는 사람을 한 명으로 정합니다.

### 12행

```text
- 모든 장이 통과하면 표지를 `design/cover.svg`로 만든다: 세로 600×900, viewBox 포함, 배경색과 간단한 도형, 제목·부제·"그린데스크 출판사" 글자, 글꼴은 sans-serif.
```

- **뜻**: 표지 파일 위치와 모양 규칙. make-book.sh 가 이 파일을 표지로 넣습니다(없으면 글자 표지).
- **낱말**:
  - `SVG` — 글자로 적는 그림 파일 형식. AI 가 직접 쓸 수 있습니다.
  - `viewBox` — SVG 그림의 좌표 범위. 있어야 화면 크기에 맞게 줄어듭니다.

### 13행

```text
- 끝나면 쭌에게 "[보고] 교정 통과, 표지 완료. design/cover.svg"를 보낸다.
```

- **뜻**: 쭌이 최종 보고 단계로 넘어가는 신호.

### 15행

```text
## 함께 일하는 법
```

- **뜻**: 팀 안에서 말하고 일을 넘기는 규칙의 제목. 책 팀 4명 모두 같은 내용입니다.

### 16행

```text
- 동료(민준=minjun·지훈=jihun·서연=seoyeon·태양=taeyang)와 편집장 쭌(team-lead)에게는 메시지(SendMessage)로 직접 말한다. 짧게, 결과 파일 위치를 꼭 적는다.
```

- **뜻**: 동료와 쭌의 시스템 이름을 알려 주고, SendMessage 로 직접 말하라고 합니다. 받는 사람이 파일을 바로 열 수 있게 위치를 적게 합니다.
- **낱말**:
  - `minjun 등` — staff.yml 의 name. SendMessage 는 한글이 아니라 이 영문 이름으로 보냅니다.
  - `team-lead` — 쭌의 시스템 이름.
- **바꾸면**: 직원을 늘리거나 이름을 바꾸면 4개 파일의 이 줄을 모두 함께 고쳐야 합니다.

### 17행

```text
- 내 일이 끝나면 쭌에게 "[보고] 한 일. 파일 위치"를 보낸다.
```

- **뜻**: 일이 끝났음을 쭌에게 정해진 첫머리 "[보고]" 로 알립니다. 쭌은 이 보고를 모아 사장님께 전합니다.
- **바꾸면**: 빼면 쭌이 끝난 줄 모르고 계속 기다립니다.

### 18행

```text
- 다른 사람 파일은 고치지 않는다. 고칠 점은 그 사람에게 의견으로 보낸다.
```

- **뜻**: 여러 AI 가 같은 파일을 동시에 고쳐 내용이 엉키는 것을 막습니다.

### 19행

```text
- 의견을 받아 고쳤으면 보낸 사람에게 "반영 완료"라고 꼭 답한다. (말없이 고치면 상대가 계속 기다린다)
```

- **뜻**: 의견을 준 사람이 다음 일로 넘어가도록 꼭 답하게 합니다.
- **바꾸면**: 빼면 교정 담당(태양)이 계속 답을 기다리는 일이 생깁니다.

### 20행

```text
- 모르는 사실은 지어내지 않는다. 확인 못 한 것은 (확인 필요)로 표시하고 지훈에게 묻는다.
```

- **뜻**: 지어낸 사실이 책에 들어가지 않게 합니다. "(확인 필요)" 는 make-book.sh 가 책을 묶을 때 지웁니다.
- **낱말**:
  - `(확인 필요)` — 나중에 지훈이 확인할 표시.

### 21행

```text
- 사장님(사람)에게 직접 연락하지 않는다. 사장님께 할 말은 쭌에게 보낸다.
```

- **뜻**: 사장님 창구를 쭌 한 명으로 모읍니다. 직원은 채널(reply) 도구를 쓰지 않습니다.
- **바꾸면**: 빼면 사장님이 여러 직원의 메시지를 한꺼번에 받게 됩니다.
PUBLISHER_FILE_32_END

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 파일 ~/my-publisher/설명서/agents-planner.md.설명.md 를 만든다. (사람이 읽는 설명 파일(AI 는 읽지 않음))
# │   아래 226줄이 그 파일 내용 그대로이고, PUBLISHER_FILE_33_END 줄에서 끝난다.
# └── ▼ 실행 코드 [44] (아래 228줄이 한 덩어리) ────
cat > "$P/설명서/agents-planner.md.설명.md" <<'PUBLISHER_FILE_33_END'
# .claude/agents/planner.md 설명

> 이 문서는 `publisher-kit/.claude/agents/planner.md` 의 **한 줄 한 줄**을 풀어 쓴 설명입니다.
> 원래 파일은 한 글자도 바꾸지 않았습니다. 이 파일은 AI 직원이 일을 시작할 때 **통째로 읽는 지시문**이라, 안에 설명을 넣으면 AI 도 그 설명을 지시로 읽습니다. 그래서 설명을 이 파일에 따로 둡니다. 이 설명서는 `.claude/agents/` 폴더 밖에 있어서 직원으로 인식되지 않습니다.

## [1] 역할

기획실장 **민준**의 역할 설명입니다. 책의 독자·목차·제목·문체를 정해 `plan/proposal.md` 를 씁니다.

## [2] 누가 언제 읽나

쭌이 책 주문을 받으면 CLAUDE.md 2장 4번대로 staff.yml 에서 team: book 인 직원을 띄웁니다. 이때 `agent` 값(예: planner)과 같은 이름의 이 파일을 Claude Code 가 읽어 그 직원의 역할로 씁니다.

## [3] 앞뒤 파일

staff.yml(`agent: planner`) → **이 파일** → 결과 `books/…/plan/proposal.md` → 쭌이 사장님께 [제안] → 확정되면 `plan/title.txt`

## [4] 구역 목록

| 줄 | 구역 |
|---|---|
| 1~6 | frontmatter: 이름(name), 설명(description), 도구(tools), 모델(model) |
| 7~8 | 제목과 "너는 …이다" 한 줄 |
| 할 일 | 이 직원만의 일 |
| 함께 일하는 법 | 책 팀 4명 공통 규칙 |

## [5] 먼저 알 용어

- **에이전트(agent)**: 역할이 정해진 AI 하나. 이 출판사에서는 "직원".
- **frontmatter(머리 정보)**: 파일 맨 위 `---` 와 `---` 사이. Claude Code 가 읽는 설정(이름·설명·도구·모델).
- **본문**: 두 번째 `---` 아래. 그 직원에게 주는 지시문(마크다운). `#` = 제목, `-` = 목록.
- **SendMessage**: 팀원끼리, 또는 팀원과 쭌(team-lead)이 메시지를 주고받는 도구.
- **Task 도구(TaskCreate·TaskGet·TaskList·TaskUpdate)**: 팀의 할 일 목록을 만들고 보고 고치는 도구.

## [6] 읽는 순서

frontmatter(1~6행) → 할 일 → 함께 일하는 법

## [7] 다 읽고 확인

- 목차를 기본 5장으로 바꾸고 싶으면 어느 파일 어느 줄을 고치나요? (이 파일 10행 "기본 3장", CLAUDE.md 3장 "기본 **3장**" 둘 다)
- 민준은 Bash 명령을 쓸 수 있나요? (아니요. 4행 tools 에 Bash 가 없습니다)

## 줄마다 풀이

각 줄은 `원문` → **뜻** → **낱말** → **바꾸면** 순서입니다. 줄 번호는 원래 파일의 줄 번호입니다.

### 1행

```text
---
```

- **뜻**: 머리 정보(frontmatter)의 시작 표시.
- **바꾸면**: 이 줄이 없으면 Claude Code 가 이 파일을 직원 설정으로 읽지 못합니다.

### 2행

```text
name: planner
```

- **뜻**: 직원 종류의 시스템 이름. staff.yml 의 `agent: planner` 와 같아야 합니다.
- **낱말**:
  - `name` — 영문 소문자·줄표만.
- **바꾸면**: 바꾸면 staff.yml 의 agent 값도 같이 바꿔야 합니다.

### 3행

```text
description: 기획실장 민준. 책의 독자·목차·제목·문체를 정한다. 출판사 팀에서 기획이 필요할 때 사용.
```

- **뜻**: 이 직원이 누구이고 언제 쓰는지 한 줄 소개. 쭌이 어떤 직원을 띄울지 고를 때 읽습니다.
- **낱말**:
  - `description` — 설명.

### 4행

```text
tools: Read, Write, Edit, Glob, Grep, WebSearch, WebFetch, SendMessage, TaskCreate, TaskGet, TaskList, TaskUpdate
```

- **뜻**: 이 직원이 쓸 수 있는 도구 목록. 책 팀은 **Bash(명령 실행)가 없습니다** — 파일 읽기·쓰기, 웹 검색, 메시지, 할 일 목록만 씁니다.
- **낱말**:
  - `tools` — 쉼표로 나눈 도구 이름들.
  - `SendMessage` — 꼭 있어야 합니다. 없으면 동료·쭌에게 말을 못 걸어 혼자 멈춥니다.
  - `WebSearch, WebFetch` — 웹 검색·웹 페이지 읽기.
- **바꾸면**: 도구를 빼면 그 일을 못 합니다. 새 직원을 만들 때도 SendMessage 는 꼭 넣습니다(staff.yml 머리 설명).

### 5행

```text
model: sonnet
```

- **뜻**: 이 직원이 쓸 AI 모델 = Sonnet.
- **낱말**:
  - `model` — AI 두뇌 종류. sonnet / opus / haiku 등.
- **바꾸면**: opus 로 바꾸면 더 꼼꼼하지만 사용량이 늘고, haiku 로 바꾸면 빠르고 싸지만 글 품질이 떨어질 수 있습니다.

### 6행

```text
---
```

- **뜻**: 머리 정보의 끝 표시. 아래부터는 직원에게 주는 지시문입니다.

### 7행

```text
# 민준 — 기획실장
```

- **뜻**: 지시문 제목.

### 8행

```text
너는 1인 출판사의 기획실장 민준이다.
```

- **뜻**: AI 에게 "너는 누구다"를 알려 주는 첫 문장. 말투와 책임 범위가 여기서 정해집니다.
- **바꾸면**: 다른 주제 팀으로 바꿀 때는 이 문장부터 바꿉니다. 예) "너는 1인 유튜브 팀의 기획 PD 민준이다."

### 9행

```text
## 할 일
```

- **뜻**: 이 직원이 맡은 일 목록의 제목.

### 10행

```text
- 쭌이 알려 준 주제·장르로 `plan/proposal.md`를 쓴다: 제목 3안, 부제, 독자 한 명(나이·상황·고민), 책의 약속 한 문장, 목차(기본 3장, 장마다 소제목 2~3개, 약 1,500자), 문체 규칙(존댓말, 한 문장 60자 이내 등).
```

- **뜻**: 기획서에 들어갈 항목을 하나하나 정합니다. 관리 화면의 책 단계 "기획" 은 이 파일이 생기면 표시됩니다.
- **낱말**:
  - `plan/proposal.md` — 기획서 파일 위치(책 폴더 안).
  - `독자 한 명` — 막연한 "독자들" 이 아니라 구체적인 한 사람을 정하게 함.
- **바꾸면**: 장 수·글자 수를 바꾸면 책 분량이 바뀝니다.

### 11행

```text
- 기획 전에 지훈에게 "이 주제에서 독자가 자주 묻는 것과 확인된 사실"을 먼저 물어보고, 지훈의 research/ 파일을 반영한다.
```

- **뜻**: 조사 → 기획 순서를 지키게 합니다(사실에 바탕을 둔 목차).

### 12행

```text
- 사장님이 고칠 점을 주면 쭌을 통해 받아 proposal.md를 고친다.
```

- **뜻**: 사장님 의견은 쭌을 거쳐서만 받습니다.

### 14행

```text
## 함께 일하는 법
```

- **뜻**: 팀 안에서 말하고 일을 넘기는 규칙의 제목. 책 팀 4명 모두 같은 내용입니다.

### 15행

```text
- 동료(민준=minjun·지훈=jihun·서연=seoyeon·태양=taeyang)와 편집장 쭌(team-lead)에게는 메시지(SendMessage)로 직접 말한다. 짧게, 결과 파일 위치를 꼭 적는다.
```

- **뜻**: 동료와 쭌의 시스템 이름을 알려 주고, SendMessage 로 직접 말하라고 합니다. 받는 사람이 파일을 바로 열 수 있게 위치를 적게 합니다.
- **낱말**:
  - `minjun 등` — staff.yml 의 name. SendMessage 는 한글이 아니라 이 영문 이름으로 보냅니다.
  - `team-lead` — 쭌의 시스템 이름.
- **바꾸면**: 직원을 늘리거나 이름을 바꾸면 4개 파일의 이 줄을 모두 함께 고쳐야 합니다.

### 16행

```text
- 내 일이 끝나면 쭌에게 "[보고] 한 일. 파일 위치"를 보낸다.
```

- **뜻**: 일이 끝났음을 쭌에게 정해진 첫머리 "[보고]" 로 알립니다. 쭌은 이 보고를 모아 사장님께 전합니다.
- **바꾸면**: 빼면 쭌이 끝난 줄 모르고 계속 기다립니다.

### 17행

```text
- 다른 사람 파일은 고치지 않는다. 고칠 점은 그 사람에게 의견으로 보낸다.
```

- **뜻**: 여러 AI 가 같은 파일을 동시에 고쳐 내용이 엉키는 것을 막습니다.

### 18행

```text
- 의견을 받아 고쳤으면 보낸 사람에게 "반영 완료"라고 꼭 답한다. (말없이 고치면 상대가 계속 기다린다)
```

- **뜻**: 의견을 준 사람이 다음 일로 넘어가도록 꼭 답하게 합니다.
- **바꾸면**: 빼면 교정 담당(태양)이 계속 답을 기다리는 일이 생깁니다.

### 19행

```text
- 모르는 사실은 지어내지 않는다. 확인 못 한 것은 (확인 필요)로 표시하고 지훈에게 묻는다.
```

- **뜻**: 지어낸 사실이 책에 들어가지 않게 합니다. "(확인 필요)" 는 make-book.sh 가 책을 묶을 때 지웁니다.
- **낱말**:
  - `(확인 필요)` — 나중에 지훈이 확인할 표시.

### 20행

```text
- 사장님(사람)에게 직접 연락하지 않는다. 사장님께 할 말은 쭌에게 보낸다.
```

- **뜻**: 사장님 창구를 쭌 한 명으로 모읍니다. 직원은 채널(reply) 도구를 쓰지 않습니다.
- **바꾸면**: 빼면 사장님이 여러 직원의 메시지를 한꺼번에 받게 됩니다.
PUBLISHER_FILE_33_END

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 파일 ~/my-publisher/설명서/agents-researcher.md.설명.md 를 만든다. (사람이 읽는 설명 파일(AI 는 읽지 않음))
# │   아래 226줄이 그 파일 내용 그대로이고, PUBLISHER_FILE_34_END 줄에서 끝난다.
# └── ▼ 실행 코드 [45] (아래 228줄이 한 덩어리) ────
cat > "$P/설명서/agents-researcher.md.설명.md" <<'PUBLISHER_FILE_34_END'
# .claude/agents/researcher.md 설명

> 이 문서는 `publisher-kit/.claude/agents/researcher.md` 의 **한 줄 한 줄**을 풀어 쓴 설명입니다.
> 원래 파일은 한 글자도 바꾸지 않았습니다. 이 파일은 AI 직원이 일을 시작할 때 **통째로 읽는 지시문**이라, 안에 설명을 넣으면 AI 도 그 설명을 지시로 읽습니다. 그래서 설명을 이 파일에 따로 둡니다. 이 설명서는 `.claude/agents/` 폴더 밖에 있어서 직원으로 인식되지 않습니다.

## [1] 역할

자료조사실장 **지훈**의 역할 설명입니다. 사실·숫자·출처를 웹에서 확인해 `research/facts.md` 에 정리합니다.

## [2] 누가 언제 읽나

쭌이 책 주문을 받으면 CLAUDE.md 2장 4번대로 staff.yml 에서 team: book 인 직원을 띄웁니다. 이때 `agent` 값(예: planner)과 같은 이름의 이 파일을 Claude Code 가 읽어 그 직원의 역할로 씁니다.

## [3] 앞뒤 파일

staff.yml(`agent: researcher`) → **이 파일** → 결과 `books/…/research/facts.md` → 민준(기획)·서연(집필)이 씀

## [4] 구역 목록

| 줄 | 구역 |
|---|---|
| 1~6 | frontmatter: 이름(name), 설명(description), 도구(tools), 모델(model) |
| 7~8 | 제목과 "너는 …이다" 한 줄 |
| 할 일 | 이 직원만의 일 |
| 함께 일하는 법 | 책 팀 4명 공통 규칙 |

## [5] 먼저 알 용어

- **에이전트(agent)**: 역할이 정해진 AI 하나. 이 출판사에서는 "직원".
- **frontmatter(머리 정보)**: 파일 맨 위 `---` 와 `---` 사이. Claude Code 가 읽는 설정(이름·설명·도구·모델).
- **본문**: 두 번째 `---` 아래. 그 직원에게 주는 지시문(마크다운). `#` = 제목, `-` = 목록.
- **SendMessage**: 팀원끼리, 또는 팀원과 쭌(team-lead)이 메시지를 주고받는 도구.
- **Task 도구(TaskCreate·TaskGet·TaskList·TaskUpdate)**: 팀의 할 일 목록을 만들고 보고 고치는 도구.

## [6] 읽는 순서

frontmatter(1~6행) → 할 일 → 함께 일하는 법

## [7] 다 읽고 확인

- 지훈이 웹을 쓰려면 어떤 도구가 필요하고, 어디서 허락되나요? (WebSearch·WebFetch. 이 파일 4행 tools 와 settings.json allow)
- 출처마다 숫자가 다르면 지훈은 어떻게 하나요? (12행: 안전한 문장을 함께 제안)

## 줄마다 풀이

각 줄은 `원문` → **뜻** → **낱말** → **바꾸면** 순서입니다. 줄 번호는 원래 파일의 줄 번호입니다.

### 1행

```text
---
```

- **뜻**: 머리 정보(frontmatter)의 시작 표시.
- **바꾸면**: 이 줄이 없으면 Claude Code 가 이 파일을 직원 설정으로 읽지 못합니다.

### 2행

```text
name: researcher
```

- **뜻**: 직원 종류의 시스템 이름. staff.yml 의 `agent: researcher` 와 같아야 합니다.

### 3행

```text
description: 자료조사실장 지훈. 사실·숫자·출처를 웹에서 확인한다. 출판사 팀에서 조사가 필요할 때 사용.
```

- **뜻**: 한 줄 소개. 쭌이 고를 때 읽습니다.

### 4행

```text
tools: Read, Write, Edit, Glob, Grep, WebSearch, WebFetch, SendMessage, TaskCreate, TaskGet, TaskList, TaskUpdate
```

- **뜻**: 이 직원이 쓸 수 있는 도구 목록. 책 팀은 **Bash(명령 실행)가 없습니다** — 파일 읽기·쓰기, 웹 검색, 메시지, 할 일 목록만 씁니다.
- **낱말**:
  - `tools` — 쉼표로 나눈 도구 이름들.
  - `SendMessage` — 꼭 있어야 합니다. 없으면 동료·쭌에게 말을 못 걸어 혼자 멈춥니다.
  - `WebSearch, WebFetch` — 웹 검색·웹 페이지 읽기.
- **바꾸면**: 도구를 빼면 그 일을 못 합니다. 새 직원을 만들 때도 SendMessage 는 꼭 넣습니다(staff.yml 머리 설명).

### 5행

```text
model: sonnet
```

- **뜻**: 이 직원이 쓸 AI 모델 = Sonnet.
- **낱말**:
  - `model` — AI 두뇌 종류. sonnet / opus / haiku 등.
- **바꾸면**: opus 로 바꾸면 더 꼼꼼하지만 사용량이 늘고, haiku 로 바꾸면 빠르고 싸지만 글 품질이 떨어질 수 있습니다.

### 6행

```text
---
```

- **뜻**: 머리 정보의 끝 표시. 아래부터는 직원에게 주는 지시문입니다.

### 7행

```text
# 지훈 — 자료조사실장
```

- **뜻**: 지시문 제목.

### 8행

```text
너는 1인 출판사의 자료조사실장 지훈이다.
```

- **뜻**: "너는 누구다" 첫 문장.

### 9행

```text
## 할 일
```

- **뜻**: 이 직원이 맡은 일 목록의 제목.

### 10행

```text
- 주제에 필요한 사실을 웹에서 찾아 `research/facts.md`에 정리한다. 문장마다 출처(기관 이름과 주소)와 확인 날짜를 붙인다.
```

- **뜻**: 조사 결과 파일과 적는 방법. 출처·날짜가 있어야 나중에 확인할 수 있습니다.
- **낱말**:
  - `research/facts.md` — 조사 파일 위치.

### 11행

```text
- 공공기관·대학·전문기관 자료를 우선한다. 블로그는 참고만 한다.
```

- **뜻**: 믿을 만한 출처 순서를 정합니다.

### 12행

```text
- 출처마다 말이 다르면 숫자 하나로 못 박지 말고 "안전한 문장"을 함께 제안한다.
```

- **뜻**: 틀린 숫자를 단정하지 않게 합니다. 예) "하루 30분 정도가 흔히 권장됩니다".

### 13행

```text
- 민준·서연·태양이 사실을 물으면 출처와 함께 답한다.
```

- **뜻**: 팀의 사실 확인 담당이라는 뜻.

### 15행

```text
## 함께 일하는 법
```

- **뜻**: 팀 안에서 말하고 일을 넘기는 규칙의 제목. 책 팀 4명 모두 같은 내용입니다.

### 16행

```text
- 동료(민준=minjun·지훈=jihun·서연=seoyeon·태양=taeyang)와 편집장 쭌(team-lead)에게는 메시지(SendMessage)로 직접 말한다. 짧게, 결과 파일 위치를 꼭 적는다.
```

- **뜻**: 동료와 쭌의 시스템 이름을 알려 주고, SendMessage 로 직접 말하라고 합니다. 받는 사람이 파일을 바로 열 수 있게 위치를 적게 합니다.
- **낱말**:
  - `minjun 등` — staff.yml 의 name. SendMessage 는 한글이 아니라 이 영문 이름으로 보냅니다.
  - `team-lead` — 쭌의 시스템 이름.
- **바꾸면**: 직원을 늘리거나 이름을 바꾸면 4개 파일의 이 줄을 모두 함께 고쳐야 합니다.

### 17행

```text
- 내 일이 끝나면 쭌에게 "[보고] 한 일. 파일 위치"를 보낸다.
```

- **뜻**: 일이 끝났음을 쭌에게 정해진 첫머리 "[보고]" 로 알립니다. 쭌은 이 보고를 모아 사장님께 전합니다.
- **바꾸면**: 빼면 쭌이 끝난 줄 모르고 계속 기다립니다.

### 18행

```text
- 다른 사람 파일은 고치지 않는다. 고칠 점은 그 사람에게 의견으로 보낸다.
```

- **뜻**: 여러 AI 가 같은 파일을 동시에 고쳐 내용이 엉키는 것을 막습니다.

### 19행

```text
- 의견을 받아 고쳤으면 보낸 사람에게 "반영 완료"라고 꼭 답한다. (말없이 고치면 상대가 계속 기다린다)
```

- **뜻**: 의견을 준 사람이 다음 일로 넘어가도록 꼭 답하게 합니다.
- **바꾸면**: 빼면 교정 담당(태양)이 계속 답을 기다리는 일이 생깁니다.

### 20행

```text
- 모르는 사실은 지어내지 않는다. 확인 못 한 것은 (확인 필요)로 표시하고 지훈에게 묻는다.
```

- **뜻**: 지어낸 사실이 책에 들어가지 않게 합니다. "(확인 필요)" 는 make-book.sh 가 책을 묶을 때 지웁니다.
- **낱말**:
  - `(확인 필요)` — 나중에 지훈이 확인할 표시.

### 21행

```text
- 사장님(사람)에게 직접 연락하지 않는다. 사장님께 할 말은 쭌에게 보낸다.
```

- **뜻**: 사장님 창구를 쭌 한 명으로 모읍니다. 직원은 채널(reply) 도구를 쓰지 않습니다.
- **바꾸면**: 빼면 사장님이 여러 직원의 메시지를 한꺼번에 받게 됩니다.
PUBLISHER_FILE_34_END

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 파일 ~/my-publisher/설명서/agents-writer.md.설명.md 를 만든다. (사람이 읽는 설명 파일(AI 는 읽지 않음))
# │   아래 235줄이 그 파일 내용 그대로이고, PUBLISHER_FILE_35_END 줄에서 끝난다.
# └── ▼ 실행 코드 [46] (아래 237줄이 한 덩어리) ────
cat > "$P/설명서/agents-writer.md.설명.md" <<'PUBLISHER_FILE_35_END'
# .claude/agents/writer.md 설명

> 이 문서는 `publisher-kit/.claude/agents/writer.md` 의 **한 줄 한 줄**을 풀어 쓴 설명입니다.
> 원래 파일은 한 글자도 바꾸지 않았습니다. 이 파일은 AI 직원이 일을 시작할 때 **통째로 읽는 지시문**이라, 안에 설명을 넣으면 AI 도 그 설명을 지시로 읽습니다. 그래서 설명을 이 파일에 따로 둡니다. 이 설명서는 `.claude/agents/` 폴더 밖에 있어서 직원으로 인식되지 않습니다.

## [1] 역할

집필 작가 **서연**의 역할 설명입니다. 확정된 목차대로 `manuscript/01.md` 부터 원고를 쓰고 교정 의견을 반영합니다.

## [2] 누가 언제 읽나

쭌이 책 주문을 받으면 CLAUDE.md 2장 4번대로 staff.yml 에서 team: book 인 직원을 띄웁니다. 이때 `agent` 값(예: planner)과 같은 이름의 이 파일을 Claude Code 가 읽어 그 직원의 역할로 씁니다.

## [3] 앞뒤 파일

plan/proposal.md(민준) + research/(지훈) → **이 파일의 서연** → `manuscript/0N.md` → 태양(교정) → make-book.sh 가 묶음

## [4] 구역 목록

| 줄 | 구역 |
|---|---|
| 1~6 | frontmatter: 이름(name), 설명(description), 도구(tools), 모델(model) |
| 7~8 | 제목과 "너는 …이다" 한 줄 |
| 할 일 | 이 직원만의 일 |
| 함께 일하는 법 | 책 팀 4명 공통 규칙 |

## [5] 먼저 알 용어

- **에이전트(agent)**: 역할이 정해진 AI 하나. 이 출판사에서는 "직원".
- **frontmatter(머리 정보)**: 파일 맨 위 `---` 와 `---` 사이. Claude Code 가 읽는 설정(이름·설명·도구·모델).
- **본문**: 두 번째 `---` 아래. 그 직원에게 주는 지시문(마크다운). `#` = 제목, `-` = 목록.
- **SendMessage**: 팀원끼리, 또는 팀원과 쭌(team-lead)이 메시지를 주고받는 도구.
- **Task 도구(TaskCreate·TaskGet·TaskList·TaskUpdate)**: 팀의 할 일 목록을 만들고 보고 고치는 도구.

## [6] 읽는 순서

frontmatter(1~6행) → 할 일 → 함께 일하는 법

## [7] 다 읽고 확인

- 원고 파일 첫 줄을 `# 1장. 장 제목` 모양으로 쓰게 하는 이유는? (make-book.sh 가 첫 `#` 줄을 장 제목·차례로 씁니다)
- 서연이 목차를 바꾸고 싶으면? (14행: 혼자 바꾸지 않고 민준에게 의견)

## 줄마다 풀이

각 줄은 `원문` → **뜻** → **낱말** → **바꾸면** 순서입니다. 줄 번호는 원래 파일의 줄 번호입니다.

### 1행

```text
---
```

- **뜻**: 머리 정보(frontmatter)의 시작 표시.
- **바꾸면**: 이 줄이 없으면 Claude Code 가 이 파일을 직원 설정으로 읽지 못합니다.

### 2행

```text
name: writer
```

- **뜻**: 직원 종류의 시스템 이름(`agent: writer`).

### 3행

```text
description: 집필 작가 서연. 확정된 목차대로 원고를 쓰고 교정 의견을 반영한다. 출판사 팀에서 집필이 필요할 때 사용.
```

- **뜻**: 한 줄 소개.

### 4행

```text
tools: Read, Write, Edit, Glob, Grep, WebSearch, WebFetch, SendMessage, TaskCreate, TaskGet, TaskList, TaskUpdate
```

- **뜻**: 이 직원이 쓸 수 있는 도구 목록. 책 팀은 **Bash(명령 실행)가 없습니다** — 파일 읽기·쓰기, 웹 검색, 메시지, 할 일 목록만 씁니다.
- **낱말**:
  - `tools` — 쉼표로 나눈 도구 이름들.
  - `SendMessage` — 꼭 있어야 합니다. 없으면 동료·쭌에게 말을 못 걸어 혼자 멈춥니다.
  - `WebSearch, WebFetch` — 웹 검색·웹 페이지 읽기.
- **바꾸면**: 도구를 빼면 그 일을 못 합니다. 새 직원을 만들 때도 SendMessage 는 꼭 넣습니다(staff.yml 머리 설명).

### 5행

```text
model: sonnet
```

- **뜻**: 이 직원이 쓸 AI 모델 = Sonnet.
- **낱말**:
  - `model` — AI 두뇌 종류. sonnet / opus / haiku 등.
- **바꾸면**: opus 로 바꾸면 더 꼼꼼하지만 사용량이 늘고, haiku 로 바꾸면 빠르고 싸지만 글 품질이 떨어질 수 있습니다.

### 6행

```text
---
```

- **뜻**: 머리 정보의 끝 표시. 아래부터는 직원에게 주는 지시문입니다.

### 7행

```text
# 서연 — 집필 작가
```

- **뜻**: 지시문 제목.

### 8행

```text
너는 1인 출판사의 집필 작가 서연이다.
```

- **뜻**: "너는 누구다" 첫 문장.

### 9행

```text
## 할 일
```

- **뜻**: 이 직원이 맡은 일 목록의 제목.

### 10행

```text
- `plan/proposal.md`의 목차와 문체대로 `manuscript/01.md`부터 한 장씩 쓴다. 첫 줄은 `# 1장. 장 제목`.
```

- **뜻**: 원고 위치·이름·첫 줄 모양을 정합니다. 관리 화면의 "장 수·글자 수" 는 manuscript/*.md 를 세서 보여 줍니다.
- **낱말**:
  - `manuscript/01.md` — 1장 파일. 이름 순서가 곧 책의 장 순서.
- **바꾸면**: 파일 이름 규칙을 바꾸면 장 순서가 엉킬 수 있습니다.

### 11행

```text
- 사실·숫자는 지훈의 `research/` 파일에 있는 것만 쓴다.
```

- **뜻**: 지어낸 숫자가 들어가지 않게 합니다.

### 12행

```text
- 한 장을 끝낼 때마다 태양에게 "N장 교정 부탁해요. manuscript/0N.md"라고 보낸다.
```

- **뜻**: 한 장씩 교정을 넘기게 합니다(책 전체를 다 쓰고 한꺼번에 고치는 것보다 빠름).

### 13행

```text
- 태양의 의견을 반영하고 "반영 완료"라고 답한 뒤 다음 장으로 넘어간다.
```

- **뜻**: 교정 → 반영 → 다음 장 순서.

### 14행

```text
- 목차를 바꿔야 할 것 같으면 혼자 바꾸지 말고 민준에게 의견을 보낸다.
```

- **뜻**: 사장님이 동의한 목차를 지키게 합니다.

### 16행

```text
## 함께 일하는 법
```

- **뜻**: 팀 안에서 말하고 일을 넘기는 규칙의 제목. 책 팀 4명 모두 같은 내용입니다.

### 17행

```text
- 동료(민준=minjun·지훈=jihun·서연=seoyeon·태양=taeyang)와 편집장 쭌(team-lead)에게는 메시지(SendMessage)로 직접 말한다. 짧게, 결과 파일 위치를 꼭 적는다.
```

- **뜻**: 동료와 쭌의 시스템 이름을 알려 주고, SendMessage 로 직접 말하라고 합니다. 받는 사람이 파일을 바로 열 수 있게 위치를 적게 합니다.
- **낱말**:
  - `minjun 등` — staff.yml 의 name. SendMessage 는 한글이 아니라 이 영문 이름으로 보냅니다.
  - `team-lead` — 쭌의 시스템 이름.
- **바꾸면**: 직원을 늘리거나 이름을 바꾸면 4개 파일의 이 줄을 모두 함께 고쳐야 합니다.

### 18행

```text
- 내 일이 끝나면 쭌에게 "[보고] 한 일. 파일 위치"를 보낸다.
```

- **뜻**: 일이 끝났음을 쭌에게 정해진 첫머리 "[보고]" 로 알립니다. 쭌은 이 보고를 모아 사장님께 전합니다.
- **바꾸면**: 빼면 쭌이 끝난 줄 모르고 계속 기다립니다.

### 19행

```text
- 다른 사람 파일은 고치지 않는다. 고칠 점은 그 사람에게 의견으로 보낸다.
```

- **뜻**: 여러 AI 가 같은 파일을 동시에 고쳐 내용이 엉키는 것을 막습니다.

### 20행

```text
- 의견을 받아 고쳤으면 보낸 사람에게 "반영 완료"라고 꼭 답한다. (말없이 고치면 상대가 계속 기다린다)
```

- **뜻**: 의견을 준 사람이 다음 일로 넘어가도록 꼭 답하게 합니다.
- **바꾸면**: 빼면 교정 담당(태양)이 계속 답을 기다리는 일이 생깁니다.

### 21행

```text
- 모르는 사실은 지어내지 않는다. 확인 못 한 것은 (확인 필요)로 표시하고 지훈에게 묻는다.
```

- **뜻**: 지어낸 사실이 책에 들어가지 않게 합니다. "(확인 필요)" 는 make-book.sh 가 책을 묶을 때 지웁니다.
- **낱말**:
  - `(확인 필요)` — 나중에 지훈이 확인할 표시.

### 22행

```text
- 사장님(사람)에게 직접 연락하지 않는다. 사장님께 할 말은 쭌에게 보낸다.
```

- **뜻**: 사장님 창구를 쭌 한 명으로 모읍니다. 직원은 채널(reply) 도구를 쓰지 않습니다.
- **바꾸면**: 빼면 사장님이 여러 직원의 메시지를 한꺼번에 받게 됩니다.
PUBLISHER_FILE_35_END

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 파일 ~/my-publisher/설명서/settings.json.설명.md 를 만든다. (사람이 읽는 설명 파일(AI 는 읽지 않음))
# │   아래 394줄이 그 파일 내용 그대로이고, PUBLISHER_FILE_36_END 줄에서 끝난다.
# └── ▼ 실행 코드 [47] (아래 396줄이 한 덩어리) ────
cat > "$P/설명서/settings.json.설명.md" <<'PUBLISHER_FILE_36_END'
# .claude/settings.json 설명

> 이 문서는 `publisher-kit/.claude/settings.json` 의 **한 줄 한 줄**을 풀어 쓴 설명입니다.
> 원래 파일은 한 글자도 바꾸지 않았습니다. JSON 파일은 형식상 주석(설명 글)을 넣을 수 없어서, 설명을 이 파일에 따로 둡니다.

## [1] 역할

Claude Code(쭌과 직원들)가 **묻지 않고 해도 되는 일**과 **절대 하면 안 되는 일**을 정하는 설정 파일입니다.
사장님이 자리에 없어도 쭌이 일을 계속하려면, 쓸 도구를 미리 허락해 두어야 합니다(허락하지 않은 도구를 쓰려 하면 쭌 칸에 "허락할까요?" 창이 뜨고 사장님이 답할 때까지 멈춥니다).

## [2] 누가 언제 읽나

`출근` → start.sh 가 `~/my-publisher` 폴더에서 `claude` 를 켤 때 Claude Code 가 이 폴더의 `.claude/settings.json` 을 읽습니다.
쭌이 부르는 직원(팀원)들도 같은 폴더에서 일하므로 같은 규칙을 따릅니다.

## [3] 앞뒤 파일

- start.sh (`cd ~/my-publisher && claude …`) → **이 파일** → 쭌이 도구를 쓸 때마다 허락/금지 검사
- CLAUDE.md 6장 "Bash 명령은 제본기 한 줄 외에는 쓰지 않는다" 는 이 파일의 allow 목록과 짝입니다.
- `.claude/agents/devops.md`(테포)의 "내가 쓰는 명령" 표는 allow 의 `bash tepo/…` 줄들과 짝입니다.

## [4] 구역 목록

| 줄 | 구역 | 하는 일 |
|---|---|---|
| 2~4 | env | 실험 기능 "에이전트 팀"(쭌이 직원을 칸마다 띄우는 기능)을 켬 |
| 6 | defaultMode | 파일 고치기는 묻지 않고 진행 |
| 7~27 | allow | 묻지 않고 써도 되는 도구·명령 목록 |
| 28~38 | deny | 무슨 일이 있어도 막는 명령 목록 |

## [5] 먼저 알 용어

- **JSON**: `{ }`(묶음), `[ ]`(목록), `"이름": 값`, 항목 사이 `,`(마지막 항목 뒤에는 `,` 를 쓰면 안 됨)
- **도구(tool)**: Claude 가 쓸 수 있는 기능. Read(파일 읽기), Write(파일 쓰기), Edit(파일 고치기), Glob(파일 찾기), Grep(글자 찾기), Bash(명령 실행), WebSearch(웹 검색), WebFetch(웹 페이지 읽기)
- **MCP**: Claude 에 바깥 프로그램(fakechat·텔레그램 등)을 잇는 방식. 이어진 프로그램의 기능은 `mcp__이름__기능` 모양의 도구가 됩니다.
- **`Bash(앞부분:*)`**: 명령이 "앞부분" 으로 **시작하면** 맞음. `*` = 그 뒤는 무엇이든.

## [6] 읽는 순서

env → defaultMode → allow → deny. deny 가 allow 보다 우선합니다(둘 다 맞으면 막힘).

## [7] 다 읽고 확인

- 쭌이 `cd books && bash make-book.sh books/…` 처럼 앞에 `cd` 를 붙이면 묻지 않고 실행될까요? (아니요. `bash make-book.sh` 로 **시작**해야 allow 에 맞습니다. 그래서 CLAUDE.md 5장이 "정확히 이 모양 한 줄만" 이라고 합니다)
- deny 에 `git push` 가 있는데 테포의 github-setup.sh 는 어떻게 push 하나요? (규칙은 쭌·테포가 **직접 치는** 명령에만 걸립니다. 허락된 스크립트 `bash tepo/github-setup.sh` 안에서 실행되는 git push 는 그 스크립트의 일부입니다)

## 줄마다 풀이

각 줄은 `원문` → **뜻** → **낱말** → **바꾸면** 순서입니다. 줄 번호는 원래 파일의 줄 번호입니다.

### 1행

```text
{
```

- **뜻**: JSON 묶음의 시작. 파일 전체가 하나의 묶음입니다.

### 2행

```text
  "env": {
```

- **뜻**: Claude Code 가 켜질 때 넣을 환경변수 묶음의 시작.
- **낱말**:
  - `env` — environment(환경). 프로그램에 넘기는 설정값.

### 3행

```text
    "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1"
```

- **뜻**: 실험 기능 **에이전트 팀**을 켭니다. 쭌(팀장)이 직원(팀원)을 따로 띄우고, 직원끼리 SendMessage 로 이야기하게 하는 기능입니다.
- **낱말**:
  - `EXPERIMENTAL` — 실험 중인 기능(앞으로 바뀔 수 있음).
  - `"1"` — 켬.
- **바꾸면**: 지우거나 "0" 으로 바꾸면 쭌이 팀원을 띄우지 못해 혼자 다 하려 하고, 사무실 화면의 직원 칸도 생기지 않습니다.

### 4행

```text
  },
```

- **뜻**: env 묶음의 끝. 뒤에 다음 항목이 있어서 `,` 를 붙였습니다.

### 5행

```text
  "permissions": {
```

- **뜻**: 권한(허락·금지) 묶음의 시작.

### 6행

```text
    "defaultMode": "acceptEdits",
```

- **뜻**: 기본 방식: **파일 만들기·고치기는 묻지 않고 받아들입니다.** 원고·기획서를 쓸 때마다 사장님께 묻지 않게 하려는 것입니다.
- **낱말**:
  - `defaultMode` — 목록에 없는 일을 어떻게 할지의 기본값.
  - `acceptEdits` — 편집(파일 쓰기·고치기)은 자동 승인. 그 밖의 명령은 묻습니다.
- **바꾸면**: "default" 로 바꾸면 파일을 쓸 때마다 쭌 칸에 확인 창이 떠서, 사장님이 없을 때 작업이 멈춥니다.

### 7행

```text
    "allow": [
```

- **뜻**: **묻지 않고 써도 되는 것** 목록의 시작.
- **낱말**:
  - `allow` — 허락.
  - `[` — 목록의 시작.

### 8행

```text
      "Read",
```

- **뜻**: 파일 읽기 도구를 허락합니다.

### 9행

```text
      "Write",
```

- **뜻**: 파일 쓰기(새로 만들기) 도구를 허락합니다. 원고·기획서·표지 파일을 씁니다.

### 10행

```text
      "Edit",
```

- **뜻**: 파일 일부 고치기 도구를 허락합니다. 교정 반영 때 씁니다.

### 11행

```text
      "Glob",
```

- **뜻**: 파일 이름 모양으로 찾기(예: `manuscript/*.md`)를 허락합니다.

### 12행

```text
      "Grep",
```

- **뜻**: 파일 안의 글자 찾기를 허락합니다.

### 13행

```text
      "WebSearch",
```

- **뜻**: 웹 검색을 허락합니다. 지훈(자료 조사)이 사실을 찾을 때 씁니다.
- **바꾸면**: 지우면 조사할 때마다 확인 창이 뜹니다.

### 14행

```text
      "WebFetch",
```

- **뜻**: 웹 페이지 내용 읽기를 허락합니다. 찾은 출처를 직접 읽을 때 씁니다.

### 15행

```text
      "mcp__plugin_telegram_telegram",
```

- **뜻**: 텔레그램 플러그인의 모든 기능(reply 등)을 허락합니다. 쭌이 휴대폰으로 답할 때 씁니다.
- **낱말**:
  - `mcp__서버이름` — 그 MCP 서버의 기능 전부.
  - `plugin_telegram_telegram` — 플러그인 telegram 안의 서버 telegram.
- **바꾸면**: 지우면 쭌이 답장할 때마다 확인 창이 떠서, 사장님이 휴대폰만 볼 때는 답이 오지 않습니다.

### 16행

```text
      "mcp__plugin_fakechat_fakechat",
```

- **뜻**: 관리 화면 대화방(fakechat)의 모든 기능을 허락합니다.
- **바꾸면**: 지우면 관리 화면 대화방으로 답이 오지 않고 쭌 칸에서 확인을 기다립니다.

### 17행

```text
      "Bash(bash make-book.sh:*)",
```

- **뜻**: `bash make-book.sh` 로 **시작하는** 명령만 묻지 않고 실행합니다. 쭌이 책을 묶을 때 씁니다.
- **낱말**:
  - `Bash(…)` — 명령 실행 도구 중 괄호 안 모양에 맞는 것만.
  - `:*` — 뒤에 무엇이 오든(책 폴더 이름).
- **바꾸면**: 다른 주제로 바꿀 때 결과물 도구 이름이 바뀌면 이 줄도 같이 바꿔야 합니다. 예) `"Bash(bash make-video.sh:*)"`

### 18행

```text
      "Bash(mkdir:*)",
```

- **뜻**: 폴더 만들기 명령을 허락합니다.

### 19행

```text
      "Bash(ls:*)",
```

- **뜻**: 파일 목록 보기 명령을 허락합니다.

### 20행

```text
      "Bash(date:*)",
```

- **뜻**: 날짜·시각 보기 명령을 허락합니다(작업 폴더 이름의 날짜, 승인 시각).

### 21행

```text
      "Bash(bash tepo/preflight.sh:*)",
```

- **뜻**: 테포의 준비 확인 스크립트(돈 안 듦).

### 22행

```text
      "Bash(bash tepo/create-infra.sh:*)",
```

- **뜻**: 테포의 서버 만들기 스크립트. 허락되어 있어도 **스크립트 스스로** 사장님 승인 기록(ops/approved.txt)이 없으면 멈춥니다.

### 23행

```text
      "Bash(bash tepo/server-setup.sh:*)",
```

- **뜻**: 테포의 서버 설치 스크립트.

### 24행

```text
      "Bash(bash tepo/github-setup.sh:*)",
```

- **뜻**: 테포의 GitHub 설정·올리기 스크립트(`--push-only` 포함).

### 25행

```text
      "Bash(bash tepo/deploy-status.sh:*)",
```

- **뜻**: 테포의 배포 결과 보기 스크립트.

### 26행

```text
      "Bash(bash tepo/health.sh:*)"
```

- **뜻**: 테포의 서버 상태 보기 스크립트. 목록의 마지막이라 뒤에 `,` 가 없습니다.

### 27행

```text
    ],
```

- **뜻**: allow 목록의 끝.

### 28행

```text
    "deny": [
```

- **뜻**: **절대 막는 것** 목록의 시작. allow 와 겹치면 이쪽이 이깁니다.
- **낱말**:
  - `deny` — 거부.

### 29행

```text
      "Bash(rm -rf:*)",
```

- **뜻**: 폴더를 통째로 지우는 명령을 막습니다(실수로 책·기록을 지우지 않게).

### 30행

```text
      "Bash(sudo:*)",
```

- **뜻**: 관리자 권한 명령을 막습니다(우분투 시스템을 건드리지 않게).

### 31행

```text
      "Bash(git push:*)",
```

- **뜻**: 쭌·직원이 직접 GitHub 에 올리는 것을 막습니다. 올리기는 테포의 github-setup.sh 를 통해서만 합니다.

### 32행

```text
      "Bash(curl:*)",
```

- **뜻**: 인터넷 주소에 직접 요청하는 명령을 막습니다(웹 읽기는 WebFetch 로만).

### 33행

```text
      "Bash(wget:*)",
```

- **뜻**: 파일 내려받기 명령을 막습니다.

### 34행

```text
      "Bash(aws lightsail delete-instance:*)",
```

- **뜻**: 서버 지우기를 막습니다. 지우기는 사장님이 라이트세일 화면에서 직접 합니다.

### 35행

```text
      "Bash(aws lightsail delete-relational-database:*)",
```

- **뜻**: DB 지우기를 막습니다(책·주문 기록이 사라지지 않게).

### 36행

```text
      "Bash(aws lightsail release-static-ip:*)",
```

- **뜻**: 고정 IP 놓기를 막습니다(주소가 바뀌지 않게).

### 37행

```text
      "Bash(gh repo delete:*)"
```

- **뜻**: GitHub 저장소 지우기를 막습니다. 목록의 마지막.

### 38행

```text
    ]
```

- **뜻**: deny 목록의 끝.

### 39행

```text
  }
```

- **뜻**: permissions 묶음의 끝.

### 40행

```text
}
```

- **뜻**: 파일 전체 묶음의 끝.
PUBLISHER_FILE_36_END

# ━━━━━━━━━━ 구역 3  마무리 설치 ━━━━━━━━━━

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 스크립트 파일들을 실행할 수 있게 한다.
# │   chmod +x    : 실행 권한 주기.
# │   *.sh        : .sh 로 끝나는 모든 파일.
# │   tepo/mock/* : 연습용 가짜 명령 전부(aws, gh, ssh …).
# └── ▼ 실행 코드 [48] ──────────────
chmod +x "$P"/*.sh "$P"/tepo/*.sh "$P"/tepo/templates/*.sh "$P"/tepo/mock/*

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: zip 안에 관리 화면 jar 가 있으면 ~/my-publisher/dashboard/ 로 복사한다. start.sh 가 이 jar 를 켠다.
# │   [ -f 파일 ] : 그 파일이 있으면 참.
# │   cp          : 복사.
# └── ▼ 실행 코드 [49] ──────────────
if [ -f "$HERE/publisher-dashboard.jar" ]; then cp "$HERE/publisher-dashboard.jar" "$P/dashboard/"; echo "📊 관리 화면 설치: $P/dashboard/publisher-dashboard.jar"; fi

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: Claude Code(claude 명령)가 설치되어 있으면 아래 줄로 fakechat 플러그인을 설치한다.
# │   command -v : 명령이 있는지 찾기.
# └── ▼ 실행 코드 [50] ──────────────
if command -v claude >/dev/null; then

  # ┌── 설명 ──────────────────────────────────
  # │ ▶ 이 줄이 하는 일: 관리 화면 대화방 ↔ 쭌 연결 플러그인 fakechat 을 설치한다. 실패하면 공식 장터를 먼저 추가하고 다시 설치한다. 이미 있으면 그냥 넘어간다.
  # │   claude plugin install 이름@장터 : 플러그인 설치.
  # │   marketplace add                 : 플러그인 장터(목록) 추가.
  # │   a || { b; c; }                  : a 가 실패하면 b, c 를 차례로.
  # └── ▼ 실행 코드 [51] ──────────────
  if claude plugin install fakechat@claude-plugins-official >/dev/null 2>&1 || { claude plugin marketplace add anthropics/claude-plugins-official >/dev/null 2>&1; claude plugin install fakechat@claude-plugins-official >/dev/null 2>&1; }; then echo "🔌 관리 화면 연결 준비 완료 (fakechat)"; else echo "⚠️ 연결 플러그인 설치 실패: 클로드 입력칸에 /plugin install fakechat@claude-plugins-official"; fi

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 위 if 의 끝.
# └── ▼ 실행 코드 [52] ──────────────
fi

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: tmux 가 없으면 설치 방법을 알린다(출근 화면에 꼭 필요).
# └── ▼ 실행 코드 [53] ──────────────
command -v tmux >/dev/null || echo "⚠️ tmux가 없어요: sudo apt install -y tmux"

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: Java 가 없으면 알린다(없으면 관리 화면만 안 켜지고 쭌은 일함).
# └── ▼ 실행 코드 [54] ──────────────
command -v java >/dev/null || echo "⚠️ Java가 없어서 관리 화면은 꺼져 있어요: sudo apt install -y openjdk-21-jre-headless"

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: ~/.bashrc 에 `출근` 단축 명령을 한 번만 넣는다. 새 우분투 창부터 `출근` 을 입력하면 start.sh 가 실행된다.
# │   ~/.bashrc         : 우분투 창을 열 때마다 읽는 설정 파일.
# │   alias 이름='명령' : 짧은 이름으로 긴 명령을 부르게 함.
# │   grep -q … ||      : 이미 있으면 다시 넣지 않는다.
# │   >>                : 파일 끝에 덧붙이기.
# └── ▼ 실행 코드 [55] ──────────────
grep -q "alias 출근=" ~/.bashrc 2>/dev/null || echo "alias 출근='bash ~/my-publisher/start.sh'" >> ~/.bashrc

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 설치된 파일 목록을 보여 준다.
# └── ▼ 실행 코드 [56] ──────────────
ls "$P" "$P/.claude/agents"

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 끝 인사.
# └── ▼ 실행 코드 [57] ──────────────
echo "✅ 출판사 준비 완료: ~/my-publisher"
