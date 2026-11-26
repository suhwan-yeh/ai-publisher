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
