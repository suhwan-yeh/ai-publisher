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
