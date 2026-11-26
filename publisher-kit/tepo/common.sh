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
