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
