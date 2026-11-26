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
