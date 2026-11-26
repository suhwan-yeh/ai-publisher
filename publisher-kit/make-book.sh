#!/bin/bash
# [1] 역할
#     make-book.sh — 원고를 묶어 전자책(HTML·EPUB·PDF)을 만드는 '제본기'. AI 가 아니라 보통 프로그램이라 AI 사용량이 0 이다.
#     쭌(편집장)이 최종 보고 단계에서 `bash make-book.sh books/작업폴더` 로 실행한다(CLAUDE.md 4번, settings.json 의 허용 목록).
#     파일 안에 두 가지 언어가 섞여 있다.
#       - bash   : 맨 위 두 줄과 맨 아래 PDF 만들기
#       - Python : <<'PY' 와 PY 사이. 글(마크다운)을 HTML 로 바꾸고 EPUB 파일을 만든다.
#     다른 주제(예: 유튜브 영상팀)로 바꿀 때는 이 파일 자리에 그 주제의 결과물 도구를 새로 만든다.
#     맨 윗줄 #!/bin/bash : "쉬뱅(shebang)". 이 파일을 /bin/bash 프로그램으로 실행하라는 표시.
#       #! 는 파일 맨 처음에만 쓰며, 뒤에 적힌 프로그램(위치)으로 이 파일을 실행한다.
#
# [2] 받는 것 → 내보내는 것
#     사용법     : bash make-book.sh books/작업폴더
#     받는 것    : books/작업폴더/manuscript/*.md   (장마다 파일 하나, 이름이 _ 로 시작하면 뺌)
#                  books/작업폴더/plan/title.txt    (1줄 제목, 2줄 부제, 3줄 저자)
#                  books/작업폴더/design/cover.svg  (없으면 글자 표지)
#     내보내는 것: books/작업폴더/dist/book.html, dist/book.epub, dist/book.pdf (PDF 는 Windows Edge 또는 Chromium 이 있을 때)
#                  화면 예) ✅ 제본 완료: 「느린 아침의 기술」 5개 장, 약 12,345자
#
# [3] 앞뒤 파일
#     CLAUDE.md(4. 최종 보고) → 쭌이 이 파일 실행 → dist/book.*
#                                              → 관리 화면이 dist/ 를 읽어 "PDF·EPUB 내려받기" 단추를 보여 줌
#     .claude/settings.json 의 "Bash(bash make-book.sh:*)" 줄이 있어야 쭌이 묻지 않고 실행할 수 있다.
#
# [4] 구역 목록
#     구역 1  책 폴더 확인 (bash)
#     구역 2  Python 시작: 원고 목록, 제목 읽기
#     구역 3  마크다운 → HTML 바꾸는 함수 inline, md2html
#     구역 4  장(chapter) 모으기, 표지
#     구역 5  book.html 만들기 (모양 css 포함)
#     구역 6  book.epub 만들기
#     구역 7  결과 알림 (Python 끝)
#     구역 8  book.pdf 만들기 (bash, Edge 또는 Chromium)
#
# [5] 먼저 알 용어
#     bash: $( ), ||, heredoc(<<'PY' … PY), for/if, [ -f ] [ -s ] [ -x ], \ (다음 줄로 이어짐), timeout
#     Python: import, 변수 =, 리스트 [ ], 튜플 ( ), 함수 def, return, if/for, f"…{값}…", re.sub(정규식 바꾸기), with
#     마크다운: # 제목, - 목록, > 인용, **굵게**, *기울임*, `코드`
#
# [6] 읽는 순서
#     구역 1 → 2 → 4 → 5 → 6 → 7 → 8 을 먼저 읽고, 구역 3(글을 HTML 로 바꾸는 규칙)은 마지막에 읽는다.
#
# [7] 다 읽고 확인
#     - plan/title.txt 가 없으면 책 제목은 무엇이 되는가? ("제목 없는 책", 저자 "그린데스크 출판사")
#     - 원고에 "(확인 필요)" 라는 글이 남아 있으면 책에 찍히는가? (아니다. 구역 4 에서 지운다)
#
# [0] 코드만 모아 보기 — 이 파일에서 실제로 실행되는 줄 전체. 아래 본문에서 ▼ 실행 코드 [번호] 를 찾으면 그 줄의 설명이 있다.
#     [1] BOOK_DIR="$(cd "${1:-.}" 2>/dev/null && pwd)" || { echo "❌ 책 폴더를 찾을 수 없어요: $1"; exit 1; }
#     [2] python3 - "$BOOK_DIR" <<'PY' || exit 1
#     [3] import sys, os, re, html, glob, zipfile, uuid, datetime
#     [4] book = sys.argv[1]
#     [5] mdir, ddir = os.path.join(book, "manuscript"), os.path.join(book, "dist")
#     [6] os.makedirs(ddir, exist_ok=True)
#     [7] files = sorted(f for f in glob.glob(os.path.join(mdir, "*.md")) if not os.path.basename(f).startswith("_"))
#     [8] if not files:
#     [9]     print("❌ manuscript 폴더에 원고(.md)가 없습니다. 원고가 먼저 있어야 책을 묶을 수 있어요."); sys.exit(1)
#     [10] meta = ["제목 없는 책", "", "그린데스크 출판사"]
#     [11] tp = os.path.join(book, "plan", "title.txt")
#     [12] if os.path.exists(tp):
#     [13]     lines = [l.strip() for l in open(tp, encoding="utf-8") if l.strip()]
#     [14]     for i, l in enumerate(lines[:3]): meta[i] = re.sub(r"^(제목|부제|저자)\s*[:：]\s*", "", l)
#     [15] title, subtitle, author = meta
#     [16] def inline(t):
#     [17]     t = html.escape(t, quote=False)
#     [18]     t = re.sub(r"`([^`]+)`", r"<code>\1</code>", t)
#     [19]     t = re.sub(r"\*\*([^*]+)\*\*", r"<strong>\1</strong>", t)
#     [20]     t = re.sub(r"(?<!\*)\*([^*\s][^*]*)\*(?!\*)", r"<em>\1</em>", t)
#     [21]     t = re.sub(r"\[([^\]]+)\]\((https?://[^)\s]+)\)", r'<a href="\2">\1</a>', t)
#     [22]     return t
#     [23] def md2html(src):
#     [24]     out, para, lst, bq = [], [], None, None
#     [25]     def flush():
#     [26]         nonlocal para, lst, bq
#     [27]         if para: out.append("<p>" + inline(" ".join(para)) + "</p>"); para = []
#     [28]         if lst: out.append(f"</{lst}>"); lst = None
#     [29]         if bq is not None:
#     [30]             body = "".join(f"<p>{inline(' '.join(x))}</p>" for x in bq if x)
#     [31]             if body: out.append(f"<blockquote>{body}</blockquote>")
#     [32]             bq = None
#     [33]     for raw in src.splitlines():
#     [34]         l = raw.rstrip()
#     [35]         if l.startswith(">"):
#     [36]             t = l[1:].strip()
#     [37]             if bq is None:
#     [38]                 if para or lst: flush()
#     [39]                 bq = [[]]
#     [40]             if t: bq[-1].append(t)
#     [41]             else: bq.append([])
#     [42]             continue
#     [43]         if bq is not None: flush()
#     [44]         if not l.strip(): flush(); continue
#     [45]         l = re.sub(r"^(\s*[-*]\s+)\[ \]\s*", r"\1☐ ", l)
#     [46]         l = re.sub(r"^(\s*[-*]\s+)\[[xX]\]\s*", r"\1☑ ", l)
#     [47]         m = re.match(r"^(#{1,4})\s+(.*)", l)
#     [48]         if m:
#     [49]             flush(); n = len(m.group(1)); out.append(f"<h{n}>{inline(m.group(2))}</h{n}>"); continue
#     [50]         m = re.match(r"^\s*([-*]|\d+[.)])\s+(.*)", l)
#     [51]         if m:
#     [52]             if para: out.append("<p>" + inline(" ".join(para)) + "</p>"); para = []
#     [53]             kind = "ol" if m.group(1)[0].isdigit() else "ul"
#     [54]             if lst != kind:
#     [55]                 if lst: out.append(f"</{lst}>")
#     [56]                 out.append(f"<{kind}>"); lst = kind
#     [57]             out.append(f"<li>{inline(m.group(2))}</li>"); continue
#     [58]         if re.match(r"^-{3,}$", l.strip()): flush(); out.append("<hr/>"); continue
#     [59]         if lst: out.append(f"</{lst}>"); lst = None
#     [60]         para.append(l.strip())
#     [61]     flush()
#     [62]     return "\n".join(out)
#     [63] chapters = []
#     [64] for f in files:
#     [65]     src = open(f, encoding="utf-8").read()
#     [66]     src = re.sub(r"\((확인 필요|출처 필요)\)", "", src)
#     [67]     m = re.search(r"^#\s+(.+)$", src, re.M)
#     [68]     chapters.append((m.group(1).strip() if m else os.path.splitext(os.path.basename(f))[0], md2html(src)))
#     [69] svgp = os.path.join(book, "design", "cover.svg")
#     [70] svg = open(svgp, encoding="utf-8").read() if os.path.exists(svgp) else ""
#     [71] svg = re.sub(r"<\?xml[^>]*\?>", "", svg).strip()
#     [72] text_cover = f'<div class="tc"><h1>{html.escape(title)}</h1><p>{html.escape(subtitle)}</p><p class="au">{ht…
#     [73] cover = svg or text_cover
#     [74] css = """   (+14줄)
#     [75] today = datetime.date.today().isoformat()
#     [76] toc = "".join(f'<li><a href="#ch{i}">{html.escape(t)}</a></li>' for i, (t, _) in enumerate(chapters, 1))
#     [77] body = "".join(f'<section class="ch" id="ch{i}">{h}</section>' for i, (_, h) in enumerate(chapters, 1))
#     [78] page = f"""<!doctype html><html lang="ko"><head><meta charset="utf-8"><title>{html.escape(title)}</title><s…   (+6줄)
#     [79] open(os.path.join(ddir, "book.html"), "w", encoding="utf-8").write(page)
#     [80] uid = "urn:uuid:" + str(uuid.uuid5(uuid.NAMESPACE_URL, book + title))
#     [81] def xhtml(t, inner):
#     [82]     return f'<?xml version="1.0" encoding="utf-8"?><!DOCTYPE html><html xmlns="http://www.w3.org/1999/xhtml…
#     [83] def fix(h):  # XHTML 형식 맞추기
#     [84]     return h.replace("<hr/>", "<hr />")
#     [85] ep = os.path.join(ddir, "book.epub")
#     [86] with zipfile.ZipFile(ep, "w") as z:
#     [87]     z.writestr(zipfile.ZipInfo("mimetype"), "application/epub+zip", compress_type=zipfile.ZIP_STORED)
#     [88]     zc = lambda n, d: z.writestr(n, d, compress_type=zipfile.ZIP_DEFLATED)
#     [89]     zc("META-INF/container.xml", '<?xml version="1.0"?><container version="1.0" xmlns="urn:oasis:names:tc:o…
#     [90]     zc("OEBPS/style.css", css.replace("@page{size:A5;margin:18mm 16mm}", ""))
#     [91]     items, spine = [], []
#     [92]     cov_inner = f'<div class="cover">{svg}</div>' if svg.startswith("<svg") else text_cover
#     [93]     zc("OEBPS/cover.xhtml", xhtml(title, cov_inner)); items.append('<item id="cover" href="cover.xhtml" med…
#     [94]     navl = "".join(f'<li><a href="ch{i}.xhtml">{html.escape(t)}</a></li>' for i, (t, _) in enumerate(chapte…
#     [95]     zc("OEBPS/nav.xhtml", f'<?xml version="1.0" encoding="utf-8"?><!DOCTYPE html><html xmlns="http://www.w3…
#     [96]     items.append('<item id="nav" href="nav.xhtml" media-type="application/xhtml+xml" properties="nav"/>'); …
#     [97]     for i, (t, h) in enumerate(chapters, 1):
#     [98]         zc(f"OEBPS/ch{i}.xhtml", xhtml(t, fix(h)))
#     [99]         items.append(f'<item id="ch{i}" href="ch{i}.xhtml" media-type="application/xhtml+xml"/>'); spine.ap…
#     [100]     items.append('<item id="css" href="style.css" media-type="text/css"/>')
#     [101]     mod = datetime.datetime.now(datetime.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
#     [102]     zc("OEBPS/content.opf", f'<?xml version="1.0" encoding="utf-8"?><package xmlns="http://www.idpf.org/200…
#     [103] n = sum(len(re.sub(r"\s", "", re.sub(r"<[^>]+>", "", h))) for _, h in chapters)
#     [104] print(f"✅ 제본 완료: 「{title}」 {len(chapters)}개 장, 약 {n:,}자")
#     [105] print(f"   📄 {ddir}/book.html")
#     [106] print(f"   📱 {ddir}/book.epub  ← 전자책 리더·리디·교보 eBook 등록용")
#     [107] DIST="$BOOK_DIR/dist"; rm -f "$DIST/book.pdf"
#     [108] EDGE=""
#     [109] for p in "/mnt/c/Program Files (x86)/Microsoft/Edge/Application/msedge.exe" "/mnt/c/Program Files/Microsoft…
#     [110]   [ -f "$p" ] && EDGE="$p" && break
#     [111] done
#     [112] if [ -n "$EDGE" ]; then
#     [113]   W=/mnt/c/Users/Public/ai-publisher-tmp; mkdir -p "$W" && cp "$DIST/book.html" "$W/book.html" && rm -f "$W…
#     [114]   timeout 120 "$EDGE" --headless --disable-gpu --no-pdf-header-footer \   (+1줄)
#     [115]   [ -s "$W/book.pdf" ] && cp "$W/book.pdf" "$DIST/book.pdf"
#     [116] else
#     [117]   for b in chromium chromium-browser google-chrome /opt/pw-browsers/chromium-*/chrome-linux/chrome; do
#     [118]     if command -v "$b" >/dev/null 2>&1 || [ -x "$b" ]; then
#     [119]       timeout 120 "$b" --headless --no-sandbox --disable-gpu --no-pdf-header-footer \   (+1줄)
#     [120]       break
#     [121]     fi
#     [122]   done
#     [123] fi
#     [124] if [ -s "$DIST/book.pdf" ]; then
#     [125]   echo "   📕 $DIST/book.pdf"
#     [126] else
#     [127]   echo "   (PDF 건너뜀 — book.html을 열어 인쇄 → PDF로 저장하세요)"
#     [128] fi

# ━━━━━━━━━━ 구역 1  책 폴더 확인 (bash) ━━━━━━━━━━

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 받은 책 폴더를 "/" 부터 시작하는 전체 경로로 바꿔 BOOK_DIR 에 담는다. 폴더가 없으면 오류를 알리고 끝낸다.
# │   $1                       : 실행할 때 넘긴 첫 번째 값. 예) books/2026-11-09-slow-morning
# │   ${1:-.}                  : 첫 번째 값이 비었으면 . (지금 폴더).
# │   cd … && pwd              : 그 폴더로 들어가서(cd) 전체 경로를 찍는다(pwd). 예) /home/khbs_d_0/my-publisher/books/2026-11-09-slow-morning
# │   "$( … )"                 : 안 명령이 찍은 글이 값이 된다.
# │   2>/dev/null              : cd 가 실패할 때 나오는 오류 글을 버린다.
# │   ||                       : 앞이 실패하면 뒤를 실행한다.
# │   { echo "❌ …"; exit 1; } : 오류 글을 찍고 실패(1)로 끝낸다.
# └── ▼ 실행 코드 [1] ───────────────
BOOK_DIR="$(cd "${1:-.}" 2>/dev/null && pwd)" || { echo "❌ 책 폴더를 찾을 수 없어요: $1"; exit 1; }

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 아래 PY 까지의 글을 Python 프로그램으로 실행한다. 책 폴더 경로를 넘겨준다. Python 이 실패하면 여기서 끝낸다.
# │   python3     : Python 언어 실행 프로그램.
# │   -           : 프로그램을 파일 대신 "입력"으로 받겠다는 뜻.
# │   "$BOOK_DIR" : Python 안에서 sys.argv[1] 로 받는 값.
# │   <<'PY'      : heredoc. 이 줄 다음부터 PY 라고만 적힌 줄 앞까지를 입력으로 준다.
# │                 따옴표('PY')로 감싸서 그 안의 $ 를 bash 가 바꾸지 않고 그대로 Python 에 넘긴다.
# │   || exit 1   : Python 이 실패(원고 없음 등)하면 PDF 단계로 가지 않고 끝낸다.
# └── ▼ 실행 코드 [2] ───────────────
python3 - "$BOOK_DIR" <<'PY' || exit 1

# ━━━━━━━━━━ 구역 2  Python 시작: 원고 목록, 제목 읽기 ━━━━━━━━━━

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 쓸 Python 도구(모듈)들을 불러온다.
# │   import   : 도구 묶음을 불러오는 말.
# │   sys      : 실행할 때 받은 값(sys.argv)·끝내기(sys.exit)
# │   os       : 파일·폴더 경로 다루기
# │   re       : 정규식(글자 모양 규칙)으로 찾기·바꾸기
# │   html     : HTML 특수 글자(< > &) 바꾸기
# │   glob     : "*.md" 같은 모양으로 파일 찾기
# │   zipfile  : zip 파일 만들기 (EPUB 은 사실 zip 파일)
# │   uuid     : 책마다 다른 고유 번호 만들기
# │   datetime : 오늘 날짜·지금 시각
# └── ▼ 실행 코드 [3] ───────────────
import sys, os, re, html, glob, zipfile, uuid, datetime

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 넘겨받은 책 폴더 경로를 book 에 담는다.
# │   sys.argv[1] : bash 가 넘겨준 첫 번째 값(= "$BOOK_DIR"). [0] 은 프로그램 자신이라 [1] 부터가 받은 값.
# └── ▼ 실행 코드 [4] ───────────────
book = sys.argv[1]

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 원고 폴더와 결과 폴더 경로를 한 번에 만든다.
# │   a, b = x, y  : 두 변수에 한 번에 넣는다.
# │   os.path.join : 폴더 이름을 / 로 이어 경로를 만든다. 예) …/slow-morning/manuscript
# │   mdir         : manuscript 폴더 = 원고
# │   ddir         : dist 폴더 = 완성 파일 (distribution 의 줄임)
# └── ▼ 실행 코드 [5] ───────────────
mdir, ddir = os.path.join(book, "manuscript"), os.path.join(book, "dist")

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: dist 폴더를 만든다. 이미 있으면 그냥 넘어간다.
# │   exist_ok=True : 이미 있어도 오류로 보지 않는다.
# └── ▼ 실행 코드 [6] ───────────────
os.makedirs(ddir, exist_ok=True)

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 원고 폴더의 .md 파일을 이름 순서로 모은다. 이름이 _ 로 시작하는 파일(메모 등)은 뺀다.
# │   glob.glob(… "*.md")      : 확장자가 .md 인 파일 전부.
# │   if not … startswith("_") : 이름이 _ 로 시작하지 않는 것만.
# │   sorted                   : 이름 순서로 정렬. 그래서 원고 이름을 01-…, 02-… 로 짓는다.
# │   결과 예                  : ['…/manuscript/01-intro.md', '…/manuscript/02-morning.md']
# └── ▼ 실행 코드 [7] ───────────────
files = sorted(f for f in glob.glob(os.path.join(mdir, "*.md")) if not os.path.basename(f).startswith("_"))

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 원고가 하나도 없으면 아래 줄을 실행한다.
# │   not files : 목록이 비어 있으면 참.
# └── ▼ 실행 코드 [8] ───────────────
if not files:

    # ┌── 설명 ──────────────────────────────────
    # │ ▶ 이 줄이 하는 일: 원고가 없다는 글을 찍고 실패(1)로 끝낸다. → bash 의 || exit 1 때문에 PDF 단계도 건너뛴다.
    # │   sys.exit(1) : Python 을 실패로 끝낸다.
    # └── ▼ 실행 코드 [9] ───────────────
    print("❌ manuscript 폴더에 원고(.md)가 없습니다. 원고가 먼저 있어야 책을 묶을 수 있어요."); sys.exit(1)

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 책 정보의 기본값. [제목, 부제, 저자] 순서. title.txt 가 없거나 줄이 모자라면 이 값이 쓰인다.
# │   [ … ] : 리스트(여러 값을 순서대로 담는 묶음).
# └── ▼ 실행 코드 [10] ──────────────
meta = ["제목 없는 책", "", "그린데스크 출판사"]

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: title.txt 경로를 tp 에 담는다. 예) …/slow-morning/plan/title.txt
# └── ▼ 실행 코드 [11] ──────────────
tp = os.path.join(book, "plan", "title.txt")

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: title.txt 가 있으면 아래 두 줄로 meta 를 채운다.
# │   os.path.exists : 그 파일이 있으면 True.
# └── ▼ 실행 코드 [12] ──────────────
if os.path.exists(tp):

    # ┌── 설명 ──────────────────────────────────
    # │ ▶ 이 줄이 하는 일: title.txt 를 줄마다 읽어 앞뒤 공백을 지우고, 빈 줄은 뺀다.
    # │   open(tp, encoding="utf-8") : 파일을 한글(utf-8)로 연다. for 로 돌리면 한 줄씩 나온다.
    # │   l.strip()                  : 줄 앞뒤의 공백·줄바꿈을 지운다.
    # │   [x for l in … if …]        : 조건에 맞는 것만 모아 새 리스트를 만드는 짧은 문법.
    # └── ▼ 실행 코드 [13] ──────────────
    lines = [l.strip() for l in open(tp, encoding="utf-8") if l.strip()]

    # ┌── 설명 ──────────────────────────────────
    # │ ▶ 이 줄이 하는 일: 앞 3줄을 차례로 meta 의 0·1·2 번 칸에 넣는다. 줄 앞의 "제목:" "부제:" "저자:" 글자는 지운다.
    # │   lines[:3]                    : 앞에서 3개까지.
    # │   enumerate                    : 번호(i = 0,1,2)와 값(l)을 같이 준다.
    # │   re.sub(규칙, 바꿀 글, 대상)  : 규칙에 맞는 부분을 바꾼다. 여기서는 "" 로 바꿔 지운다.
    # │   ^(제목|부제|저자)\s*[:：]\s* : 줄 맨 앞(^)의 제목/부제/저자 + 공백 + 쌍점(: 또는 전각 ：) + 공백.
    # │                                  예) "제목: 느린 아침의 기술" → "느린 아침의 기술"
    # └── ▼ 실행 코드 [14] ──────────────
    for i, l in enumerate(lines[:3]): meta[i] = re.sub(r"^(제목|부제|저자)\s*[:：]\s*", "", l)

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: meta 의 세 값을 각각 title(제목), subtitle(부제), author(저자)에 나눠 담는다.
# └── ▼ 실행 코드 [15] ──────────────
title, subtitle, author = meta

# ━━━━━━━━━━ 구역 3  마크다운 → HTML 바꾸는 함수 ━━━━━━━━━━

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: inline 함수: 한 줄 안의 마크다운 꾸밈(`코드`, **굵게**, *기울임*, [글](주소))을 HTML 로 바꾼다.
# │   def 이름(값): : 함수 만들기. 아래 들여쓴 줄이 함수 몸통.
# │   t             : 바꿀 글 한 덩어리.
# └── ▼ 실행 코드 [16] ──────────────
def inline(t):

    # ┌── 설명 ──────────────────────────────────
    # │ ▶ 이 줄이 하는 일: < > & 를 &lt; &gt; &amp; 로 바꾼다. 원고의 < 가 HTML 태그로 잘못 읽히지 않게.
    # │   quote=False : 따옴표(" ')는 그대로 둔다.
    # └── ▼ 실행 코드 [17] ──────────────
    t = html.escape(t, quote=False)

    # ┌── 설명 ──────────────────────────────────
    # │ ▶ 이 줄이 하는 일: `글` → <code>글</code> (코드 글씨).
    # │   `([^`]+)` : ` 사이의 글(` 가 아닌 글자 1개 이상).
    # │   \1        : 규칙의 첫 번째 ( ) 에 잡힌 글.
    # └── ▼ 실행 코드 [18] ──────────────
    t = re.sub(r"`([^`]+)`", r"<code>\1</code>", t)

    # ┌── 설명 ──────────────────────────────────
    # │ ▶ 이 줄이 하는 일: **글** → <strong>글</strong> (굵게).
    # │   \* : * 글자 그대로. (* 는 규칙에서 특별한 뜻이 있어 \ 를 붙인다)
    # └── ▼ 실행 코드 [19] ──────────────
    t = re.sub(r"\*\*([^*]+)\*\*", r"<strong>\1</strong>", t)

    # ┌── 설명 ──────────────────────────────────
    # │ ▶ 이 줄이 하는 일: *글* → <em>글</em> (기울임). ** 와 헷갈리지 않게 앞뒤에 * 가 또 붙은 경우는 뺀다.
    # │   (?<!\*) : 바로 앞 글자가 * 가 아닐 때만.
    # │   (?!\*)  : 바로 뒤 글자가 * 가 아닐 때만.
    # └── ▼ 실행 코드 [20] ──────────────
    t = re.sub(r"(?<!\*)\*([^*\s][^*]*)\*(?!\*)", r"<em>\1</em>", t)

    # ┌── 설명 ──────────────────────────────────
    # │ ▶ 이 줄이 하는 일: [글](https://주소) → <a href="주소">글</a> (누르면 열리는 링크).
    # │   https?:// : http:// 또는 https:// 로 시작하는 주소만.
    # │   \2        : 두 번째 ( ) = 주소.
    # └── ▼ 실행 코드 [21] ──────────────
    t = re.sub(r"\[([^\]]+)\]\((https?://[^)\s]+)\)", r'<a href="\2">\1</a>', t)

    # ┌── 설명 ──────────────────────────────────
    # │ ▶ 이 줄이 하는 일: 바꾼 글을 돌려준다.
    # └── ▼ 실행 코드 [22] ──────────────
    return t

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: md2html 함수: 원고 한 장(마크다운 전체)을 HTML 로 바꾼다. 줄을 하나씩 보며 제목·목록·인용·문단을 구별한다.
# │   src : 원고 파일 내용 전체.
# └── ▼ 실행 코드 [23] ──────────────
def md2html(src):

    # ┌── 설명 ──────────────────────────────────
    # │ ▶ 이 줄이 하는 일: 작업용 변수 4개를 준비한다.
    # │   out  : 만든 HTML 조각을 차례로 쌓는 리스트.
    # │   para : 아직 문단으로 내보내지 않은 줄들.
    # │   lst  : 지금 열려 있는 목록 종류. "ul"(점 목록) / "ol"(번호 목록) / None(없음).
    # │   bq   : 모으는 중인 인용(> …) 줄들. None 이면 인용 중이 아님.
    # └── ▼ 실행 코드 [24] ──────────────
    out, para, lst, bq = [], [], None, None

    # ┌── 설명 ──────────────────────────────────
    # │ ▶ 이 줄이 하는 일: flush 함수: 모아 둔 문단·목록·인용을 HTML 로 마무리해 out 에 내보낸다. (flush = 비우다)
    # └── ▼ 실행 코드 [25] ──────────────
    def flush():

        # ┌── 설명 ──────────────────────────────────
        # │ ▶ 이 줄이 하는 일: 바깥 함수(md2html)의 변수 para, lst, bq 를 이 안에서 바꾸겠다는 선언.
        # │   nonlocal : 없으면 이 안에서 새 변수가 생겨 바깥 값이 안 바뀐다.
        # └── ▼ 실행 코드 [26] ──────────────
        nonlocal para, lst, bq

        # ┌── 설명 ──────────────────────────────────
        # │ ▶ 이 줄이 하는 일: 모아 둔 줄이 있으면 띄어쓰기로 이어 <p>문단</p> 으로 내보내고 비운다.
        # │   " ".join(para) : 줄들을 띄어쓰기로 이어 한 덩어리로.
        # │   out.append     : out 리스트 끝에 하나 더 넣는다.
        # └── ▼ 실행 코드 [27] ──────────────
        if para: out.append("<p>" + inline(" ".join(para)) + "</p>"); para = []

        # ┌── 설명 ──────────────────────────────────
        # │ ▶ 이 줄이 하는 일: 열린 목록이 있으면 닫는다. 예) </ul>
        # │   f"</{lst}>" : f 글자: { } 안을 값으로 바꾼다. lst="ul" → "</ul>"
        # └── ▼ 실행 코드 [28] ──────────────
        if lst: out.append(f"</{lst}>"); lst = None

        # ┌── 설명 ──────────────────────────────────
        # │ ▶ 이 줄이 하는 일: 모으는 중인 인용이 있으면 아래 세 줄로 마무리한다.
        # └── ▼ 실행 코드 [29] ──────────────
        if bq is not None:

            # ┌── 설명 ──────────────────────────────────
            # │ ▶ 이 줄이 하는 일: 인용 안의 문단마다 <p>…</p> 로 만들어 붙인다. (> 빈 줄로 문단이 나뉜다)
            # └── ▼ 실행 코드 [30] ──────────────
            body = "".join(f"<p>{inline(' '.join(x))}</p>" for x in bq if x)

            # ┌── 설명 ──────────────────────────────────
            # │ ▶ 이 줄이 하는 일: 내용이 있으면 <blockquote>(인용 상자)로 감싸 내보낸다.
            # └── ▼ 실행 코드 [31] ──────────────
            if body: out.append(f"<blockquote>{body}</blockquote>")

            # ┌── 설명 ──────────────────────────────────
            # │ ▶ 이 줄이 하는 일: 인용 모으기를 끝낸다.
            # └── ▼ 실행 코드 [32] ──────────────
            bq = None

    # ┌── 설명 ──────────────────────────────────
    # │ ▶ 이 줄이 하는 일: 원고를 한 줄씩 본다.
    # │   splitlines() : 글을 줄 단위 리스트로 나눈다.
    # └── ▼ 실행 코드 [33] ──────────────
    for raw in src.splitlines():

        # ┌── 설명 ──────────────────────────────────
        # │ ▶ 이 줄이 하는 일: 줄 끝의 공백을 지운다.
        # └── ▼ 실행 코드 [34] ──────────────
        l = raw.rstrip()

        # ┌── 설명 ──────────────────────────────────
        # │ ▶ 이 줄이 하는 일: 줄이 > 로 시작하면 인용 줄이다.
        # └── ▼ 실행 코드 [35] ──────────────
        if l.startswith(">"):

            # ┌── 설명 ──────────────────────────────────
            # │ ▶ 이 줄이 하는 일: > 를 뺀 나머지 글. 예) "> 아침은 천천히" → "아침은 천천히"
            # │   l[1:] : 두 번째 글자부터 끝까지.
            # └── ▼ 실행 코드 [36] ──────────────
            t = l[1:].strip()

            # ┌── 설명 ──────────────────────────────────
            # │ ▶ 이 줄이 하는 일: 인용이 새로 시작되면 아래 두 줄.
            # └── ▼ 실행 코드 [37] ──────────────
            if bq is None:

                # ┌── 설명 ──────────────────────────────────
                # │ ▶ 이 줄이 하는 일: 앞에 모아 둔 문단·목록을 먼저 내보낸다.
                # └── ▼ 실행 코드 [38] ──────────────
                if para or lst: flush()

                # ┌── 설명 ──────────────────────────────────
                # │ ▶ 이 줄이 하는 일: 인용 모으기 시작. 빈 문단 하나를 가진 리스트.
                # └── ▼ 실행 코드 [39] ──────────────
                bq = [[]]

            # ┌── 설명 ──────────────────────────────────
            # │ ▶ 이 줄이 하는 일: 글이 있으면 지금 인용 문단에 붙인다.
            # │   bq[-1] : 리스트의 마지막 칸.
            # └── ▼ 실행 코드 [40] ──────────────
            if t: bq[-1].append(t)

            # ┌── 설명 ──────────────────────────────────
            # │ ▶ 이 줄이 하는 일: 글이 없는 "> " 줄이면 인용 안에서 새 문단을 시작한다.
            # └── ▼ 실행 코드 [41] ──────────────
            else: bq.append([])

            # ┌── 설명 ──────────────────────────────────
            # │ ▶ 이 줄이 하는 일: 이 줄 처리는 끝. 다음 줄로.
            # └── ▼ 실행 코드 [42] ──────────────
            continue

        # ┌── 설명 ──────────────────────────────────
        # │ ▶ 이 줄이 하는 일: 인용 중이었는데 > 가 아닌 줄이 나오면 인용을 마무리한다.
        # └── ▼ 실행 코드 [43] ──────────────
        if bq is not None: flush()

        # ┌── 설명 ──────────────────────────────────
        # │ ▶ 이 줄이 하는 일: 빈 줄이면 문단이 끝난 것. 내보내고 다음 줄로.
        # └── ▼ 실행 코드 [44] ──────────────
        if not l.strip(): flush(); continue

        # ┌── 설명 ──────────────────────────────────
        # │ ▶ 이 줄이 하는 일: 체크 목록 "- [ ] 할 일" → "- ☐ 할 일"
        # └── ▼ 실행 코드 [45] ──────────────
        l = re.sub(r"^(\s*[-*]\s+)\[ \]\s*", r"\1☐ ", l)

        # ┌── 설명 ──────────────────────────────────
        # │ ▶ 이 줄이 하는 일: 체크 완료 "- [x] 한 일" → "- ☑ 한 일"
        # └── ▼ 실행 코드 [46] ──────────────
        l = re.sub(r"^(\s*[-*]\s+)\[[xX]\]\s*", r"\1☑ ", l)

        # ┌── 설명 ──────────────────────────────────
        # │ ▶ 이 줄이 하는 일: 줄이 # ~ #### + 띄어쓰기로 시작하는지(제목 줄인지) 본다.
        # │   re.match : 줄 맨 앞부터 규칙에 맞는지 본다. 맞으면 m 에 결과, 아니면 None.
        # │   #{1,4}   : # 가 1개에서 4개.
        # └── ▼ 실행 코드 [47] ──────────────
        m = re.match(r"^(#{1,4})\s+(.*)", l)

        # ┌── 설명 ──────────────────────────────────
        # │ ▶ 이 줄이 하는 일: 제목 줄이면 아래 줄 실행.
        # └── ▼ 실행 코드 [48] ──────────────
        if m:

            # ┌── 설명 ──────────────────────────────────
            # │ ▶ 이 줄이 하는 일: 모아 둔 것을 내보내고, # 개수로 제목 크기를 정해 <h1>~<h4> 로 내보낸다.
            # │   m.group(1) : 첫 번째 ( ) 에 잡힌 글 = "##" 같은 # 들.
            # │   len        : 글자 수. "##" → 2 → <h2>
            # └── ▼ 실행 코드 [49] ──────────────
            flush(); n = len(m.group(1)); out.append(f"<h{n}>{inline(m.group(2))}</h{n}>"); continue

        # ┌── 설명 ──────────────────────────────────
        # │ ▶ 이 줄이 하는 일: 줄이 목록(- 또는 * 또는 1. 1))으로 시작하는지 본다.
        # │   [-*]    : - 또는 *
        # │   \d+[.)] : 숫자 + . 또는 )  예) 1.  2)
        # └── ▼ 실행 코드 [50] ──────────────
        m = re.match(r"^\s*([-*]|\d+[.)])\s+(.*)", l)

        # ┌── 설명 ──────────────────────────────────
        # │ ▶ 이 줄이 하는 일: 목록 줄이면 아래 줄 실행.
        # └── ▼ 실행 코드 [51] ──────────────
        if m:

            # ┌── 설명 ──────────────────────────────────
            # │ ▶ 이 줄이 하는 일: 앞에 모아 둔 문단이 있으면 먼저 내보낸다.
            # └── ▼ 실행 코드 [52] ──────────────
            if para: out.append("<p>" + inline(" ".join(para)) + "</p>"); para = []

            # ┌── 설명 ──────────────────────────────────
            # │ ▶ 이 줄이 하는 일: 숫자로 시작하면 "ol"(번호 목록), 아니면 "ul"(점 목록).
            # │   A if 조건 else B : 조건이 참이면 A, 아니면 B.
            # └── ▼ 실행 코드 [53] ──────────────
            kind = "ol" if m.group(1)[0].isdigit() else "ul"

            # ┌── 설명 ──────────────────────────────────
            # │ ▶ 이 줄이 하는 일: 지금 열린 목록과 종류가 다르면 아래 두 줄로 새 목록을 연다.
            # └── ▼ 실행 코드 [54] ──────────────
            if lst != kind:

                # ┌── 설명 ──────────────────────────────────
                # │ ▶ 이 줄이 하는 일: 열린 목록이 있으면 먼저 닫는다.
                # └── ▼ 실행 코드 [55] ──────────────
                if lst: out.append(f"</{lst}>")

                # ┌── 설명 ──────────────────────────────────
                # │ ▶ 이 줄이 하는 일: <ul> 또는 <ol> 을 열고 기억한다.
                # └── ▼ 실행 코드 [56] ──────────────
                out.append(f"<{kind}>"); lst = kind

            # ┌── 설명 ──────────────────────────────────
            # │ ▶ 이 줄이 하는 일: 목록 한 칸 <li>…</li> 를 내보내고 다음 줄로.
            # └── ▼ 실행 코드 [57] ──────────────
            out.append(f"<li>{inline(m.group(2))}</li>"); continue

        # ┌── 설명 ──────────────────────────────────
        # │ ▶ 이 줄이 하는 일: --- (- 3개 이상)만 있는 줄이면 가로줄 <hr/>.
        # └── ▼ 실행 코드 [58] ──────────────
        if re.match(r"^-{3,}$", l.strip()): flush(); out.append("<hr/>"); continue

        # ┌── 설명 ──────────────────────────────────
        # │ ▶ 이 줄이 하는 일: 보통 글 줄이 나왔는데 목록이 열려 있으면 목록을 닫는다.
        # └── ▼ 실행 코드 [59] ──────────────
        if lst: out.append(f"</{lst}>"); lst = None

        # ┌── 설명 ──────────────────────────────────
        # │ ▶ 이 줄이 하는 일: 보통 글 줄은 문단에 모은다.
        # └── ▼ 실행 코드 [60] ──────────────
        para.append(l.strip())

    # ┌── 설명 ──────────────────────────────────
    # │ ▶ 이 줄이 하는 일: 마지막에 남은 것을 내보낸다.
    # └── ▼ 실행 코드 [61] ──────────────
    flush()

    # ┌── 설명 ──────────────────────────────────
    # │ ▶ 이 줄이 하는 일: HTML 조각들을 줄바꿈으로 이어 돌려준다.
    # └── ▼ 실행 코드 [62] ──────────────
    return "\n".join(out)

# ━━━━━━━━━━ 구역 4  장 모으기, 표지 ━━━━━━━━━━

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 장 목록. 한 칸 = (장 제목, 장 HTML).
# └── ▼ 실행 코드 [63] ──────────────
chapters = []

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 원고 파일을 하나씩 처리한다.
# └── ▼ 실행 코드 [64] ──────────────
for f in files:

    # ┌── 설명 ──────────────────────────────────
    # │ ▶ 이 줄이 하는 일: 원고 파일 내용 전체를 읽는다.
    # └── ▼ 실행 코드 [65] ──────────────
    src = open(f, encoding="utf-8").read()

    # ┌── 설명 ──────────────────────────────────
    # │ ▶ 이 줄이 하는 일: 원고에 남은 "(확인 필요)" "(출처 필요)" 표시를 지운다. 기획·조사 단계의 메모가 책에 찍히지 않게.
    # └── ▼ 실행 코드 [66] ──────────────
    src = re.sub(r"\((확인 필요|출처 필요)\)", "", src)

    # ┌── 설명 ──────────────────────────────────
    # │ ▶ 이 줄이 하는 일: 원고에서 첫 번째 "# 제목" 줄을 찾는다.
    # │   re.M : ^ $ 가 글 전체가 아니라 줄마다의 처음·끝을 뜻하게 한다.
    # └── ▼ 실행 코드 [67] ──────────────
    m = re.search(r"^#\s+(.+)$", src, re.M)

    # ┌── 설명 ──────────────────────────────────
    # │ ▶ 이 줄이 하는 일: (장 제목, HTML) 을 장 목록에 넣는다. 제목 줄이 없으면 파일 이름(확장자 뺌)을 제목으로 쓴다.
    # │   os.path.splitext : 이름과 확장자를 나눈다. "01-intro.md" → ("01-intro", ".md")
    # └── ▼ 실행 코드 [68] ──────────────
    chapters.append((m.group(1).strip() if m else os.path.splitext(os.path.basename(f))[0], md2html(src)))

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 표지 그림 경로. 예) …/design/cover.svg (태양이 만든다)
# └── ▼ 실행 코드 [69] ──────────────
svgp = os.path.join(book, "design", "cover.svg")

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 표지 그림이 있으면 읽고, 없으면 빈 글.
# └── ▼ 실행 코드 [70] ──────────────
svg = open(svgp, encoding="utf-8").read() if os.path.exists(svgp) else ""

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 그림 맨 앞의 <?xml …?> 머리줄을 지운다(HTML 안에 넣을 때 필요 없음).
# └── ▼ 실행 코드 [71] ──────────────
svg = re.sub(r"<\?xml[^>]*\?>", "", svg).strip()

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 그림이 없을 때 쓸 글자 표지(제목·부제·저자).
# │   f'…' : 작은따옴표 f 글자. 안에 큰따옴표(class="tc")를 쓰려고 작은따옴표로 감쌌다.
# └── ▼ 실행 코드 [72] ──────────────
text_cover = f'<div class="tc"><h1>{html.escape(title)}</h1><p>{html.escape(subtitle)}</p><p class="au">{html.escape(author)}</p></div>'

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 그림이 있으면 그림, 없으면 글자 표지.
# │   A or B : A 가 비어 있지 않으면 A, 비어 있으면 B.
# └── ▼ 실행 코드 [73] ──────────────
cover = svg or text_cover

# ━━━━━━━━━━ 구역 5  book.html 만들기 ━━━━━━━━━━

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 책의 모양(글꼴·여백·쪽 나눔)을 정하는 CSS 글. """ 부터 """ 까지 여러 줄이 한 값이다.
# │   @page{size:A5…} : 인쇄(PDF) 쪽 크기 A5, 여백 위아래 18mm·양옆 16mm.
# │   body{…}         : 본문 글꼴(한글 명조 계열), 줄 간격 1.85, 단어 중간에서 줄을 바꾸지 않음(keep-all).
# │   .cover          : 표지가 한 쪽을 다 쓰고, 다음 내용은 새 쪽에서(page-break-after).
# │   section.ch      : 장마다 새 쪽에서 시작.
# │   blockquote      : 인용 상자: 왼쪽 초록 줄 + 연한 바탕.
# │   .howto          : 화면에서만 보이는 노란 "PDF 만들기" 안내 상자.
# │   @media print    : 인쇄할 때는 안내 상자를 숨기고 여백을 없앤다.
# └── ▼ 실행 코드 [74] (아래 15줄이 한 덩어리) ────
css = """
@page{size:A5;margin:18mm 16mm}
body{font-family:"Noto Serif KR","Nanum Myeongjo","Apple SD Gothic Neo","Malgun Gothic",serif;line-height:1.85;color:#222;max-width:640px;margin:0 auto;padding:24px;word-break:keep-all}
.cover{min-height:90vh;display:flex;align-items:center;justify-content:center;page-break-after:always;text-align:center}
.cover svg{width:100%;height:auto;max-height:88vh}
.tc h1{font-size:2.2em;margin:0 0 .4em}.tc .au{margin-top:3em;color:#666}
.toc{page-break-after:always}.toc li{margin:.4em 0}
section.ch{page-break-before:always}
h1{font-size:1.6em;margin:1.2em 0 .8em}h2{font-size:1.25em;margin:1.6em 0 .6em}h3{font-size:1.08em}
blockquote{margin:1em 0;padding:.6em 1em;border-left:4px solid #8bb174;background:#f4f8f1}
code{background:#f2f2f2;padding:0 .3em;border-radius:3px}
.colophon{page-break-before:always;font-size:.9em;color:#555;margin-top:30vh}
.howto{background:#fff6e0;border:1px solid #f0c060;padding:10px 14px;border-radius:8px;font-family:sans-serif;font-size:14px}
@media print{.howto{display:none}body{max-width:none;padding:0}}
"""

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 오늘 날짜. 예) 2026-11-10 (책 끝의 "펴낸 날")
# └── ▼ 실행 코드 [75] ──────────────
today = datetime.date.today().isoformat()

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 차례 목록 HTML. 장마다 <li><a href="#ch1">장 제목</a></li>
# │   enumerate(chapters, 1) : 1 부터 번호를 붙인다.
# │   (t, _)                 : 장 제목만 쓰고 HTML 은 쓰지 않는다(_ = 안 쓰는 값).
# └── ▼ 실행 코드 [76] ──────────────
toc = "".join(f'<li><a href="#ch{i}">{html.escape(t)}</a></li>' for i, (t, _) in enumerate(chapters, 1))

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 본문 HTML. 장마다 <section class="ch" id="ch1">…</section>
# └── ▼ 실행 코드 [77] ──────────────
body = "".join(f'<section class="ch" id="ch{i}">{h}</section>' for i, (_, h) in enumerate(chapters, 1))

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 완성 HTML 한 장 전체. 안내 상자 → 표지 → 차례 → 본문 → 끝 쪽(제목·지은이·펴낸 날).
# │   <meta charset="utf-8"> : 한글이 깨지지 않게.
# │   <style>{css}</style>   : 위 css 를 넣는다.
# │   class="colophon"       : 책 맨 끝 판권 쪽.
# └── ▼ 실행 코드 [78] (아래 7줄이 한 덩어리) ────
page = f"""<!doctype html><html lang="ko"><head><meta charset="utf-8"><title>{html.escape(title)}</title><style>{css}</style></head><body>
<p class="howto">📄 PDF 만들기: <b>Ctrl+P</b>(Mac은 <b>⌘P</b>) → 대상(프린터)을 <b>PDF로 저장</b> → 저장. 이 노란 상자는 PDF에 나오지 않아요.</p>
<div class="cover">{cover}</div>
<nav class="toc"><h2>차례</h2><ol>{toc}</ol></nav>
{body}
<div class="colophon"><p><b>{html.escape(title)}</b><br>{html.escape(subtitle)}</p><p>지은이 · {html.escape(author)}<br>펴낸 날 · {today}</p></div>
</body></html>"""

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: dist/book.html 파일로 저장한다.
# │   "w" : 쓰기. 있던 파일은 새로 덮어쓴다.
# └── ▼ 실행 코드 [79] ──────────────
open(os.path.join(ddir, "book.html"), "w", encoding="utf-8").write(page)

# ━━━━━━━━━━ 구역 6  book.epub 만들기 ━━━━━━━━━━

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: EPUB 에 넣을 이 책의 고유 번호. 같은 폴더·같은 제목이면 매번 같은 번호가 나온다.
# │   uuid5 : 이름(폴더+제목)으로 정해지는 번호.
# └── ▼ 실행 코드 [80] ──────────────
uid = "urn:uuid:" + str(uuid.uuid5(uuid.NAMESPACE_URL, book + title))

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: xhtml 함수: EPUB 안의 쪽 하나(XHTML 문서)를 만든다.
# │   XHTML : EPUB 이 요구하는 엄격한 HTML. 태그를 모두 닫아야 한다.
# └── ▼ 실행 코드 [81] ──────────────
def xhtml(t, inner):

    # ┌── 설명 ──────────────────────────────────
    # │ ▶ 이 줄이 하는 일: 머리(제목·style.css 연결) + 몸통(inner) 으로 된 XHTML 글을 돌려준다.
    # └── ▼ 실행 코드 [82] ──────────────
    return f'<?xml version="1.0" encoding="utf-8"?><!DOCTYPE html><html xmlns="http://www.w3.org/1999/xhtml" xml:lang="ko" lang="ko"><head><meta charset="utf-8"/><title>{html.escape(t)}</title><link rel="stylesheet" href="style.css"/></head><body>{inner}</body></html>'

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: fix 함수: XHTML 규칙에 맞게 <hr/> 를 <hr /> 로 고친다.
# │   # XHTML 형식 맞추기 : 줄 끝의 짧은 설명(원래 있던 것).
# └── ▼ 실행 코드 [83] ──────────────
def fix(h):  # XHTML 형식 맞추기

    # ┌── 설명 ──────────────────────────────────
    # │ ▶ 이 줄이 하는 일: 바꾼 글을 돌려준다.
    # └── ▼ 실행 코드 [84] ──────────────
    return h.replace("<hr/>", "<hr />")

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: EPUB 파일 경로. 예) …/dist/book.epub
# └── ▼ 실행 코드 [85] ──────────────
ep = os.path.join(ddir, "book.epub")

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: book.epub 을 zip 으로 새로 만든다. 아래 들여쓴 줄에서 z 에 파일을 넣고, 끝나면 자동으로 닫는다.
# │   with … as z : 열고, 다 쓰면 저절로 닫아 주는 문법.
# │   EPUB        : 정해진 이름의 파일들을 zip 으로 묶은 것.
# └── ▼ 실행 코드 [86] ──────────────
with zipfile.ZipFile(ep, "w") as z:

    # ┌── 설명 ──────────────────────────────────
    # │ ▶ 이 줄이 하는 일: 첫 파일 mimetype = "application/epub+zip". EPUB 규칙상 맨 처음, 압축 없이(ZIP_STORED) 넣어야 한다.
    # └── ▼ 실행 코드 [87] ──────────────
    z.writestr(zipfile.ZipInfo("mimetype"), "application/epub+zip", compress_type=zipfile.ZIP_STORED)

    # ┌── 설명 ──────────────────────────────────
    # │ ▶ 이 줄이 하는 일: zc 함수(짧은 이름): 이름 n 으로 내용 d 를 압축해서 넣는다.
    # │   lambda : 한 줄짜리 함수를 만드는 말.
    # └── ▼ 실행 코드 [88] ──────────────
    zc = lambda n, d: z.writestr(n, d, compress_type=zipfile.ZIP_DEFLATED)

    # ┌── 설명 ──────────────────────────────────
    # │ ▶ 이 줄이 하는 일: 전자책 리더에게 "본문 목록은 OEBPS/content.opf 에 있다" 고 알려 주는 파일.
    # └── ▼ 실행 코드 [89] ──────────────
    zc("META-INF/container.xml", '<?xml version="1.0"?><container version="1.0" xmlns="urn:oasis:names:tc:opendocument:xmlns:container"><rootfiles><rootfile full-path="OEBPS/content.opf" media-type="application/oebps-package+xml"/></rootfiles></container>')

    # ┌── 설명 ──────────────────────────────────
    # │ ▶ 이 줄이 하는 일: 모양 파일. EPUB 에서는 쪽 크기(@page) 줄을 뺀다(리더가 화면에 맞춤).
    # └── ▼ 실행 코드 [90] ──────────────
    zc("OEBPS/style.css", css.replace("@page{size:A5;margin:18mm 16mm}", ""))

    # ┌── 설명 ──────────────────────────────────
    # │ ▶ 이 줄이 하는 일: items = 들어간 파일 목록, spine = 읽는 순서.
    # └── ▼ 실행 코드 [91] ──────────────
    items, spine = [], []

    # ┌── 설명 ──────────────────────────────────
    # │ ▶ 이 줄이 하는 일: 표지 쪽 내용: 그림이 <svg 로 시작하면 그림, 아니면 글자 표지.
    # └── ▼ 실행 코드 [92] ──────────────
    cov_inner = f'<div class="cover">{svg}</div>' if svg.startswith("<svg") else text_cover

    # ┌── 설명 ──────────────────────────────────
    # │ ▶ 이 줄이 하는 일: 표지 쪽을 넣고, 목록(items)과 읽는 순서(spine) 맨 앞에 적는다.
    # │   properties="svg" : 그 쪽에 SVG 그림이 들어 있다는 표시(EPUB 규칙).
    # └── ▼ 실행 코드 [93] ──────────────
    zc("OEBPS/cover.xhtml", xhtml(title, cov_inner)); items.append('<item id="cover" href="cover.xhtml" media-type="application/xhtml+xml"' + (' properties="svg"' if svg.startswith("<svg") else '') + '/>'); spine.append('<itemref idref="cover"/>')

    # ┌── 설명 ──────────────────────────────────
    # │ ▶ 이 줄이 하는 일: 전자책 차례 목록. 장마다 <li><a href="ch1.xhtml">장 제목</a></li>
    # └── ▼ 실행 코드 [94] ──────────────
    navl = "".join(f'<li><a href="ch{i}.xhtml">{html.escape(t)}</a></li>' for i, (t, _) in enumerate(chapters, 1))

    # ┌── 설명 ──────────────────────────────────
    # │ ▶ 이 줄이 하는 일: 차례 쪽을 넣는다. epub:type="toc" 가 리더의 "목차" 단추와 연결된다.
    # └── ▼ 실행 코드 [95] ──────────────
    zc("OEBPS/nav.xhtml", f'<?xml version="1.0" encoding="utf-8"?><!DOCTYPE html><html xmlns="http://www.w3.org/1999/xhtml" xmlns:epub="http://www.idpf.org/2007/ops" xml:lang="ko" lang="ko"><head><meta charset="utf-8"/><title>차례</title></head><body><nav epub:type="toc" id="toc"><h2>차례</h2><ol>{navl}</ol></nav></body></html>')

    # ┌── 설명 ──────────────────────────────────
    # │ ▶ 이 줄이 하는 일: 차례 쪽을 목록과 읽는 순서에 적는다.
    # └── ▼ 실행 코드 [96] ──────────────
    items.append('<item id="nav" href="nav.xhtml" media-type="application/xhtml+xml" properties="nav"/>'); spine.append('<itemref idref="nav"/>')

    # ┌── 설명 ──────────────────────────────────
    # │ ▶ 이 줄이 하는 일: 장마다 아래 두 줄.
    # └── ▼ 실행 코드 [97] ──────────────
    for i, (t, h) in enumerate(chapters, 1):

        # ┌── 설명 ──────────────────────────────────
        # │ ▶ 이 줄이 하는 일: 장 하나를 ch1.xhtml, ch2.xhtml … 로 넣는다.
        # └── ▼ 실행 코드 [98] ──────────────
        zc(f"OEBPS/ch{i}.xhtml", xhtml(t, fix(h)))

        # ┌── 설명 ──────────────────────────────────
        # │ ▶ 이 줄이 하는 일: 그 장을 목록과 읽는 순서에 적는다.
        # └── ▼ 실행 코드 [99] ──────────────
        items.append(f'<item id="ch{i}" href="ch{i}.xhtml" media-type="application/xhtml+xml"/>'); spine.append(f'<itemref idref="ch{i}"/>')

    # ┌── 설명 ──────────────────────────────────
    # │ ▶ 이 줄이 하는 일: style.css 도 목록에 적는다.
    # └── ▼ 실행 코드 [100] ─────────────
    items.append('<item id="css" href="style.css" media-type="text/css"/>')

    # ┌── 설명 ──────────────────────────────────
    # │ ▶ 이 줄이 하는 일: 지금 시각(세계 표준시). 예) 2026-11-10T02:15:00Z (EPUB 필수 정보 "고친 때")
    # └── ▼ 실행 코드 [101] ─────────────
    mod = datetime.datetime.now(datetime.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")

    # ┌── 설명 ──────────────────────────────────
    # │ ▶ 이 줄이 하는 일: 책 정보(번호·제목·저자·언어 ko·고친 때) + 파일 목록 + 읽는 순서를 담은 핵심 파일.
    # │   dc:title / dc:creator : 제목 / 저자.
    # └── ▼ 실행 코드 [102] ─────────────
    zc("OEBPS/content.opf", f'<?xml version="1.0" encoding="utf-8"?><package xmlns="http://www.idpf.org/2007/opf" version="3.0" unique-identifier="bookid" xml:lang="ko"><metadata xmlns:dc="http://purl.org/dc/elements/1.1/"><dc:identifier id="bookid">{uid}</dc:identifier><dc:title>{html.escape(title)}</dc:title><dc:creator>{html.escape(author)}</dc:creator><dc:language>ko</dc:language><meta property="dcterms:modified">{mod}</meta></metadata><manifest>{"".join(items)}</manifest><spine>{"".join(spine)}</spine></package>')

# ━━━━━━━━━━ 구역 7  결과 알림 (Python 끝) ━━━━━━━━━━

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 본문 글자 수(태그와 공백을 뺀 수)를 센다.
# │   <[^>]+> : HTML 태그.
# │   \s      : 공백·줄바꿈.
# └── ▼ 실행 코드 [103] ─────────────
n = sum(len(re.sub(r"\s", "", re.sub(r"<[^>]+>", "", h))) for _, h in chapters)

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 결과를 찍는다. 예) ✅ 제본 완료: 「느린 아침의 기술」 5개 장, 약 12,345자
# │   {n:,} : 천 단위 쉼표.
# └── ▼ 실행 코드 [104] ─────────────
print(f"✅ 제본 완료: 「{title}」 {len(chapters)}개 장, 약 {n:,}자")

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: HTML 파일 위치를 찍는다.
# └── ▼ 실행 코드 [105] ─────────────
print(f"   📄 {ddir}/book.html")

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: EPUB 파일 위치를 찍는다.
# └── ▼ 실행 코드 [106] ─────────────
print(f"   📱 {ddir}/book.epub  ← 전자책 리더·리디·교보 eBook 등록용")

PY

# ━━━━━━━━━━ 구역 8  book.pdf 만들기 (bash) ━━━━━━━━━━

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: dist 폴더 경로를 DIST 에 담고, 예전 PDF 는 지운다(실패했을 때 옛 PDF 가 남지 않게).
# │   rm -f : 파일 지우기. -f = 없어도 오류 없음.
# └── ▼ 실행 코드 [107] ─────────────
DIST="$BOOK_DIR/dist"; rm -f "$DIST/book.pdf"

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: Windows Edge 위치를 담을 변수. 처음엔 비워 둔다.
# └── ▼ 실행 코드 [108] ─────────────
EDGE=""

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: Edge 가 있을 만한 두 위치를 차례로 본다. (/mnt/c = 우분투에서 본 Windows C: 드라이브)
# └── ▼ 실행 코드 [109] ─────────────
for p in "/mnt/c/Program Files (x86)/Microsoft/Edge/Application/msedge.exe" "/mnt/c/Program Files/Microsoft/Edge/Application/msedge.exe"; do

  # ┌── 설명 ──────────────────────────────────
  # │ ▶ 이 줄이 하는 일: 그 위치에 파일이 있으면 EDGE 에 담고 찾기를 멈춘다.
  # └── ▼ 실행 코드 [110] ─────────────
  [ -f "$p" ] && EDGE="$p" && break

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 위 for / while 반복의 끝
# └── ▼ 실행 코드 [111] ─────────────
done

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: Edge 를 찾았으면 Edge 로 PDF 를 만든다(아래 3줄).
# └── ▼ 실행 코드 [112] ─────────────
if [ -n "$EDGE" ]; then

  # ┌── 설명 ──────────────────────────────────
  # │ ▶ 이 줄이 하는 일: Windows 쪽 임시 폴더를 만들고 book.html 을 복사한다.
  # │   Edge 는 Windows 프로그램이라 Windows 폴더의 파일만 잘 연다.
  # │   W        : Windows 임시 폴더 = C:\Users\Public\ai-publisher-tmp
  # │   mkdir -p : 폴더 만들기. -p = 이미 있어도 괜찮음.
  # └── ▼ 실행 코드 [113] ─────────────
  W=/mnt/c/Users/Public/ai-publisher-tmp; mkdir -p "$W" && cp "$DIST/book.html" "$W/book.html" && rm -f "$W/book.pdf"

  # ┌── 설명 ──────────────────────────────────
  # │ ▶ 이 줄이 하는 일: Edge 를 창 없이(--headless) 띄워 book.html 을 PDF 로 인쇄한다. 120초가 넘으면 멈춘다.
  # │   (줄 끝 \ = 다음 줄과 한 명령)
  # │   timeout 120            : 120초 제한.
  # │   --headless             : 화면에 창을 띄우지 않는다.
  # │   --disable-gpu          : 그래픽 카드를 쓰지 않는다(창 없을 때 오류 방지).
  # │   --no-pdf-header-footer : PDF 쪽 위아래에 날짜·주소가 찍히지 않게.
  # │   --print-to-pdf=…       : 이 위치에 PDF 로 저장.
  # │   'file:///C:/…'         : 열 HTML 파일 주소(Windows 형식).
  # └── ▼ 실행 코드 [114] (아래 2줄이 한 덩어리) ────
  timeout 120 "$EDGE" --headless --disable-gpu --no-pdf-header-footer \
    --print-to-pdf='C:\Users\Public\ai-publisher-tmp\book.pdf' 'file:///C:/Users/Public/ai-publisher-tmp/book.html' >/dev/null 2>&1

  # ┌── 설명 ──────────────────────────────────
  # │ ▶ 이 줄이 하는 일: PDF 가 만들어졌으면(크기 0 이 아니면) dist 폴더로 가져온다.
  # │   -s : 파일이 있고 크기가 0 보다 크면 참.
  # └── ▼ 실행 코드 [115] ─────────────
  [ -s "$W/book.pdf" ] && cp "$W/book.pdf" "$DIST/book.pdf"

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 조건이 거짓일 때 실행할 부분의 시작
# └── ▼ 실행 코드 [116] ─────────────
else

  # ┌── 설명 ──────────────────────────────────
  # │ ▶ 이 줄이 하는 일: Edge 가 없으면(리눅스 PC 등) Chromium·Chrome 을 차례로 찾는다.
  # └── ▼ 실행 코드 [117] ─────────────
  for b in chromium chromium-browser google-chrome /opt/pw-browsers/chromium-*/chrome-linux/chrome; do

    # ┌── 설명 ──────────────────────────────────
    # │ ▶ 이 줄이 하는 일: 그 이름의 명령이 있거나 실행 파일이면 아래로.
    # │   [ -x "$b" ] : 실행할 수 있는 파일이면 참.
    # └── ▼ 실행 코드 [118] ─────────────
    if command -v "$b" >/dev/null 2>&1 || [ -x "$b" ]; then

      # ┌── 설명 ──────────────────────────────────
      # │ ▶ 이 줄이 하는 일: Chromium 으로 같은 방식으로 PDF 를 만든다.
      # │   --no-sandbox : 보호 상자 기능을 끈다(일부 리눅스에서 필요).
      # └── ▼ 실행 코드 [119] (아래 2줄이 한 덩어리) ────
      timeout 120 "$b" --headless --no-sandbox --disable-gpu --no-pdf-header-footer \
        --print-to-pdf="$DIST/book.pdf" "file://$DIST/book.html" >/dev/null 2>&1

      # ┌── 설명 ──────────────────────────────────
      # │ ▶ 이 줄이 하는 일: 하나로 만들었으면 더 찾지 않는다.
      # └── ▼ 실행 코드 [120] ─────────────
      break

    # ┌── 설명 ──────────────────────────────────
    # │ ▶ 이 줄이 하는 일: 위 if 블록의 끝 (if 를 거꾸로 쓴 말)
    # └── ▼ 실행 코드 [121] ─────────────
    fi

  # ┌── 설명 ──────────────────────────────────
  # │ ▶ 이 줄이 하는 일: 위 for / while 반복의 끝
  # └── ▼ 실행 코드 [122] ─────────────
  done

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 위 if 블록의 끝 (if 를 거꾸로 쓴 말)
# └── ▼ 실행 코드 [123] ─────────────
fi

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: PDF 가 생겼는지 보고 결과를 알린다.
# └── ▼ 실행 코드 [124] ─────────────
if [ -s "$DIST/book.pdf" ]; then

  # ┌── 설명 ──────────────────────────────────
  # │ ▶ 이 줄이 하는 일: PDF 위치를 찍는다.
  # └── ▼ 실행 코드 [125] ─────────────
  echo "   📕 $DIST/book.pdf"

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 조건이 거짓일 때 실행할 부분의 시작
# └── ▼ 실행 코드 [126] ─────────────
else

  # ┌── 설명 ──────────────────────────────────
  # │ ▶ 이 줄이 하는 일: PDF 를 못 만들었으면 직접 만드는 방법을 알린다(브라우저에서 인쇄 → PDF로 저장).
  # └── ▼ 실행 코드 [127] ─────────────
  echo "   (PDF 건너뜀 — book.html을 열어 인쇄 → PDF로 저장하세요)"

# ┌── 설명 ──────────────────────────────────
# │ ▶ 이 줄이 하는 일: 위 if 블록의 끝 (if 를 거꾸로 쓴 말)
# └── ▼ 실행 코드 [128] ─────────────
fi
