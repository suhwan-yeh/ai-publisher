/*
 * [1] 역할
 *     사무실 화면(/office)을 움직이는 자바스크립트다. 2초마다 GET /api/office 로 실제 데이터를 받아 그린다(흐름 E).
 *       - 직원마다 책상 하나: 상태(작업 중·대기·허용 기다림·자리 비움)에 따라 class 를 바꾸고, tmux 화면 글자를 모니터에 넣는다
 *       - 직원끼리 새 메시지: 보낸 책상 → 받는 책상으로 봉투를 날린다
 *       - 사장실 대화(chatpanel.js 의 chat:new 이벤트): 사장실 ↔ 쭌 책상으로 봉투를 날린다
 *
 * [2] 받는 것 → 내보내는 것 (실제로 실행해서 얻은 값)
 *     요청  GET /api/office?after=0
 *     응답  200 (실제 응답, 줄임)
 *       {"source":"기록","teamName":"session-2d8e941e",
 *        "book":{"id":2,"folder":"20261109-dinosaur","title":"20261109-dinosaur","stage":"기획 완료","stageIndex":1,"members":4,"expectedMembers":4,"peerTalk":4,"reports":6,"filesDelivered":false,…},
 *        "agents":[{"name":"team-lead","korean":"쭌","role":"편집장","team":"lead","status":"IDLE","statusLabel":"대기","screen":[],"lastActive":"2026-11-09T21:02:42.256Z","sent":0},
 *                  {"name":"minjun","korean":"민준","role":"기획","team":"book","status":"OFFLINE","statusLabel":"자리 비움","lastActive":null,"sent":0}, …],
 *        "messages":[…,{"id":153,"from":"tepo","fromKorean":"테포","to":"team-lead","toKorean":"쭌","text":"[보고] 준비 부족: …","category":"보고","at":"2026-11-09T21:02:36.357Z"}],
 *        "leadWaitingPermission":false,"now":"…"}
 *     화면  쭌 책상: <div class="desk s-IDLE" data-name="team-lead"> … <span class="pill">대기</span> …
 *           다음 요청은 GET /api/office?after=153 (받은 메시지 중 가장 큰 id)
 *
 * [3] 앞뒤 파일
 *     templates/office.html (책상을 넣을 빈 자리 #desks, #lead-slot, #ops-desks, #fx 등)  →  이 파일이 채운다
 *     static/js/people.js (window.Publisher: 직원 색·이름·뒷모습 그림)  →  (이 파일)
 *     (이 파일) poll()  →  api/OfficeApiController.java 의 office()  →  service/OfficeService.java  →  dto/OfficeResponse.java (JSON)
 *     static/js/chatpanel.js  →  'chat:new' 이벤트  →  (이 파일)
 *
 * [4] 메서드 목록
 *     함수                        하는 일                                                         흐름 번호
 *     buildDesk(a)                직원 한 명의 책상 요소를 처음 한 번 만든다                           흐름 E-⑧
 *     updateDesk(a, source)       책상의 상태·모니터 글자·아래 설명을 바꾼다                            흐름 E-⑧
 *     updateTop(j)                위쪽 책 제목·단계 막대·점검 표시                                    흐름 E-⑧
 *     updateRoster(agents)        아래쪽 직원 표                                                      흐름 E-⑧
 *     center, anchor              요소의 화면 위 가운데 좌표 {x, y}
 *     bubble(이름, 제목, 글)        책상 위에 3.4초 동안 말풍선
 *     fly(from, to, …)            봉투가 곡선을 따라 날아가는 움직임
 *     enqueue, next               봉투를 차례로 하나씩 날리는 대기열
 *     openScreen, refreshModal    책상을 누르면 그 사람의 실제 화면을 크게 (GET /api/office/screen/{이름})
 *     poll()                      2초마다 GET /api/office                                             흐름 E-②, E-⑧
 *
 * [5] 먼저 알 용어 (자세한 설명: docs/용어-풀이.md)
 *     즉시 실행 함수, fetch·.then·.catch·.finally, setTimeout, document.createElement·innerHTML·textContent,
 *     classList, dataset, style.setProperty(CSS 변수), addEventListener, CustomEvent(chat:new) 받기,
 *     getBoundingClientRect, requestAnimationFrame, Promise(P.ready)
 *
 * [6] 읽는 순서
 *     맨 아래 poll() → updateTop() → updateDesk() → buildDesk() → enqueue()·fly() → 나머지
 *
 * [7] 다 읽고 확인
 *     - 사무실 화면을 처음 열었을 때 이미 지난 메시지들은 봉투로 날아가는가? (아니다. poll() 의 first)
 *     - 쭌이 출근하지 않아 tmux 가 없으면 모니터에는 무엇이 보이는가? ("[대화 기록으로 보는 중]" + 마지막 활동)
 */
/* =====================================================================
   office.js — AI 출판사 사무실
   2초마다 fetch('/api/office?after=마지막메시지') 로 받은 실제 데이터로 화면을 움직입니다.
     - 책상 상태(작업 중·대기·허용 기다림·자리 비움) → 사람 동작
     - tmux 칸의 실제 글자 → 모니터
     - 직원끼리 새 메시지 → 보낸 책상에서 받는 책상으로 봉투가 날아감
     - 사장실 대화(chat:new) → 사장실 ↔ 편집장실 사이로 봉투가 날아감
   ===================================================================== */
// 즉시 실행 함수: 안의 변수가 이 파일 안에만 있게 한다(chatpanel.js 의 변수와 겹치지 않는다).
(function () {
  'use strict';
  // P: people.js 가 만들어 둔 공용 객체. 직원 색·이름(P.person), 단계 이름(P.STAGES), "몇 분 전"(P.ago) 등을 쓴다.
  var P = window.Publisher;
  // desks: 이름 → 책상 요소.  예) desks["team-lead"] = <div class="desk …">
  var desks = {};            // 이름 → 책상 요소
  // lastMsgId = 받은 메시지 중 가장 큰 id (다음 요청의 after=).  예) 153
  // first     = 화면을 연 뒤 첫 응답인가
  // latest    = 이름 → 가장 최근 직원 정보 a
  // openName  = 지금 크게 보고 있는 사람 이름 (없으면 null)
  var lastMsgId = 0, first = true, latest = {}, openName = null;
  // queue: 날릴 봉투 대기열 [[보낸 사람, 받는 사람, 제목, 글], …].  flying: 지금 봉투가 날고 있는가.
  var queue = [], flying = false;
  // 사용자가 운영체제에서 "움직임 줄이기"를 켰으면 true. 그러면 봉투를 날리지 않고 말풍선만 띄운다.
  var reduce = window.matchMedia && matchMedia('(prefers-reduced-motion: reduce)').matches;
  // $ 는 이름이 짧은 함수일 뿐이다.  $('desks') = document.getElementById('desks')
  var $ = function (id) { return document.getElementById(id); };

  /* ---------- 책상 만들기 ---------- */
  // [흐름 E-⑧] 책상 만들기. 이 사람의 책상이 아직 없을 때 한 번만 실행된다.
  // a 예) {"name":"minjun","korean":"민준","role":"기획","team":"book","status":"OFFLINE","statusLabel":"자리 비움",…}
  function buildDesk(a) {
    // p 예) {ko:"민준", role:"기획", color:"#5b8cff", …}  (색은 직원 명부의 값)
    var p = P.person(a.name, a.korean, a.role);
    var d = document.createElement('div');
    // 처음에는 자리 비움 모양. 곧 updateDesk 가 실제 상태로 바꾼다.
    d.className = 'desk s-OFFLINE';
    // tabIndex=0: Tab 키로 이 책상에 갈 수 있게 한다(키보드 사용자용).
    d.tabIndex = 0;
    // CSS 변수 --c 에 직원 색을 넣는다. office.css 가 var(--c) 로 그 색을 쓴다.  결과) style="--c:#5b8cff"
    d.style.setProperty('--c', p.color);
    d.dataset.name = a.name;
    // innerHTML: 글자를 HTML 로 해석해 안을 채운다. 여기에는 고정된 틀만 넣는다.
    // 사람마다 다른 글자(이름 등)는 아래에서 textContent 로 넣는다. 서버에서 온 글을 innerHTML 에 넣으면 그 안의 태그가 실행될 수 있기 때문이다.
    d.innerHTML =
      '<div class="desk-head"><span class="dot"></span><span class="nm"></span><span class="rl"></span><span class="pill"></span></div>' +
      '<div class="scene"><div class="lamp"></div><div class="monitor"><div class="screen"><pre></pre><div class="zzz">자리 비움</div></div></div>' +
      '<div class="chair"></div><div class="mug"></div></div>' +
      '<div class="desk-foot"><span class="task"></span><span class="act"></span><span class="meta"></span></div>';
    // querySelector('.nm'): d 안에서 class 가 nm 인 첫 요소.  결과) <span class="nm">민준</span>
    d.querySelector('.nm').textContent = p.ko;
    d.querySelector('.rl').textContent = p.role;
    // 의자에 앉은 뒷모습 그림(people.js)을 컵 앞에 끼워 넣는다.
    d.querySelector('.scene').insertBefore(P.backView(p), d.querySelector('.mug'));
    // 책상을 누르면 그 사람의 화면을 크게 연다.
    d.addEventListener('click', function () { openScreen(a.name); });
    d.addEventListener('keydown', function (e) { if (e.key === 'Enter' || e.key === ' ') { e.preventDefault(); openScreen(a.name); } });
    // 놓을 자리: 쭌 → 편집장실(#lead-slot),  테포(team "ops") → 서버실(#ops-desks, 숨겨 둔 방을 보이게),  나머지 → 팀 책상들(#desks)
    if (a.name === 'team-lead') $('lead-slot').appendChild(d);
    else if (a.team === 'ops') { $('ops-desks').appendChild(d); $('server-room').hidden = false; }
    else $('desks').appendChild(d);
    desks[a.name] = d;
    return d;
  }

  // [흐름 E-⑧] 2초마다 직원마다 실행된다.  source = "tmux"(실시간) 또는 "기록"(대화 기록만 있음)
  function updateDesk(a, source) {
    // 책상이 있으면 그것, 없으면 지금 만든다.
    var d = desks[a.name] || buildDesk(a);
    // 상태에 맞는 class.  예) status "IDLE" → "desk s-IDLE"
    // office.css 의 .s-WORKING(타자 치는 움직임), .s-IDLE, .s-WAITING(손 든 모양), .s-OFFLINE(빈 의자)가 모양을 정한다.
    d.className = 'desk s-' + a.status;
    // 상태 글자.  예) "대기", "자리 비움"
    d.querySelector('.pill').textContent = a.statusLabel;
    d.querySelector('.pill').title = a.spinner || '';
    var pre = d.querySelector('.screen pre');
    var text;
    // tmux 화면 글자 줄들을 줄바꿈으로 이어 모니터에 넣는다.  screen 예) ["✻ Writing… (12s)", "> manuscript/02.md 쓰는 중", …]
    if (a.screen && a.screen.length) text = a.screen.join('\n');
    // tmux 가 없으면(source "기록") 화면 글자가 없다. 대신 상태를 글로 적는다.
    // 예) "[대화 기록으로 보는 중]\n마지막 활동 5시간 전",  출근 전이면 "[대화 기록으로 보는 중]\n아직 출근 전"
    else if (source !== 'tmux') text = '[대화 기록으로 보는 중]\n' + (a.status === 'OFFLINE' ? '아직 출근 전' : '마지막 활동 ' + P.ago(a.lastActive));
    else text = '';
    // 글이 바뀌었을 때만 고친다. 같은 글을 계속 넣으면 스크롤 위치가 흔들린다.
    if (pre.textContent !== text) pre.textContent = text;
    d.querySelector('.task').textContent = a.task ? '맡은 일 · ' + a.task : (a.name === 'team-lead' ? '팀 지휘 · 사장님 보고' : '');
    d.querySelector('.act').textContent = a.activity ? '● ' + a.activity : (a.status === 'OFFLINE' ? '아직 자리에 없어요' : '');
    // 예) "보낸 메시지 0 · 마지막 활동 5시간 전"
    d.querySelector('.meta').textContent = '보낸 메시지 ' + a.sent + ' · 마지막 활동 ' + P.ago(a.lastActive);
  }

  /* ---------- 위쪽: 책 제목·단계·점검 ---------- */
  // [흐름 E-⑧] 위쪽: 지금 만드는 책과 단계, 점검 네 가지
  function updateTop(j) {
    var b = j.book;
    // 책 제목. 주문이 없으면(book 이 null) 안내 글.  예) "20261109-dinosaur" (title.txt 가 아직 없어 폴더 이름)
    $('bk-title').textContent = b ? b.title : '아직 주문이 없어요 — 오른쪽 사장실에서 주문해 보세요';
    var st = $('stages');
    // 단계 막대를 처음 한 번 만든다.  P.STAGES = ["주문 접수","기획 완료","집필 중","교정 중","표지 완료","전자책 완성"]
    if (!st.children.length) P.STAGES.forEach(function (s) { var e = document.createElement('span'); e.textContent = s; st.appendChild(e); });
    // st.children 은 배열이 아니라서 forEach 를 빌려 쓴다. i = 단계 순서(0부터).
    // i < stageIndex → "done"(지난 단계),  i === stageIndex → "now"(지금 단계).  예) stageIndex 1 → "주문 접수" done, "기획 완료" now
    Array.prototype.forEach.call(st.children, function (e, i) {
      e.className = !b ? '' : i < b.stageIndex ? 'done' : i === b.stageIndex ? 'now' : '';
    });
    var c = $('checks');
    // 점검 네 가지 [표시 글, 통과했나].  예) book 이 위 실제 응답이면
    //   ["① 팀원 4/4", true]  ["② 직원끼리 4", true]  ["③ 보고 6", true]  ["④ 파일 아직", false]
    var items = b ? [
      ['① 팀원 ' + b.members + '/' + b.expectedMembers, b.members >= b.expectedMembers], ['② 직원끼리 ' + b.peerTalk, b.peerTalk > 0],
      ['③ 보고 ' + b.reports, b.reports > 0], ['④ 파일 ' + (b.filesDelivered ? '도착' : '아직'), b.filesDelivered]] : [];
    // 안을 비운 뒤 다시 채운다.
    c.innerHTML = '';
    items.forEach(function (it) { var e = document.createElement('span'); e.textContent = it[0]; if (it[1]) e.className = 'on'; c.appendChild(e); });
    var src = $('source');
    // 실제 응답 source "기록" → "대화 기록으로 보는 중 (tmux 없음)"
    src.textContent = j.source === 'tmux' ? '실시간 · tmux 화면' : '대화 기록으로 보는 중 (tmux 없음)';
    src.className = 'source' + (j.source === 'tmux' ? ' live' : '');
    // 쭌이 도구 사용 허용을 기다리면 빨간 안내를 보인다.
    $('alert').classList.toggle('on', !!j.leadWaitingPermission);
  }

  // [흐름 E-⑧] 아래쪽 직원 표. 매번 비우고 줄(tr)을 새로 만든다.
  function updateRoster(agents) {
    var tb = $('roster');
    tb.innerHTML = '';
    agents.forEach(function (a) {
      var p = P.person(a.name);
      var tr = document.createElement('tr');
      // 한 줄의 칸 다섯 개.  예) ["민준 (기획)", "-", "자리 비움", "아직 없음", "0"]   (lastActive 가 null 이면 P.ago 가 "아직 없음")
      [p.ko + ' (' + p.role + ')', a.task || (a.name === 'team-lead' ? '팀 지휘' : '-'), a.statusLabel, P.ago(a.lastActive), String(a.sent)]
        .forEach(function (v, i) {
          var td = document.createElement('td');
          if (i === 0) { var sw = document.createElement('span'); sw.className = 'sw'; sw.style.background = p.color; td.appendChild(sw); }
          // createTextNode: 글자만 있는 노드. textContent 처럼 태그로 해석되지 않는다.
          td.appendChild(document.createTextNode(v));
          tr.appendChild(td);
        });
      tb.appendChild(tr);
    });
  }

  /* ---------- 봉투 날리기 ---------- */
  // getBoundingClientRect(): 요소의 화면 위 위치와 크기 {left, top, width, height}(px).
  // 돌려줌: 가로 가운데, 세로는 dy 비율(기본 0.5 = 가운데)의 좌표.  예) {x: 640, y: 210}
  function center(elm, dy) {
    var r = elm.getBoundingClientRect();
    return { x: r.left + r.width / 2, y: r.top + r.height * (dy == null ? 0.5 : dy) };
  }
  // 봉투가 출발·도착할 자리. 'boss' 는 오른쪽 사장실 패널(#cp) 위쪽, 나머지는 그 사람 책상. 모르는 이름이면 쭌 책상.
  function anchor(name) {
    if (name === 'boss') return center($('cp'), 0.15);
    var d = desks[name] || desks['team-lead'];
    return d ? center(d.querySelector('.scene'), 0.55) : null;
  }

  // 책상(또는 사장실) 위에 말풍선을 띄운다. 3.4초 뒤 사라진다.
  function bubble(name, title, text) {
    var target = name === 'boss' ? $('cp') : desks[name];
    if (!target) return;
    var r = target.getBoundingClientRect();
    var b = document.createElement('div');
    b.className = 'bubble';
    b.innerHTML = '<b></b><span></span>';
    b.firstChild.textContent = title;
    // 글이 90자보다 길면 앞 90자 + "…"
    b.lastChild.textContent = text.length > 90 ? text.slice(0, 90) + '…' : text;
    b.style.position = 'fixed';
    // 말풍선이 화면 밖으로 나가지 않게 왼쪽 위치를 8px ~ (화면 너비-240px) 사이로 맞춘다.
    b.style.left = Math.max(8, Math.min(window.innerWidth - 240, r.left + r.width / 2 - 110)) + 'px';
    b.style.top = Math.max(8, r.top + 34) + 'px';
    document.body.appendChild(b);
    // 3.4초 뒤 class out(사라지는 CSS 움직임)을 붙이고, 0.46초 뒤 요소를 지운다.
    setTimeout(function () { b.classList.add('out'); setTimeout(function () { b.remove(); }, 460); }, 3400);
  }

  // 봉투 날리기.  from·to = 이름 또는 'boss',  done = 다 날고 나서 부를 함수.
  function fly(from, to, title, text, done) {
    var a = anchor(from), b = anchor(to);
    // 자리를 못 찾거나 움직임 줄이기면 말풍선만 띄우고 끝.
    if (!a || !b || reduce) { bubble(to, title, text); done(); return; }
    var fx = $('fx');
    var env = document.createElement('div');
    env.className = 'envelope';
    // 봉투 모양 SVG 그림(사각형 + V 모양 선).
    env.innerHTML = '<svg viewBox="0 0 30 21" width="30" height="21"><rect x="1" y="1" width="28" height="19" rx="3" fill="#fff4e3" stroke="#f3b27a" stroke-width="1.5"/>' +
      '<path d="M2 3 L15 12 L28 3" fill="none" stroke="#e08560" stroke-width="1.6"/></svg>';
    fx.appendChild(env);
    // 곡선의 꼭짓점: 두 점의 가운데에서 위로 120px. 봉투가 위로 휘어 날아간다.
    var cx = (a.x + b.x) / 2, cy = Math.min(a.y, b.y) - 120;
    // 날아가는 시간 1.1초. 기다리는 봉투가 4개보다 많으면 0.65초로 빨리. performance.now() = 지금 시각(밀리초).
    var dur = queue.length > 4 ? 650 : 1100, t0 = performance.now(), n = 0;
    // 한 장면(frame)을 그린다. requestAnimationFrame 이 브라우저가 화면을 다시 그릴 때마다(보통 1초에 60번) 부른다.
    function step(now) {
      // t = 지난 시간의 비율 0 → 1.   e = 처음과 끝은 천천히, 가운데는 빠르게 바꾼 비율(ease-in-out).
      var t = Math.min(1, (now - t0) / dur), e = t < .5 ? 2 * t * t : 1 - Math.pow(-2 * t + 2, 2) / 2;
      // 2차 베지어 곡선 공식: 출발점 a, 꼭짓점 (cx, cy), 도착점 b 사이에서 비율 e 의 위치. e=0 이면 a, e=1 이면 b.
      var x = (1 - e) * (1 - e) * a.x + 2 * (1 - e) * e * cx + e * e * b.x;
      var y = (1 - e) * (1 - e) * a.y + 2 * (1 - e) * e * cy + e * e * b.y;
      // 봉투를 (x, y)로 옮기고, 처음에는 -12도 기울였다가 도착할 때 0도가 된다.
      env.style.transform = 'translate(' + x + 'px,' + y + 'px) rotate(' + ((1 - t) * -12) + 'deg)';
      // 세 장면마다 꼬리 점(trail)을 하나 남기고 0.7초 뒤 지운다.
      if (++n % 3 === 0) { var tr = document.createElement('div'); tr.className = 'trail'; tr.style.left = x + 'px'; tr.style.top = y + 'px'; fx.appendChild(tr); setTimeout(function () { tr.remove(); }, 700); }
      // 아직 도착하지 않았으면 다음 장면을 예약하고 끝낸다.
      if (t < 1) return requestAnimationFrame(step);
      env.remove();
      // 도착: 봉투를 지우고 도착 자리에 퍼지는 원(ping)과 말풍선을 띄운다.
      var pg = document.createElement('div'); pg.className = 'ping'; pg.style.left = b.x + 'px'; pg.style.top = b.y + 'px';
      fx.appendChild(pg); setTimeout(function () { pg.remove(); }, 900);
      bubble(to, title, text);
      done();
    }
    requestAnimationFrame(step);
  }

  // 봉투를 대기열 끝에 넣는다. 날고 있는 봉투가 없으면 바로 next().
  function enqueue(from, to, title, text) {
    queue.push([from, to, title, text]);
    if (!flying) next();
  }
  // 대기열 맨 앞 봉투를 꺼내 날린다. 다 날면 0.35초 뒤 다음 봉투. 대기열이 비면 flying=false.
  function next() {
    var job = queue.shift();
    if (!job) { flying = false; return; }
    flying = true;
    fly(job[0], job[1], job[2], job[3], function () { setTimeout(next, 350); });
  }

  /* ---------- 확대 보기 ---------- */
  // 책상을 누르면 확대 창(#modal)을 열고 그 사람의 화면을 가져온다.
  function openScreen(name) {
    openName = name;
    $('modal').classList.add('on');
    refreshModal();
    $('m-close').focus();
  }
  function refreshModal() {
    if (!openName) return;
    var p = P.person(openName);
    $('m-title').textContent = p.ko + ' (' + p.role + ') 의 화면';
    // encodeURIComponent: 주소에 넣을 수 있는 글자로 바꾼다.  예) "seoyeon" → "seoyeon",  "쭌" → "%EC%AD%8C"
    // 요청 예) GET /api/office/screen/seoyeon   tmux 가 없으면 404 + {"message":"…"}
    fetch('/api/office/screen/' + encodeURIComponent(openName))
      // 성공이든 404 든 몸통 JSON 을 읽어 {ok, j} 로 묶는다(chatpanel.js 의 send 와 같은 방법).
      // [흐름 E-⑧] j = 위 [2] 의 실제 응답 객체. 받은 값으로 화면을 고친다.
      .then(function (r) { return r.json().then(function (j) { return { ok: r.ok, j: j }; }); })
      .then(function (res) {
        var term = $('m-term');
        var stick = term.scrollHeight - term.scrollTop - term.clientHeight < 40;
        if (res.ok) {
          $('m-status').textContent = res.j.statusLabel;
          // 200 이면 실제 화면 줄들.  ScreenResponse 의 lines
          term.textContent = res.j.lines.join('\n');
        } else {
          $('m-status').textContent = '';
          var a = latest[openName];
          // 404 면 서버가 보낸 안내 글 + 대화 기록으로 아는 마지막 활동.
          term.textContent = res.j.message + (a ? '\n\n마지막 활동: ' + P.ago(a.lastActive) + '\n보낸 메시지: ' + a.sent : '');
        }
        if (stick) term.scrollTop = term.scrollHeight;
      }).catch(function () {});
  }
  function closeModal() { openName = null; $('modal').classList.remove('on'); }
  $('m-close').addEventListener('click', closeModal);
  $('modal').addEventListener('click', function (e) { if (e.target === $('modal')) closeModal(); });
  // Esc 키로 확대 창 닫기.
  document.addEventListener('keydown', function (e) { if (e.key === 'Escape') closeModal(); });

  /* ---------- 사장실 대화 → 봉투 ---------- */
  // chatpanel.js 가 보낸 'chat:new' 이벤트를 받는다. e.detail = 메시지 객체.
  // 예) e.detail = {"id":103,"fromBoss":true,"text":"좋아요, 이대로 진행해 주세요.",…} → 사장실 → 쭌 책상으로 "사장님 → 쭌" 봉투
  document.addEventListener('chat:new', function (e) {
    var m = e.detail;
    if (m.fromBoss) enqueue('boss', 'team-lead', '사장님 → 쭌', m.text);
    else enqueue('team-lead', 'boss', '쭌 → 사장님', m.text);
  });

  /* ---------- 2초마다 새 데이터 ---------- */
  // [흐름 E-②] 2초마다 서버에 사무실 데이터를 요청한다. 다음 차례는 서버의 OfficeApiController.office() (흐름 E-③).
  function poll() {
    // 요청 예) 처음 GET /api/office?after=0,  그 뒤 GET /api/office?after=153
    fetch('/api/office?after=' + lastMsgId)
      // 200 이 아니면 .catch 로. 200 이면 몸통 JSON 을 객체로.
      .then(function (r) { if (!r.ok) throw new Error(r.status); return r.json(); })
      .then(function (j) {
        updateTop(j);
        // 직원마다 책상 고치기. agents 는 쭌, 민준, 지훈, 서연, 태양, 테포 순.
        j.agents.forEach(function (a) { latest[a.name] = a; updateDesk(a, j.source); });
        updateRoster(j.agents);
        j.messages.forEach(function (m) {
          // 가장 큰 id 를 기억해 다음 요청에서 그 뒤의 메시지만 받는다.
          lastMsgId = Math.max(lastMsgId, m.id);
          // forEach 안의 return 은 "이 메시지는 건너뛰기"(continue 와 같은 뜻)다.
          if (first) return; // 처음 열었을 때 지난 메시지는 날리지 않음
          // 받는 사람의 책상이 없으면 쭌 책상으로.
          var to = m.to && desks[m.to] ? m.to : 'team-lead';
          // 예) 테포 책상 → 쭌 책상, 제목 "테포 → 쭌 · 보고"
          enqueue(m.from, to, m.fromKorean + ' → ' + m.toKorean + ' · ' + m.category, m.text || '');
        });
        // 처음 열었을 때는 봉투 대신 마지막 대화 하나만 0.6초 뒤 말풍선으로 보여 준다.
        if (first && j.messages.length) {
          var last = j.messages[j.messages.length - 1];
          setTimeout(function () { bubble(last.to && desks[last.to] ? last.to : 'team-lead', '마지막 대화 · ' + last.fromKorean + ' → ' + last.toKorean, last.text || ''); }, 600);
        }
        first = false;
        if (openName) refreshModal();
      })
      // 서버에 연결하지 못하면 위쪽 표시에 알린다.
      .catch(function () { $('source').textContent = '관리 화면과 연결이 끊겼어요'; })
      // 성공·실패와 상관없이 2초 뒤 다시 poll(). (chatpanel.js 의 3초 폴링과 같은 방법)
      .finally(function () { setTimeout(poll, 2000); });
  }
  // P.ready: people.js 가 GET /api/staff 로 직원 명부를 다 읽으면 끝나는 Promise. 끝난 뒤 첫 poll() 을 부른다.
  // 없으면: 직원 색·이름을 모르는 채로 책상을 그리게 된다.
  P.ready.then(poll); // 직원 명부를 읽은 뒤 시작
})();
