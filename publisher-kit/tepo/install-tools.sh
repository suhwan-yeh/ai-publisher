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
