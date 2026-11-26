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
