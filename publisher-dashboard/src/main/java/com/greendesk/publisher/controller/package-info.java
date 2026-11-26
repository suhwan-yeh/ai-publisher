/*
 * [1] 역할
 *     주소창·링크·폼 요청을 받아 HTML 화면을 돌려주는 @Controller 묶음. 메서드는 템플릿 이름이나 "redirect:주소" 를 돌려준다.
 *
 * [2] 받는 것 → 내보내는 것 (실제로 실행해서 얻은 값)
 *     GET /books/3  →  "book"  →  templates/book.html 을 채운 HTML (200)
 *     POST /order   →  "redirect:/chat"  →  302 Location: /chat
 *
 * [3] 앞뒤 파일
 *     계층 (화살표 = 부르는 방향, 거꾸로 부르지 않는다)
 *       브라우저 → controller / api → service → repository → DB
 *                                       service → client → fakechat(쭌), tmux
 *       scan(시각에 맞춰 실행) → service → scan 의 읽기 클래스 → repository → DB
 *       dto  : api 가 JSON 으로 주고받는 모양     domain : DB 표와 대응하는 엔티티     config : 설정
 *
 * [4] 파일 목록
 *     DashboardController     /, /books/{id}, /team, /rescan, /download/…        흐름 A, C
 *     ChatPageController      /chat, /order, /chat/{id}/file/{index}               흐름 A, C
 *     OfficePageController    /office, /meeting                                    흐름 A, E-①
 *     LoginController         /login (서버 모드)
 *     ViewHelpers             템플릿에서 ${@fmt.…} 로 부르는 시각 글자 바꾸기
 *     FileResponses           파일 내려받기 응답 만들기
 *
 * [5] 먼저 알 용어 (자세한 설명: docs/용어-풀이.md)
 *     @Controller, @GetMapping, @PostMapping, Model, redirect:
 *
 * [6] 읽는 순서
 *     DashboardController → ChatPageController → OfficePageController → 나머지
 *
 * [7] 다 읽고 확인
 *     - 이 패키지의 클래스가 JSON 을 돌려주는 경우가 있는가? (없다. 파일 바이트를 돌려주는 download/file 은 있다)
 *     - 이 패키지에서 Repository 를 직접 부르는 클래스가 있는가? (없다. service 를 거친다)
 */
package com.greendesk.publisher.controller;
