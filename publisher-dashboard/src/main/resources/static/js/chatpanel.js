/*
 * [1] 역할
 *     대화 패널(대화방 /chat 과 사무실 /office 오른쪽)에서 브라우저 쪽 동작을 맡는 자바스크립트다.
 *       - 보내기 버튼(submit 이벤트) → fetch 로 POST /api/chat → 응답 JSON 으로 말풍선을 그린다        흐름 B
 *       - 3초마다 GET /api/chat?after=마지막번호 → 새 메시지를 그린다                                 흐름 B′
 *       - 400·503 응답이면 응답 JSON 의 message 를 빨간 글로 보여 준다                                흐름 D-④
 *     페이지를 새로 받지 않고 화면 일부만 바꾼다. HTML 의 처음 말풍선은 서버(타임리프 fragments.html)가 그렸다.
 *
 * [2] 받는 것 → 내보내는 것 (실제로 실행해서 얻은 값)
 *     보내기 (흐름 B) 실제 요청과 응답
 *       요청  POST /api/chat
 *             Content-Type: application/json
 *             {"text":"좋아요, 이대로 진행해 주세요."}
 *       응답  HTTP/1.1 201
 *             Location: /api/chat/103
 *             {"id":103,"fromBoss":true,"text":"좋아요, 이대로 진행해 주세요.","at":"2026-11-09T21:46:33.776008Z","channel":"web","files":[]}
 *       화면  <div class="cp-msg boss-m" data-id="103"><small>사장님 · 11-09 21:46</small><span class="t">좋아요, 이대로 진행해 주세요.</span></div>
 *     폴링 (흐름 B′)
 *       요청  GET /api/chat?after=102
 *       응답  200  {"online":true,"messages":[{"id":103,"fromBoss":true,…}]}
 *     오류 (흐름 D-④)
 *       응답  400  {"status":400,"code":"VALIDATION","message":"보낼 말을 적어 주세요.",…}  → 빨간 글 "보낼 말을 적어 주세요."
 *
 * [3] 앞뒤 파일
 *     templates/fragments.html 의 chatPanel 조각(id="cp" …)  ←  이 파일이 그 요소를 찾아 움직인다
 *     (이 파일)  →  api/ChatApiController.java (POST/GET /api/chat),  api/OfficeApiController.java (GET /api/office/status)
 *     (이 파일)  →  document 에 'chat:new' 이벤트  →  static/js/office.js 가 받아 봉투를 날린다
 *
 * [4] 메서드 목록
 *     함수                 하는 일                                                          흐름 번호
 *     p2(n), time(iso)     시각 글자 만들기               예) "2026-11-09T21:46:33.776008Z" → "11-09 21:46"
 *     lastId()             화면의 마지막 말풍선 번호       예) 103
 *     render(m)            메시지 객체 하나 → 말풍선 div 하나                                  흐름 B-⑦
 *     updateDecide()       마지막 말이 쭌의 [제안]이면 승인·수정·거부 버튼을 보인다
 *     status(on)           "🟢 쭌과 연결됨 / 🔴 쭌이 출근 전이에요" 표시
 *     notify(text)         탭 제목 깜빡임 + 알림음
 *     poll()               3초마다 새 메시지 가져오기                                         흐름 B′-①, B′-⑤
 *     pollPermission()     6초마다 "쭌이 허용을 기다리는지" 가져오기
 *     send(text)           POST /api/chat 보내고 결과에 따라 그리거나 오류 표시                  흐름 B-①, B-⑦, D-④
 *     (이벤트 등록)         submit, keydown(Enter), click(버튼·칩), visibilitychange             흐름 B-①
 *
 * [5] 먼저 알 용어 (자세한 설명: docs/용어-풀이.md)
 *     즉시 실행 함수 (function(){…})(), 'use strict', document.getElementById, addEventListener, preventDefault,
 *     fetch, Promise·.then·.catch·.finally, response.ok·status·json(), JSON.stringify, createElement·textContent·appendChild,
 *     dataset(data-* 속성), classList, setTimeout, CustomEvent·dispatchEvent, 정규식 .test()
 *
 * [6] 읽는 순서
 *     맨 아래 "이벤트 등록" 부분(submit) → send() → render() → poll() → 나머지 함수
 *
 * [7] 다 읽고 확인
 *     - 보내기 버튼을 눌렀을 때 ev.preventDefault() 가 없으면 무슨 일이 생기는가? (폼이 페이지를 새로 받아 버려 fetch 결과를 그리지 못한다)
 *     - 내가 보낸 말이 send() 로 그려진 뒤 3초 뒤 poll() 에서 같은 메시지가 또 오면 말풍선이 두 개가 되는가? (아니다. render() 첫 줄)
 */
/* =====================================================================
   chatpanel.js — 사장실 대화 패널 (대화방 /chat 과 사무실 오른쪽 공용)
   비동기 요청은 fetch API 만 사용합니다.
     GET  /api/chat?after={id}   3초마다 새 메시지
     POST /api/chat              보내기 → 201 이면 성공, 400·503 이면 ErrorResponse.message 를 보여 줌
     GET  /api/office/status     6초마다 "쭌이 허용을 기다리는지"
   새 메시지가 오면 document 에 'chat:new' 이벤트를 보냅니다 (사무실이 봉투 애니메이션에 씀).
   ===================================================================== */
// 즉시 실행 함수: function(){…} 을 만들자마자 () 로 실행한다.
//   결과   : 안의 var 변수들이 이 함수 안에만 있다. 다른 JS 파일(office.js 등)의 변수와 이름이 겹치지 않는다.
(function () {
  // 'use strict': 엄격 모드. 선언하지 않은 변수에 값을 넣는 실수 같은 것을 오류로 알려 준다.
  'use strict';
  // document.getElementById('cp')
  //   뜻     : HTML 에서 id="cp" 인 요소를 찾는다.
  //   결과   : 대화 패널의 바깥 <section id="cp"> 요소. 없으면 null.
  var root = document.getElementById('cp');
  // 대화 패널이 없는 화면(예: 첫 화면 /)에서는 아무것도 하지 않고 끝낸다.
  if (!root) return;

  // 화면 요소들을 미리 찾아 둔다.
  //   log = 말풍선 목록,  tx = 입력칸 <textarea>,  err = 빨간 오류 글
  var log = document.getElementById('cp-log'), tx = document.getElementById('cp-tx'), err = document.getElementById('cp-err');
  // st = 연결 표시,  decide = 승인·수정·거부 버튼 줄,  decideQ = 그 위의 질문 글
  var st = document.getElementById('cp-st'), decide = document.getElementById('cp-decide'), decideQ = document.getElementById('cp-decide-q');
  // perm = "쭌이 허용을 기다려요" 안내,  bell = 알림음 켜기/끄기 버튼
  var perm = document.getElementById('cp-perm'), bell = document.getElementById('cp-bell');
  // KEY: 정규식. 글 안에 "[제안]", "[최종 보고]", "[배포 제안]" 중 하나가 있는지 본다.
  // 예) KEY.test("[제안] 제목 후보 세 가지입니다") → true,   KEY.test("접수했습니다.") → false
  var KEY = /\[(제안|최종 보고|배포 제안)\]/;
  var soundOn = true, baseTitle = document.title, blinkTimer = null;
  // localStorage: 브라우저에 작은 값을 저장해 두는 곳. 새로고침해도 남는다.
  // 알림음을 끈 적이 있으면('off') soundOn=false. 저장소를 쓸 수 없는 브라우저면 catch 로 넘어가 기본값 true.
  try { soundOn = localStorage.getItem('publisher:sound') !== 'off'; } catch (e) { /* 저장소 못 쓰면 기본값 */ }

  // 숫자를 두 자리 글자로.  예) p2(9) → '09',  p2(21) → '21'
  function p2(n) { return ('0' + n).slice(-2); }
  // (1) new Date(iso)                  ISO 글자를 Date 객체로.  예) "2026-11-09T21:46:33.776008Z"
  // (2) getMonth()+1, getDate() …      브라우저 시간대의 월·일·시·분 (getMonth 는 0부터 세므로 +1)
  // (3) 결과 "MM-dd HH:mm"              예) UTC 브라우저 "11-09 21:46", 한국 브라우저 "11-10 06:46"
  function time(iso) { if (!iso) return ''; var d = new Date(iso); return p2(d.getMonth() + 1) + '-' + p2(d.getDate()) + ' ' + p2(d.getHours()) + ':' + p2(d.getMinutes()); }
  // (1) log.querySelectorAll('.cp-msg[data-id]')   data-id 가 있는 말풍선 전부
  // (2) m[m.length - 1].dataset.id                 마지막 말풍선의 data-id 글자.  예) "103"
  // (3) +"103"                                     앞의 + 는 글자를 숫자로 바꾼다 → 103.  말풍선이 없으면 0.
  function lastId() { var m = log.querySelectorAll('.cp-msg[data-id]'); return m.length ? +m[m.length - 1].dataset.id : 0; }
  // 스크롤이 맨 아래 근처(90px 안)에 있으면 true. 사장님이 위로 올려 옛 메시지를 읽는 중이면 새 메시지가 와도 아래로 끌어내리지 않는다.
  function nearBottom() { return log.scrollHeight - log.scrollTop - log.clientHeight < 90; }
  function bottom() { log.scrollTop = log.scrollHeight; }

  /** 메시지 하나를 그린다 (서버가 처음 그린 모양과 같게) */
  // [흐름 B-⑦] 메시지 객체 하나를 말풍선으로 그린다.
  // 받는 것 m 예) {"id":103,"fromBoss":true,"text":"좋아요, 이대로 진행해 주세요.","at":"2026-11-09T21:46:33.776008Z","channel":"web","files":[]}
  // 돌려줌  : 새로 만든 div, 이미 화면에 있으면 null
  function render(m) {
    // 같은 번호의 말풍선이 이미 있으면 그리지 않는다.  찾는 글자 예) .cp-msg[data-id="103"]
    // send() 가 그린 메시지가 poll() 로 한 번 더 와도 두 번 그려지지 않는다.
    if (log.querySelector('.cp-msg[data-id="' + m.id + '"]')) return null;
    // "아직 대화가 없어요" 안내가 있으면 지운다.
    var empty = document.getElementById('cp-empty'); if (empty) empty.remove();
    // document.createElement('div')
    //   뜻     : 새 <div> 요소를 만든다. 아직 화면에 붙지 않았다(아래 log.appendChild 에서 붙인다).
    var d = document.createElement('div');
    // class 를 정한다.
    // (1) 'cp-msg '                              모든 말풍선 공통
    // (2) m.fromBoss ? 'boss-m' : 'lead-m'       사장님 말은 오른쪽(boss-m), 쭌의 말은 왼쪽(lead-m)
    // (3) 쭌의 말에 [제안] 등이 있으면 ' key'     눈에 띄는 색
    // 예) 사장님 103번 → "cp-msg boss-m"
    d.className = 'cp-msg ' + (m.fromBoss ? 'boss-m' : 'lead-m') + (!m.fromBoss && KEY.test(m.text || '') ? ' key' : '');
    // dataset.id = HTML 속성 data-id.  결과: <div class="cp-msg boss-m" data-id="103">
    d.dataset.id = m.id;
    var s = document.createElement('small');
    // textContent: 요소 안의 글자를 넣는다. 글자 그대로 넣으므로 <b> 같은 태그를 써도 태그로 해석되지 않는다(안전).
    // 예) "사장님 · 11-09 21:46",  텔레그램으로 온 말이면 "사장님 · 텔레그램 · 11-09 10:06"
    s.textContent = (m.fromBoss ? '사장님' : '쭌 편집장') + (m.channel === 'telegram' ? ' · 텔레그램' : '') + ' · ' + time(m.at);
    // appendChild: s 를 d 의 마지막 자식으로 붙인다.
    d.appendChild(s);
    // 본문 <span class="t">좋아요, 이대로 진행해 주세요.</span>
    var t = document.createElement('span'); t.className = 't'; t.textContent = m.text || ''; d.appendChild(t);
    // 첨부 파일마다 내려받기 링크를 만든다. files 가 없으면 빈 배열로 본다.
    // f 예) {"name":"book.pdf","url":"/chat/57/file/0"}  → <a class="cp-file" href="/chat/57/file/0">⬇ book.pdf</a>
    (m.files || []).forEach(function (f) {
      var w = document.createElement('div'); var a = document.createElement('a');
      a.className = 'cp-file'; a.href = f.url; a.textContent = '⬇ ' + f.name; w.appendChild(a); d.appendChild(w);
    });
    // 완성한 말풍선을 목록 맨 아래에 붙인다. 이 순간 화면에 보인다.
    log.appendChild(d);
    return d;
  }

  /** 마지막 메시지가 쭌의 [제안]·[최종 보고]면 승인·수정·거부 버튼을 보여 준다 */
  // 마지막 말풍선이 쭌의 [제안]·[최종 보고]·[배포 제안]이면 승인·수정·거부 버튼 줄을 보인다.
  function updateDecide() {
    var all = log.querySelectorAll('.cp-msg');
    var last = all[all.length - 1];
    // (1) last                              말풍선이 하나라도 있고
    // (2) classList.contains('lead-m')      쭌의 말이고
    // (3) KEY.test(…)                       [제안] 등이 들어 있으면
    // !! 는 결과를 true/false 로 바꾼다.
    var show = !!(last && last.classList.contains('lead-m') && KEY.test(last.textContent));
    // classList.toggle('on', show): show 가 true 면 class on 을 붙이고, false 면 뗀다. CSS 가 .on 일 때만 보이게 한다.
    decide.classList.toggle('on', show);
    if (show) {
      // match(KEY)[1] = 괄호 안에 맞은 글자.  예) "[제안] 제목 후보…" → "제안"
      var k = last.textContent.match(KEY)[1];
      decideQ.textContent = '쭌이 [' + k + ']에 대한 답을 기다려요';
    }
  }

  // 연결 표시를 바꾼다. on 은 응답 JSON 의 online 값(true/false).
  function status(on) {
    st.className = 'st ' + (on ? 'on' : 'off');
    st.textContent = on ? '🟢 쭌과 연결됨' : '🔴 쭌이 출근 전이에요';
  }

  /** 알림: 탭 제목 깜빡임 + 짧은 알림음 */
  // 쭌의 [제안] 등이 새로 오면 부른다. 다른 탭을 보고 있어도 알 수 있게 탭 제목을 깜빡이고 소리를 낸다.
  function notify(text) {
    var k = (text.match(KEY) || [])[0] || '새 보고';
    clearInterval(blinkTimer);
    var on = false, n = 0;
    // setInterval(함수, 900): 0.9초마다 함수를 계속 부른다. clearInterval 로 멈춘다.
    // 제목이 "🔔 제안 도착" ↔ 원래 제목 으로 번갈아 바뀐다. 20번이 지나거나, 이 탭을 보고 있으면 6번 뒤 멈춘다.
    blinkTimer = setInterval(function () {
      document.title = (on = !on) ? '🔔 ' + k + ' 도착' : baseTitle;
      if (++n > 20 || (!document.hidden && n > 6)) { clearInterval(blinkTimer); document.title = baseTitle; }
    }, 900);
    if (!soundOn) return;
    try {
      // AudioContext: 브라우저에서 소리를 만드는 기능. 660Hz, 880Hz 두 음을 0.18초 간격으로 짧게 낸다.
      var ac = new (window.AudioContext || window.webkitAudioContext)();
      [660, 880].forEach(function (f, i) {
        var o = ac.createOscillator(), g = ac.createGain();
        o.type = 'sine'; o.frequency.value = f; o.connect(g); g.connect(ac.destination);
        var t0 = ac.currentTime + i * 0.18;
        g.gain.setValueAtTime(0.0001, t0); g.gain.exponentialRampToValueAtTime(0.18, t0 + 0.02); g.gain.exponentialRampToValueAtTime(0.0001, t0 + 0.32);
        o.start(t0); o.stop(t0 + 0.34);
      });
    } catch (e) { /* 소리를 못 내도 괜찮음 */ }
  }

  // [흐름 B′-①] 폴링: 3초마다 서버에 "새 메시지 있나요?" 하고 묻는다. 다음 차례는 서버의 ChatApiController.poll() (흐름 B′-②).
  // 쭌의 답장은 쭌이 대화 기록에 남긴 것을 서버가 읽어(흐름 F) DB 에 넣은 것이므로, 브라우저가 물어봐야 알 수 있다.
  function poll() {
    // fetch(주소)
    //   뜻     : 자바스크립트에서 HTTP 요청을 보낸다. 방식을 적지 않으면 GET.
    //   받는 것: 주소 예) "/api/chat?after=102"
    //   결과   : Promise(나중에 응답이 오면 .then 의 함수가 실행되는 약속 객체). 응답을 기다리는 동안 화면은 멈추지 않는다.
    fetch('/api/chat?after=' + lastId())
      // 첫 번째 .then: 응답 머리가 도착했을 때
      // (1) r.ok          상태코드가 200~299 면 true
      // (2) throw …       아니면 오류로 만들어 아래 .catch 로 건너뛴다
      // (3) r.json()      몸통 JSON 글자를 자바스크립트 객체로 바꾼다 (이것도 Promise)
      .then(function (r) { if (!r.ok) throw new Error(r.status); return r.json(); })
      // [흐름 B′-⑤] 두 번째 .then: j = 바뀐 객체.  예) {online:true, messages:[{id:103, fromBoss:true, …}]}
      .then(function (j) {
        status(j.online);
        var near = nearBottom();
        // 새 메시지마다 render(m). 이미 있는 번호면 render 가 null 을 돌려준다.
        j.messages.forEach(function (m) {
          if (render(m)) {
            // CustomEvent('chat:new', { detail: m })
            //   뜻     : 직접 이름을 지은 이벤트를 만든다. detail 에 메시지 객체를 담는다.
            //   결과   : document.addEventListener('chat:new', …) 로 기다리는 office.js 가 받아 사장실↔쭌 책상 사이에 봉투를 날린다.
            //   이 파일은 office.js 를 몰라도 된다. 이벤트만 보낸다.
            document.dispatchEvent(new CustomEvent('chat:new', { detail: m }));
            if (!m.fromBoss && KEY.test(m.text || '')) notify(m.text);
          }
        });
        if (j.messages.length) { updateDecide(); if (near) bottom(); }
      })
      // .catch: 앞의 어디에서든 오류가 나면 여기로 온다. 서버가 잠깐 꺼져도 화면에 오류를 띄우지 않고 넘어간다.
      .catch(function () { /* 잠깐 끊겨도 다음 차례에 다시 */ })
      // .finally: 성공·실패와 상관없이 마지막에 실행한다.
      // setTimeout(poll, 3000): 3000밀리초(3초) 뒤에 poll 을 한 번 부른다. 그 poll 이 끝나면 또 3초 뒤… 로 계속 이어진다.
      // setInterval 대신 이렇게 하면 응답이 늦을 때 요청이 겹쳐 쌓이지 않는다.
      .finally(function () { setTimeout(poll, 3000); });
  }

  // 6초마다 GET /api/office/status.  응답 예) {"tmuxAvailable":false,"leadWaitingPermission":false,"working":[]}
  // leadWaitingPermission 이 true 면 "쭌이 허용을 기다려요" 안내를 보인다.
  function pollPermission() {
    fetch('/api/office/status')
      .then(function (r) { return r.ok ? r.json() : null; })
      .then(function (j) { if (j) perm.classList.toggle('on', !!j.leadWaitingPermission); })
      .catch(function () {})
      .finally(function () { setTimeout(pollPermission, 6000); });
  }

  /** 보내기: 201 Created → 화면에 추가, 그 밖의 상태코드 → 오류 문장 표시 */
  // [흐름 B-①] 보내기.  돌려줌: Promise<true/false> (보냈으면 true)
  function send(text) {
    // 앞뒤 공백을 지운다.  예) "  좋아요 " → "좋아요"
    text = (text || '').trim();
    // 빈 글이면 서버에 보내지 않고 바로 false. (서버에서도 @Valid 로 한 번 더 막는다 → 흐름 D-①)
    if (!text) return Promise.resolve(false);
    err.hidden = true;
    // 요청 헤더. Content-Type: application/json = "몸통이 JSON 이다".
    // 없으면: 스프링이 @RequestBody 를 JSON 으로 읽지 못해 415(Unsupported Media Type) 가 된다.
    var headers = { 'Content-Type': 'application/json' };
    // 서버(prod) 모드에서는 HTML 머리에 <meta name="_csrf" content="토큰"> 과 <meta name="_csrf_header" content="X-CSRF-TOKEN"> 이 있다.
    var csrf = document.querySelector('meta[name="_csrf"]'), csrfHeader = document.querySelector('meta[name="_csrf_header"]');
    // 그 토큰을 헤더에 넣는다.  결과 예) headers = {"Content-Type":"application/json","X-CSRF-TOKEN":"…"}
    // 없으면(서버 모드에서): Spring Security 가 다른 사이트에서 온 요청으로 보고 403 을 돌려준다. 내 PC 모드에는 meta 가 없어 건너뛴다.
    if (csrf && csrfHeader) headers[csrfHeader.content] = csrf.content; // 서버 모드: CSRF 토큰
    // [흐름 B-①] 서버로 보내는 줄
    // (1) method: 'POST'                  방식
    // (2) headers                         위에서 만든 헤더
    // (3) JSON.stringify({ text: text })  객체를 JSON 글자로.  {text:"좋아요, 이대로 진행해 주세요."} → '{"text":"좋아요, 이대로 진행해 주세요."}'
    // 실제 요청) POST /api/chat   Content-Type: application/json   {"text":"좋아요, 이대로 진행해 주세요."}
    // 다음 차례: 서버의 ChatApiController.send() (흐름 B-②)
    return fetch('/api/chat', { method: 'POST', headers: headers, body: JSON.stringify({ text: text }) })
      // 응답이 오면 상태코드와 몸통을 한 객체로 묶는다. 201 이든 400·503 이든 몸통은 JSON 이기 때문이다.
      // 결과 예) {status:201, body:{id:103, fromBoss:true, …}}   또는   {status:400, body:{status:400, code:"VALIDATION", message:"보낼 말을 적어 주세요.", …}}
      .then(function (r) { return r.json().then(function (body) { return { status: r.status, body: body }; }); })
      .then(function (res) {
        // [흐름 B-⑦] 201 Created = 서버가 저장까지 마쳤다. === 는 자료형까지 같은지 비교한다.
        if (res.status === 201) {
          // 응답 JSON 으로 말풍선을 그리고, 새로 그렸으면 chat:new 이벤트도 보낸다.
          if (render(res.body)) document.dispatchEvent(new CustomEvent('chat:new', { detail: res.body }));
          updateDecide(); bottom();
          return true;
        }
        // [흐름 D-④] 201 이 아니면 서버가 보낸 ErrorResponse 의 message 를 보여 준다.
        // 예) 400 → "보낼 말을 적어 주세요."   503 → "쭌이 출근 전이에요. 우분투 창에서 '출근'을 입력한 뒤 다시 보내 주세요."
        // message 가 없으면 "보내지 못했어요 (500)" 처럼 상태코드를 보여 준다.
        err.textContent = res.body.message || ('보내지 못했어요 (' + res.status + ')');
        err.hidden = false;
        return false;
      })
      // 서버 자체에 연결하지 못했을 때(관리 화면을 껐을 때)나 응답이 JSON 이 아닐 때.
      .catch(function () { err.textContent = '관리 화면과 연결이 끊겼어요. 새로고침해 주세요.'; err.hidden = false; return false; });
  }

  // [흐름 B-①] 모든 흐름 B 의 시작점
  // addEventListener('submit', 함수)
  //   뜻     : 폼에 "제출(submit)" 사건이 일어나면 함수를 부른다. 보내기 버튼을 누르거나 Enter 로 제출할 때 일어난다.
  //   받는 것: ev = 사건 정보 객체
  document.getElementById('cp-form').addEventListener('submit', function (ev) {
    // preventDefault(): 브라우저의 기본 동작(폼 내용을 들고 다른 페이지로 이동)을 막는다.
    // 없으면: 페이지가 새로 열려 아래 fetch 결과를 그릴 화면이 사라진다.
    ev.preventDefault();
    // 입력칸 글을 보내고, 보냈으면(true) 입력칸을 비운다. 실패하면 글을 남겨 다시 보낼 수 있게 한다.
    send(tx.value).then(function (ok) { if (ok) tx.value = ''; });
  });
  // 입력칸에서 키를 누를 때마다.
  tx.addEventListener('keydown', function (e) {
    // Enter 만 누르면 보내기, Shift+Enter 는 줄바꿈.
    // isComposing = 한글 조합 중(예: "좋" 을 치는 중). 조합 중의 Enter 는 글자 확정이므로 보내지 않는다.
    // requestSubmit(): 폼 제출 사건을 일으킨다 → 위의 submit 함수가 실행된다.
    if (e.key === 'Enter' && !e.shiftKey && !e.isComposing) { e.preventDefault(); document.getElementById('cp-form').requestSubmit(); }
  });
  // 승인·수정·거부 버튼과 빠른 말 칩: 결국 평소 말로 보냄
  // 패널 안 어디를 눌러도 이 함수 하나가 받는다(이벤트 위임). 버튼마다 따로 등록하지 않는다.
  root.addEventListener('click', function (e) {
    // e.target = 실제로 누른 요소.  closest(선택자) = 자신부터 바깥쪽으로 올라가며 맞는 첫 요소.
    // 예) <button data-say="좋아요, 이대로 진행해 주세요.">✅ 승인</button> 을 누르면 b = 그 버튼
    var b = e.target.closest('[data-say],[data-edit]');
    if (!b) return;
    // "✏️ 수정" 버튼(data-edit="이렇게 바꿔 주세요: ") 이면 보내지 않고 입력칸에 글을 채운 뒤 커서를 맨 끝에 둔다.
    if (b.dataset.edit !== undefined) { tx.value = b.dataset.edit; tx.focus(); tx.setSelectionRange(tx.value.length, tx.value.length); return; }
    // "⛔ 거부" 버튼은 data-confirm 이 있어 한 번 더 묻는다.  예) "정말 거부할까요? 쭌이 작업을 멈추고 무엇을 바꿀지 물어봐요."
    // 취소를 누르면 여기서 끝.
    if (b.dataset.confirm && !window.confirm(b.dataset.confirm)) return;
    // 보내는 동안 버튼을 눌리지 않게 한다(두 번 보내기 방지).
    b.disabled = true;
    // 버튼에 적힌 말을 평소 말처럼 보낸다(흐름 B 와 같은 길).  예) "좋아요, 이대로 진행해 주세요."
    send(b.dataset.say).finally(function () { b.disabled = false; });
  });
  // 알림음 켜기/끄기. 고른 값을 localStorage 에 저장한다.
  bell.addEventListener('click', function () {
    soundOn = !soundOn;
    bell.textContent = soundOn ? '🔔' : '🔕';
    try { localStorage.setItem('publisher:sound', soundOn ? 'on' : 'off'); } catch (e) {}
  });
  bell.textContent = soundOn ? '🔔' : '🔕';
  // 이 탭으로 돌아오면(document.hidden=false) 제목 깜빡임을 멈춘다.
  document.addEventListener('visibilitychange', function () { if (!document.hidden) { clearInterval(blinkTimer); document.title = baseTitle; } });

  // 서버가 처음 그린 시각을 브라우저 시간대로 다시 표시
  // 서버가 그린 시각은 서버 시간대다. data-at(원래 ISO 시각)으로 브라우저 시간대의 시각을 다시 적는다.
  // 예) 서버 "사장님 · 11-09 10:06" → 한국 브라우저 "사장님 · 11-09 19:06"
  log.querySelectorAll('small[data-at]').forEach(function (e) {
    e.textContent = e.textContent.replace(/\d\d-\d\d \d\d:\d\d$/, time(e.dataset.at));
  });
  updateDecide(); bottom();
  // [흐름 B′] 첫 폴링을 3초 뒤에 시작한다. 그 뒤로는 poll() 의 finally 가 이어 간다.
  setTimeout(poll, 3000);
  pollPermission();
  // 다른 파일에서 ChatPanel.send("…") 로 쓸 수 있게 send 만 밖으로 내놓는다.
  window.ChatPanel = { send: send };
})();
