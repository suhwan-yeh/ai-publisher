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
