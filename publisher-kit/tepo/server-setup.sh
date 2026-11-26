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
