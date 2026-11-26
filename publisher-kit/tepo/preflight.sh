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
