/*
 * [1] 역할
 *     회의실 화면(/meeting)을 움직이는 자바스크립트다. 원탁 둘레에 직원 자리를 두고, 팀원끼리 주고받은 메시지를 차례로 보여 준다.
 *       - 실시간: 3초마다 GET /api/meeting?after=마지막번호 → 새 메시지를 한 사람씩 말하게 한다
 *       - 다시 보기: GET /api/meeting?bookId=책번호 → 그 책의 회의 전체를 1×·2×·4× 빠르기로 재생한다
 *     사무실(office.js)과 같은 방법(fetch → JSON → 화면 고치기 → setTimeout 으로 다시)을 쓴다. 흐름 E 와 같은 길이다.
 *
 * [2] 받는 것 → 내보내는 것 (실제로 실행해서 얻은 값)
 *     다시 보기 요청  GET /api/meeting?bookId=3
 *     응답 200 (실제 응답, 줄임)
 *       {"teamName":"session-bbaed2ce","bookId":3,"bookTitle":"꼬리 살랑, 첫 산책","stage":"전자책 완성",
 *        "chapters":["1장. 나가기 전에 알아 둘 것","2장. 첫 10분 산책","3장. 날씨와 매일 하는 산책"],"live":false,
 *        "messages":[{"id":91,"from":"minjun","fromKorean":"민준","to":"jihun","toKorean":"지훈","text":"지훈, 민준이야. 강아지 산책 …","category":"의논","at":"2026-11-09T20:22:00.024Z"}, … 28개],
 *        "bossNotes":[{"id":99,"fromBoss":true,"text":"퇴근길 10분 동안 읽을 수 있는 짧은 시집 하나 만들어 볼까?",…}, …]}
 *     없는 책  GET /api/meeting?bookId=999 → 404 {"status":404,"code":"NOT_FOUND","message":"책을 찾을 수 없어요.",…}
 *
 * [3] 앞뒤 파일
 *     templates/meeting.html (원탁 SVG #seats·#beams, 화이트보드 #wb-*, 회의록 #mlog, 다시 보기 단추 #rp-*)
 *     static/js/people.js (P.person, P.topView, P.clock)  →  (이 파일)
 *     (이 파일)  →  api/OfficeApiController.java 의 meeting()  →  service/OfficeService.java  →  dto/MeetingResponse.java
 *     (이 파일)  →  api/BookApiController.java (GET /api/books: 다시 보기 책 목록)
 *
 * [4] 메서드 목록
 *     함수                          하는 일
 *     spot(이름), seat(이름, 한글)    원탁 위 자리 좌표와 사람 그림 (한 번만 만든다)
 *     seatTeam()                    처음 자리: 쭌 + 책 팀 4명
 *     whiteboard(j)                 화이트보드: 책 제목·단계·목차·사장님 메모 2개
 *     minute(m, now)                회의록 한 줄 추가
 *     clearStage(), speak(m, …)      한 사람이 말하는 장면 (커지는 자리, 빛줄기, 말풍선)
 *     play(), enqueue(list)          대기열의 메시지를 한 개씩 말하게 한다
 *     setState(live)                "회의 중 / 회의 쉬는 중 / 다시 보기 중" 표시
 *     poll()                        3초마다 GET /api/meeting?after=
 *     loadBooks()                   GET /api/books → 다시 보기 고르기 칸
 *     (이벤트 등록)                   다시 보기·실시간으로·빠르기 단추
 *
 * [5] 먼저 알 용어 (자세한 설명: docs/용어-풀이.md)
 *     즉시 실행 함수, fetch·.then·.catch·.finally, setTimeout·clearTimeout, 배열 shift·concat·filter·slice, classList, SVG path(Q 곡선), encodeURIComponent
 *
 * [6] 읽는 순서
 *     맨 아래 P.ready.then(…) → poll() → enqueue() → play() → speak() → minute() → whiteboard() → 다시 보기 단추
 *
 * [7] 다 읽고 확인
 *     - 다시 보기 중에도 3초 폴링은 계속되는가? (아니다. poll() 첫 줄 mode !== 'live' 에서 멈춘다)
 *     - 2× 단추를 누르면 한 사람이 말하는 시간은 어떻게 바뀌는가? (setTimeout(done, ms / speed) → 절반)
 */
/* =====================================================================
   meeting.js — 팀 회의실
   실시간: 3초마다 fetch('/api/meeting?after=마지막') → 새 메시지를 차례로 연출
   다시 보기: fetch('/api/meeting?bookId=책') → 그 책의 회의 전체를 1×·2×·4× 로 재생
   연출: 말하는 사람이 커지며 빛나고, 듣는 사람에게 빛줄기, 말풍선, 회의록 한 줄
   ===================================================================== */
// 즉시 실행 함수: 이 파일의 변수가 다른 JS 파일과 섞이지 않게 한다.
(function () {
  'use strict';
  // people.js 가 만든 공용 객체.
  var P = window.Publisher;
  var $ = function (id) { return document.getElementById(id); };
  // 원탁 SVG 의 viewBox 크기. 말풍선 위치를 % 로 바꿀 때 쓴다.
  var VB = { w: 640, h: 440 };
  // SPOTS: 이름 → 원탁 위 자리 좌표 [x, y]. 쭌은 위 가운데(320, 78), 네 명은 왼쪽·오른쪽 위아래.
  var SPOTS = { 'team-lead': [320, 78], minjun: [112, 168], jihun: [128, 336], seoyeon: [512, 336], taeyang: [528, 168] };
  // 그 밖의 사람(예: 테포)이 말하면 원탁 아래쪽 자리에 차례로 앉힌다.
  var EXTRA_SPOTS = [[320, 400], [214, 404], [426, 404]];
  // seats   이름 → 자리 SVG 요소              lastId  받은 메시지 중 가장 큰 id.  예) 153
  // mode    'live'(실시간) 또는 'replay'(다시 보기)     speed  1, 2, 4
  // queue   말할 차례를 기다리는 메시지 배열   playing·paused  재생 중인가·멈췄는가     timer  지금 말하는 장면의 setTimeout 번호
  var seats = {}, lastId = 0, mode = 'live', speed = 1, queue = [], playing = false, paused = false, timer = null;
  var reduce = window.matchMedia && matchMedia('(prefers-reduced-motion: reduce)').matches;

  function spot(name) {
    // 처음 보는 이름이면 남은 자리를 준다. % (나머지)로 세 자리를 돌려 쓴다.
    if (!SPOTS[name]) SPOTS[name] = EXTRA_SPOTS[(Object.keys(SPOTS).length - 5) % EXTRA_SPOTS.length];
    return SPOTS[name];
  }
  function seat(name, ko) {
    if (seats[name]) return seats[name];
    var p = P.person(name, ko);
    var s = spot(name);
    // people.js 의 topView 가 위에서 본 사람 그림을 #seats 안 (x, y)에 그린다.
    seats[name] = P.topView($('seats'), p, s[0], s[1]);
    return seats[name];
  }
  // 처음 자리: 쭌 + 책 팀. 다른 팀(예: 서버실 테포)은 회의에서 말하면 그때 자리가 생김
  function seatTeam() {
    // P.staff() = /api/staff 로 읽은 직원 명부. 못 읽었으면 기본 다섯 명.
    var list = P.staff();
    if (!list.length) list = [{ name: 'team-lead' }, { name: 'minjun' }, { name: 'jihun' }, { name: 'seoyeon' }, { name: 'taeyang' }];
    // 책 팀과 쭌만 처음부터 앉힌다. 테포(team "ops")는 회의에서 말할 때 자리가 생긴다.
    list.filter(function (s) { return !s.team || s.team === 'lead' || s.team === 'book'; }).forEach(function (s) { seat(s.name, s.korean); });
  }

  /* ---------- 화이트보드 ---------- */
  // 화이트보드를 채운다.  j 예) bookTitle "꼬리 살랑, 첫 산책", stage "전자책 완성", chapters 3개
  function whiteboard(j) {
    $('wb-title').textContent = j.bookTitle || '아직 회의 주제가 없어요';
    var sn = $('wb-stage');
    // hidden = true 면 요소를 숨긴다. 단계가 없으면 숨긴다.
    sn.hidden = !j.stage; sn.textContent = j.stage || '';
    var ol = $('wb-ch'); ol.innerHTML = '';
    if (j.chapters && j.chapters.length) j.chapters.forEach(function (c) { var li = document.createElement('li'); li.textContent = c; ol.appendChild(li); });
    else { var li = document.createElement('li'); li.textContent = '목차는 원고가 나오면 적혀요'; li.style.listStyle = 'none'; li.style.color = '#777'; ol.appendChild(li); }
    var notes = $('wb-notes'); notes.innerHTML = '';
    // slice(-2): 배열의 마지막 2개.  사장님 말 중 최근 두 개를 메모지(📌)로 붙인다. 70자가 넘으면 줄인다.
    (j.bossNotes || []).slice(-2).forEach(function (n) {
      var d = document.createElement('div'); d.className = 'sticky';
      d.textContent = '📌 사장님: ' + (n.text.length > 70 ? n.text.slice(0, 70) + '…' : n.text);
      notes.appendChild(d);
    });
  }

  /* ---------- 회의록 ---------- */
  // 회의록에 한 줄을 더한다.  now = true 면 "지금 말하는 줄" 표시(.now).
  // 결과 예) 민준 → 지훈 [의논]  20:22
  //          지훈, 민준이야. 강아지 산책 첫 시작하는 보호자가 …
  function minute(m, now) {
    var log = $('mlog');
    var p = P.person(m.from, m.fromKorean);
    var row = document.createElement('div');
    row.className = 'mrow' + (now ? ' now' : '');
    row.style.setProperty('--c', p.color);
    row.innerHTML = '<div class="who"></div><div class="txt"></div>';
    var who = row.firstChild;
    who.appendChild(document.createTextNode(m.fromKorean + ' → ' + m.toKorean + ' '));
    // 분류 표시.  예) class="cat cat-의논" 글자 "의논"  (보고·의논·지시 등은 서버의 TeamMessageResponse.category)
    var cat = document.createElement('span'); cat.className = 'cat cat-' + m.category; cat.textContent = m.category; who.appendChild(cat);
    var t = document.createElement('i'); t.textContent = '  ' + P.clock(m.at); who.appendChild(t);
    row.lastChild.textContent = m.text || '';
    // 앞줄들의 "지금" 표시를 떼고 새 줄에만 남긴다.
    log.querySelectorAll('.mrow.now').forEach(function (r) { r.classList.remove('now'); });
    log.appendChild(row);
    log.scrollTop = log.scrollHeight;
  }

  /* ---------- 말하기 연출 ---------- */
  // 앞 장면을 지운다: 모든 자리에서 speak·listen class 를 떼고, 빛줄기·말풍선을 비운다.
  function clearStage() {
    Object.keys(seats).forEach(function (k) { seats[k].classList.remove('speak', 'listen'); });
    $('beams').innerHTML = '';
    $('mbubbles').innerHTML = '';
  }

  // 한 메시지를 "말하는 장면"으로 보여 준다.  done = 장면이 끝나면 부를 함수,  noLog = true 면 회의록에 적지 않는다.
  function speak(m, done, noLog) {
    clearStage();
    var from = seat(m.from, m.fromKorean), toName = seats[m.to] ? m.to : 'team-lead';
    var to = seat(toName, m.toKorean);
    // 말하는 사람 자리에 class speak → office.css 의 회의실 구역(.seat.speak)이 자리를 키우고 빛나게 한다. 듣는 사람은 listen.
    from.classList.add('speak');
    if (toName !== m.from) to.classList.add('listen');
    var a = spot(m.from), b = spot(toName), p = P.person(m.from);
    if (toName !== m.from) {
      // 빛줄기: SVG path 의 d 속성.  M x y = 시작점,  Q 320 228 x2 y2 = 원탁 가운데(320, 228)로 휘어 끝점까지 가는 곡선.
      // 예) 민준(112,168) → 지훈(128,336):  d="M112 168 Q 320 228 128 336"
      var path = P.svg('path', { 'class': 'beam', stroke: p.color, d: 'M' + a[0] + ' ' + a[1] + ' Q 320 228 ' + b[0] + ' ' + b[1] }, $('beams'));
      path.style.opacity = .85;
    }
    // 말풍선 (말하는 사람 근처)
    var wrap = $('tablewrap'), bub = document.createElement('div');
    bub.className = 'mbubble';
    bub.innerHTML = '<b></b><span></span>';
    bub.firstChild.textContent = m.fromKorean + ' → ' + m.toKorean;
    var tag = document.createElement('span'); tag.className = 'tag cat-' + m.category; tag.textContent = m.category; bub.firstChild.appendChild(tag);
    var text = m.text || '';
    // 말풍선 글은 140자까지.
    bub.lastChild.textContent = text.length > 140 ? text.slice(0, 140) + '…' : text;
    // 말하는 사람 좌표를 화면 비율(%)로.  예) 민준 x=112 → 112/640*100 = 17.5%
    var leftPct = a[0] / VB.w * 100, topPct = a[1] / VB.h * 100;
    bub.style.left = Math.max(2, Math.min(56, leftPct - 20)) + '%';
    // 원탁 위쪽 사람이면 말풍선을 그 아래에, 아래쪽 사람이면 그 위에 둔다.
    if (a[1] < 220) bub.style.top = (topPct + 12) + '%'; else bub.style.bottom = (100 - topPct + 12) + '%';
    bub.style.borderTop = '3px solid ' + p.color;
    $('mbubbles').appendChild(bub);
    if (!noLog) minute(m, true);
    // 장면 길이: 2.2초 + 글자당 0.022초, 많아야 6.5초.  예) 100자 → 2200 + 2200 = 4400ms
    var ms = reduce ? 1200 : Math.min(6500, 2200 + text.length * 22);
    // 빠르기만큼 줄인다.  예) 4400ms, 2× → 2200ms 뒤 done()
    timer = setTimeout(done, ms / speed);
  }

  // 대기열 맨 앞 메시지를 꺼내 말하게 하고, 끝나면 0.25초 쉬고 다음 메시지. 대기열이 비면 멈춘다.
  function play() {
    if (paused) return;
    // shift(): 배열의 맨 앞을 꺼내고 지운다. 비어 있으면 undefined.
    var m = queue.shift();
    if (!m) {
      playing = false;
      if (mode === 'replay') { $('mstate').textContent = '다시 보기 끝'; }
      return;
    }
    playing = true;
    speak(m, function () { setTimeout(play, 250 / speed); });
  }
  // concat: 두 배열을 이은 새 배열. 재생 중이 아니면 바로 시작한다.
  function enqueue(list) { queue = queue.concat(list); if (!playing) play(); }

  /* ---------- 실시간 ---------- */
  // 위쪽 상태 표시.  live 는 응답의 live 값(최근에 팀원끼리 대화가 있었는가).  실제 응답 live=false → "회의 쉬는 중"
  function setState(live) {
    var s = $('mstate');
    if (mode === 'replay') { s.className = 'mstate replay'; s.textContent = '다시 보기 중 · ' + speed + '×'; return; }
    s.className = 'mstate' + (live ? ' live' : '');
    s.textContent = live ? '회의 중' : '회의 쉬는 중';
    $('tablewrap').classList.toggle('idle-room', !live);
  }

  var firstLoad = true;
  // 실시간 모드에서 3초마다 새 회의 메시지를 요청한다.
  function poll() {
    // 다시 보기 중이면 요청하지 않는다.
    if (mode !== 'live') return;
    // 요청 예) 처음 GET /api/meeting?after=0,  그 뒤 GET /api/meeting?after=153
    fetch('/api/meeting?after=' + lastId)
      .then(function (r) { if (!r.ok) throw new Error(r.status); return r.json(); })
      .then(function (j) {
        if (mode !== 'live') return;
        whiteboard(j);
        setState(j.live);
        // 처음 열었을 때: 지난 회의록은 장면 없이 바로 적고(minute(m, false)), 마지막 한 마디만 말풍선으로 보여 준다.
        // 그 뒤 응답에서 새 메시지가 오면 enqueue 로 한 명씩 말하게 한다.
        if (firstLoad) {
          // 처음 열면 지난 회의록은 바로 적고, 마지막 한 마디만 보여 줌
          j.messages.forEach(function (m) { minute(m, false); lastId = Math.max(lastId, m.id); });
          if (j.messages.length) speak(j.messages[j.messages.length - 1], function () {}, true);
          firstLoad = false;
        } else if (j.messages.length) {
          j.messages.forEach(function (m) { lastId = Math.max(lastId, m.id); });
          enqueue(j.messages);
        }
      })
      .catch(function () { $('mstate').textContent = '관리 화면과 연결이 끊겼어요'; })
      // 실시간 모드일 때만 3초 뒤 다시 poll().
      .finally(function () { if (mode === 'live') setTimeout(poll, 3000); });
  }

  /* ---------- 다시 보기 ---------- */
  // GET /api/books 로 책 목록을 받아 다시 보기 고르기 칸(<select id="rp-book">)에 넣는다.
  // 결과 예) <option value="3">꼬리 살랑, 첫 산책 (직원끼리 11)</option>
  function loadBooks() {
    fetch('/api/books').then(function (r) { return r.json(); }).then(function (books) {
      var sel = $('rp-book');
      books.forEach(function (b) { var o = document.createElement('option'); o.value = b.id; o.textContent = b.title + ' (직원끼리 ' + b.peerTalk + ')'; sel.appendChild(o); });
      if (books.length) sel.value = books[0].id;
    }).catch(function () {});
  }
  // "▶ 다시 보기" 단추. 재생 중에 누르면 멈춤/이어서.
  $('rp-play').addEventListener('click', function () {
    var id = $('rp-book').value;
    if (!id) return;
    if (mode === 'replay' && playing) { // 일시정지·이어서
      paused = !paused;
      $('rp-play').textContent = paused ? '▶ 이어서' : '⏸ 멈춤';
      if (!paused) play();
      return;
    }
    // 요청 예) GET /api/meeting?bookId=3  (encodeURIComponent: 주소에 넣을 수 있는 글자로 바꾼다)
    fetch('/api/meeting?bookId=' + encodeURIComponent(id))
      .then(function (r) { return r.json().then(function (j) { return { ok: r.ok, j: j }; }); })
      .then(function (res) {
        // 404 등이면 서버의 오류 문장을 보여 준다.  예) "책을 찾을 수 없어요."
        if (!res.ok) { $('mstate').textContent = res.j.message; return; }
        // 다시 보기 모드로 바꾸고, 지금 장면의 setTimeout 을 취소하고(clearTimeout), 대기열을 비운다.
        mode = 'replay'; paused = false; clearTimeout(timer); queue = [];
        $('mlog').innerHTML = ''; clearStage();
        whiteboard(res.j); setState(false);
        $('rp-live').hidden = false; $('rp-play').textContent = '⏸ 멈춤';
        // 그 책의 회의 메시지 전체(예: 28개)를 차례로 재생한다.
        enqueue(res.j.messages);
      });
  });
  // "실시간으로" 단추: 처음 연 상태로 되돌리고 poll() 을 다시 시작한다.
  $('rp-live').addEventListener('click', function () {
    mode = 'live'; paused = false; clearTimeout(timer); queue = []; playing = false;
    $('mlog').innerHTML = ''; clearStage(); lastId = 0; firstLoad = true;
    $('rp-live').hidden = true; $('rp-play').textContent = '▶ 다시 보기';
    poll();
  });
  document.querySelectorAll('[data-speed]').forEach(function (b) {
    b.addEventListener('click', function () {
      // data-speed="2" 의 글자 "2" 를 숫자 2 로.
      speed = +b.dataset.speed;
      document.querySelectorAll('[data-speed]').forEach(function (x) { x.classList.toggle('on', x === b); });
      if (mode === 'replay') setState(false);
    });
  });

  // 직원 명부를 다 읽은 뒤 자리 배치 → 책 목록 → 첫 poll().
  P.ready.then(function () { seatTeam(); loadBooks(); poll(); });
})();
