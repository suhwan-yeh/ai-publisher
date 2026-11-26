/*
 * [1] 역할
 *     사무실·회의실 화면이 함께 쓰는 공용 자바스크립트다. 직원 정보(한글 이름·역할·색)와 사람 그림(SVG)을 만든다.
 *     다 만든 것을 window.Publisher 에 넣어 두면 office.js, meeting.js 가 P = window.Publisher 로 꺼내 쓴다.
 *     페이지가 열리면 GET /api/staff 로 직원 명부를 한 번 읽는다.
 *
 * [2] 받는 것 → 내보내는 것 (실제로 실행해서 얻은 값)
 *     요청  GET /api/staff
 *     응답  200 (실제 응답)
 *       [{"name":"team-lead","korean":"쭌","role":"편집장","team":"lead","color":"#f08a5d"},
 *        {"name":"minjun","korean":"민준","role":"기획","team":"book","color":"#5b8cff"}, …,
 *        {"name":"tepo","korean":"테포","role":"배포·서버","team":"ops","color":"#3ec6e0"}]
 *     결과  Publisher.person("tepo") → {ko:"테포", role:"배포·서버", color:"#3ec6e0", team:"ops", hair:"#262230"}
 *           Publisher.ago("2026-11-09T21:02:42.256Z") → "5시간 전"   Publisher.clock("2026-11-09T21:02:42.256Z") → "21:02" (UTC 브라우저)
 *
 * [3] 앞뒤 파일
 *     templates/office.html, meeting.html 이 이 파일을 office.js·meeting.js 보다 먼저 불러온다
 *     (이 파일)  →  api/OfficeApiController.java 의 staff()  (GET /api/staff, 직원 명부 staff.yml)
 *     (이 파일)  →  static/js/office.js (backView), static/js/meeting.js (topView)
 *
 * [4] 메서드 목록
 *     함수                           하는 일                                           예
 *     person(이름, 한글, 역할)          직원 정보 객체. 처음 보는 이름이면 남은 색을 준다     person("minjun") → {ko:"민준", color:"#5b8cff", …}
 *     el(태그, 속성, 부모)              SVG 요소 하나 만들기                               el('circle', {r:5}) → <circle r="5">
 *     backView(p)                      사무실: 모니터를 보는 뒷모습 SVG
 *     topView(부모, p, x, y, 글)        회의실: 위에서 본 모습 SVG
 *     clock(iso), ago(iso)             "21:02",  "5시간 전"
 *     ready                            직원 명부를 다 읽으면 끝나는 Promise
 *
 * [5] 먼저 알 용어 (자세한 설명: docs/용어-풀이.md)
 *     즉시 실행 함수, 객체 {키: 값}, Object.keys, document.createElementNS(SVG), setAttribute, for…in, fetch·Promise, window 전역 객체
 *
 * [6] 읽는 순서
 *     맨 아래 ready·window.Publisher → person() → el() → backView() → topView() → ago()
 *
 * [7] 다 읽고 확인
 *     - /api/staff 가 실패하면 사무실 화면은 그려지는가? (그려진다. .catch 가 [] 를 돌려주고 PEOPLE 기본값을 쓴다)
 *     - SVG 요소를 document.createElement 로 만들면 왜 화면에 보이지 않는가? (SVG 이름공간 NS 가 필요하다)
 */
/* =====================================================================
   people.js — 출판사 사람들(색·머리 모양)과 SVG 아바타 그리기
   사무실은 "어깨 너머로 본 뒷모습", 회의실은 "위에서 본 모습"
   ===================================================================== */
// 즉시 실행 함수: 안의 변수(PEOPLE 등)를 밖에서 직접 건드리지 못하게 한다. 밖에 내놓을 것만 맨 아래 window.Publisher 에 넣는다.
(function () {
  'use strict';

  // PEOPLE: 이름 → 사람 정보. 직원 명부를 읽기 전의 기본값이다. color = 옷 색, hair = 머리 색, long = 긴 머리.
  var PEOPLE = {
    'team-lead': { ko: '쭌', role: '편집장', color: '#f08a5d', hair: '#2b2118' },
    minjun: { ko: '민준', role: '기획', color: '#5b8cff', hair: '#1d1d24' },
    jihun: { ko: '지훈', role: '자료 조사', color: '#3fbf8f', hair: '#3b2a1d' },
    seoyeon: { ko: '서연', role: '집필', color: '#b07cff', hair: '#2a1712', long: true },
    taeyang: { ko: '태양', role: '교정·표지', color: '#ffb547', hair: '#5b3b1b' }
  };
  // 기본값에 없는 새 직원(예: 테포, 신입)에게 차례로 줄 색.
  var EXTRA = ['#3ec6e0', '#ff7eb6', '#9ad14b', '#e6d36a'];
  var SKIN = '#f1c9a8';
  // SVG 이름공간. SVG 요소는 이 값을 주고 createElementNS 로 만들어야 그림으로 보인다.
  var NS = 'http://www.w3.org/2000/svg';

  /** 이름으로 사람 정보 (처음 보는 사람은 색을 정해 줌) */
  // 이름으로 사람 정보를 돌려준다. 같은 이름이면 늘 같은 객체를 돌려주므로 색이 바뀌지 않는다.
  function person(name, ko, role) {
    if (!PEOPLE[name]) {
      // Object.keys(PEOPLE).length = 지금까지 아는 사람 수. 기본 5명을 빼면 새로 온 사람의 순서.
      // 예) 테포가 처음이면 n=0 → EXTRA[0] = "#3ec6e0"   (명부에 color 가 있으면 아래 ready 에서 그 색으로 바꾼다)
      var n = Object.keys(PEOPLE).length - 5;
      PEOPLE[name] = { ko: ko || name, role: role || '', color: EXTRA[Math.max(0, n) % EXTRA.length], hair: '#262230' };
    }
    var p = PEOPLE[name];
    // 한글 이름·역할이 주어지면 덮어쓴다(직원 명부 값이 우선).
    if (ko) p.ko = ko;
    if (role) p.role = role;
    return p;
  }

  // SVG 요소를 만든다.
  // (1) createElementNS(NS, tag)   예) tag='circle'
  // (2) for (var k in attrs)        객체의 키마다  예) {cx:55, cy:41, r:5.2} → setAttribute('cx', 55) …
  // (3) parent 가 있으면 그 안에 붙인다.
  function el(tag, attrs, parent) {
    var e = document.createElementNS(NS, tag);
    for (var k in attrs) e.setAttribute(k, attrs[k]);
    if (parent) parent.appendChild(e);
    return e;
  }

  /** 사무실: 책상에 앉아 모니터를 보는 뒷모습 (viewBox 150×104) */
  // 사무실 책상의 사람(뒷모습). 팔 g 에 class arm-l·arm-r·raise 를 주어 office.css 가 상태마다 다른 팔을 보이고 움직인다.
  function backView(p) {
    // viewBox '0 0 150 104': 그림 안의 좌표 범위(가로 150, 세로 104). 실제 크기는 CSS 가 정하고 그림은 비율대로 늘어난다.
    // aria-hidden: 화면 읽기 프로그램이 이 그림을 건너뛰게 한다(꾸밈 그림).
    var svg = el('svg', { viewBox: '0 0 150 104', 'class': 'person', 'aria-hidden': 'true' });
    var shirt = p.color;
    // 키보드
    el('rect', { x: 40, y: 36, width: 70, height: 8, rx: 3, fill: '#2b3247' }, svg);
    el('rect', { x: 44, y: 38, width: 62, height: 3, rx: 1.5, fill: '#3a435e' }, svg);
    // 팔 (어깨에서 키보드로)
    var al = el('g', { 'class': 'arm-l' }, svg);
    el('path', { d: 'M40 84 C30 66 38 50 54 42', stroke: shirt, 'stroke-width': 13, 'stroke-linecap': 'round', fill: 'none' }, al);
    el('circle', { cx: 55, cy: 41, r: 5.2, fill: SKIN }, al);
    var ar = el('g', { 'class': 'arm-r' }, svg);
    el('path', { d: 'M110 84 C120 66 112 50 96 42', stroke: shirt, 'stroke-width': 13, 'stroke-linecap': 'round', fill: 'none' }, ar);
    el('circle', { cx: 95, cy: 41, r: 5.2, fill: SKIN }, ar);
    // 손 든 팔 (허용 기다림)
    // 손 든 팔. 평소에는 숨기고, 허용 기다림(.s-WAITING) 상태에서만 CSS 가 보인다.
    var raise = el('g', { 'class': 'raise' }, svg);
    el('path', { d: 'M112 82 C128 64 132 40 128 20', stroke: shirt, 'stroke-width': 13, 'stroke-linecap': 'round', fill: 'none' }, raise);
    el('circle', { cx: 128, cy: 16, r: 6, fill: SKIN }, raise);
    // 몸통
    var body = el('g', { 'class': 'body' }, svg);
    el('path', { d: 'M28 106 C28 82 48 70 75 70 C102 70 122 82 122 106 Z', fill: shirt }, body);
    el('path', { d: 'M28 106 C28 82 48 70 75 70 C102 70 122 82 122 106 Z', fill: 'none', stroke: 'rgba(0,0,0,.18)', 'stroke-width': 1 }, body);
    el('path', { d: 'M60 72 Q75 80 90 72', stroke: 'rgba(0,0,0,.22)', 'stroke-width': 3, fill: 'none', 'stroke-linecap': 'round' }, body);
    // 머리 (뒷모습)
    var head = el('g', { 'class': 'head' }, svg);
    el('rect', { x: 68, y: 56, width: 14, height: 16, rx: 5, fill: SKIN }, head);
    el('ellipse', { cx: 56.5, cy: 50, rx: 3.5, ry: 5, fill: SKIN }, head);
    el('ellipse', { cx: 93.5, cy: 50, rx: 3.5, ry: 5, fill: SKIN }, head);
    el('circle', { cx: 75, cy: 46, r: 19, fill: p.hair }, head);
    if (p.long) el('path', { d: 'M57 48 C56 66 62 76 75 78 C88 76 94 66 93 48 Z', fill: p.hair }, head);
    el('path', { d: 'M63 36 C68 30 80 29 87 35', stroke: 'rgba(255,255,255,.14)', 'stroke-width': 3, fill: 'none', 'stroke-linecap': 'round' }, head);
    return svg;
  }

  /** 회의실: 위에서 본 모습. (x, y) 자리에 그룹을 만들어 돌려줌 */
  // 회의실 원탁의 자리 하나. translate(x,y)로 원탁 둘레의 (x, y)에 놓는다. 말하는 사람은 meeting.js 가 class 를 붙여 고리(ring)를 빛나게 한다.
  function topView(parent, p, x, y, label) {
    var g = el('g', { 'class': 'seat', transform: 'translate(' + x + ',' + y + ')' }, parent);
    var inner = el('g', { 'class': 'in' }, g);
    el('circle', { 'class': 'ring', cx: 0, cy: 0, r: 36, fill: 'none', stroke: p.color, 'stroke-width': 3 }, inner);
    el('circle', { 'class': 'ring2', cx: 0, cy: 0, r: 34, fill: 'none', stroke: p.color, 'stroke-width': 2, 'stroke-dasharray': '4 5' }, inner);
    el('ellipse', { cx: 0, cy: 6, rx: 30, ry: 22, fill: 'rgba(0,0,0,.35)' }, inner); // 의자
    var body = el('g', { 'class': 'body' }, inner);
    el('ellipse', { cx: 0, cy: 4, rx: 25, ry: 14, fill: p.color }, body);
    el('ellipse', { cx: 0, cy: 4, rx: 25, ry: 14, fill: 'none', stroke: 'rgba(0,0,0,.2)' }, body);
    el('circle', { cx: 0, cy: 0, r: 12.5, fill: p.hair }, body);
    if (p.long) el('ellipse', { cx: 0, cy: 6, rx: 11, ry: 9, fill: p.hair }, body);
    el('path', { d: 'M-6 -7 Q0 -11 6 -7', stroke: 'rgba(255,255,255,.18)', 'stroke-width': 2.4, fill: 'none', 'stroke-linecap': 'round' }, body);
    var t = el('text', { x: 0, y: 44, 'text-anchor': 'middle', fill: '#e9ecf5', 'font-size': 14, 'font-weight': 800 }, g);
    t.textContent = label || p.ko;
    var r = el('text', { x: 0, y: 60, 'text-anchor': 'middle', fill: '#9aa3bd', 'font-size': 11 }, g);
    r.textContent = p.role;
    return g;
  }

  function p2(n) { return ('0' + n).slice(-2); }
  // 시:분.  예) "2026-11-09T21:02:42.256Z" → UTC 브라우저 "21:02", 한국 브라우저 "06:02"
  function clock(iso) { if (!iso) return ''; var d = new Date(iso); return p2(d.getHours()) + ':' + p2(d.getMinutes()); }
  // 지금부터 얼마 전인지.  null 이면 "아직 없음".
  // (1) Date.now() - new Date(iso).getTime()   밀리초 차이
  // (2) / 1000 후 Math.round                   초.  예) 약 20000초 → 3600 이상 → Math.floor(20000/3600) = 5 → "5시간 전"
  function ago(iso) {
    if (!iso) return '아직 없음';
    var s = Math.max(0, Math.round((Date.now() - new Date(iso).getTime()) / 1000));
    if (s < 60) return s + '초 전';
    if (s < 3600) return Math.floor(s / 60) + '분 전';
    return Math.floor(s / 3600) + '시간 전';
  }

  /** 직원 명부(/api/staff)를 읽어 색·이름을 맞춘다. 못 읽으면 기본값으로 */
  var staffList = [];
  // 페이지가 열리자마자 직원 명부를 요청한다. ready 는 Promise 라서 다른 파일이 P.ready.then(…) 으로 "다 읽은 뒤"를 기다릴 수 있다.
  var ready = fetch('/api/staff')
    // 200 이면 JSON 배열, 아니면 빈 배열(기본값으로 그린다).
    .then(function (r) { return r.ok ? r.json() : []; })
    .then(function (list) {
      staffList = list;
      list.forEach(function (s) {
        // 명부의 한 사람.  s 예) {"name":"tepo","korean":"테포","role":"배포·서버","team":"ops","color":"#3ec6e0"}
        var p = person(s.name, s.korean, s.role);
        if (s.color) p.color = s.color;
        p.team = s.team;
      });
      return list;
    })
    .catch(function () { return []; });

  // window.Publisher: 브라우저 전역 객체 window 에 붙여 다른 JS 파일에서 쓸 수 있게 한다.
  // office.js 의 var P = window.Publisher; 가 이것을 꺼낸다.
  window.Publisher = { ready: ready, staff: function () { return staffList; }, person: person, backView: backView, topView: topView, svg: el, clock: clock, ago: ago,
    STAGES: ['주문 접수', '기획 완료', '집필 중', '교정 중', '표지 완료', '전자책 완성'] };
})();
