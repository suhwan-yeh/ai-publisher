/*
 * [1] 역할
 *     GET /api/office/screen/{name} 응답 몸통의 모양이다. 직원 한 명의 tmux 칸 화면 글자 전체를 담는다.
 *
 * [2] 받는 것 → 내보내는 것 (실제로 실행해서 얻은 값)
 *     내보내는 것  {"name":"jihun","korean":"지훈","status":"WORKING","statusLabel":"작업 중","lines":["● Web Search(\"…\")","  ⎿  Did 1 search in 8s", …]}
 *     (tmux 가 실행 중일 때의 예. tmux 가 없으면 404 가 응답된다)
 *
 * [3] 앞뒤 파일
 *     service/OfficeService.java 의 screen()  →  api/OfficeApiController.java  →  static/js/office.js 의 refreshModal()
 *
 * [4] 필드 목록
 *     필드          자료형         뜻                              예
 *     name          String         영문 이름                        "jihun"
 *     korean        String         한글 이름                        "지훈"
 *     status        String         WORKING · WAITING · IDLE        "WORKING"
 *     statusLabel   String         status 의 한글 표시              "작업 중"
 *     lines         List<String>   화면 글자를 한 줄씩 담은 목록
 *
 * [5] 먼저 알 용어 (자세한 설명: docs/용어-풀이.md)
 *     record, List<String>
 *
 * [6] 읽는 순서
 *     필드 목록이 전부다.
 *
 * [7] 다 읽고 확인
 *     - office.js 는 lines 목록을 화면에 표시할 때 어떤 글자로 이어 붙이는가? ( lines.join("\n") : 줄바꿈 )
 *     - 사무실 책상의 모니터에는 14줄만 보인다. 이 응답에는 몇 줄이 들어 있는가? (입력칸을 뺀 화면 전체)
 */
package com.greendesk.publisher.dto;

import java.util.List;

/** GET /api/office/screen/{name} 응답: 한 사람의 tmux 칸 화면 전체 (확대 보기) */
// record
//   뜻     : 값만 담는 클래스를 짧게 선언하는 자바 문법이다. 괄호 안에 적은 이름들이 필드가 된다.
//   결과   : 자바가 생성자, 필드 값을 꺼내는 메서드(예: text()), equals, toString 을 자동으로 만든다.
//            값을 바꾸는 메서드(setter)는 만들지 않는다. 한 번 만든 객체의 값은 바뀌지 않는다.
//   JSON   : 스프링이 이 객체를 JSON 으로 바꿀 때 필드 이름이 JSON 의 이름이 된다.
public record ScreenResponse(String name, String korean, String status, String statusLabel, List<String> lines) {
}
