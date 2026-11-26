/*
 * [1] 역할
 *     GET /api/office/status 응답 몸통의 모양이다. 대화방이 6초마다 받아 알림 표시 여부를 정한다.
 *
 * [2] 받는 것 → 내보내는 것 (실제로 실행해서 얻은 값)
 *     내보내는 것  {"tmuxAvailable":false,"leadWaitingPermission":false,"working":[]}
 *
 * [3] 앞뒤 파일
 *     service/OfficeService.java 의 status()  →  api/OfficeApiController.java  →  static/js/chatpanel.js 의 pollPermission()
 *
 * [4] 필드 목록
 *     필드                    자료형         뜻                                       예
 *     tmuxAvailable           boolean        tmux 화면을 읽을 수 있었는가               false
 *     leadWaitingPermission   boolean        쭌이 허용 질문에서 멈춰 있는가             false
 *     working                 List<String>   지금 작업 중인 사람의 한글 이름 목록         []
 *
 * [5] 먼저 알 용어 (자세한 설명: docs/용어-풀이.md)
 *     record, boolean
 *
 * [6] 읽는 순서
 *     필드 목록이 전부다.
 *
 * [7] 다 읽고 확인
 *     - leadWaitingPermission 이 true 이면 chatpanel.js 는 어느 요소에 on 클래스를 붙이는가? ( id="cp-perm" )
 *     - 이 응답은 /api/office 보다 작다. 대화방이 /api/office 대신 이 주소를 호출하는 이유는 무엇인가?
 */
package com.greendesk.publisher.dto;

import java.util.List;

/** GET /api/office/status 응답: 가벼운 알림용 (대화방이 부름) */
// record
//   뜻     : 값만 담는 클래스를 짧게 선언하는 자바 문법이다. 괄호 안에 적은 이름들이 필드가 된다.
//   결과   : 자바가 생성자, 필드 값을 꺼내는 메서드(예: text()), equals, toString 을 자동으로 만든다.
//            값을 바꾸는 메서드(setter)는 만들지 않는다. 한 번 만든 객체의 값은 바뀌지 않는다.
//   JSON   : 스프링이 이 객체를 JSON 으로 바꿀 때 필드 이름이 JSON 의 이름이 된다.
public record OfficeStatusResponse(boolean tmuxAvailable, boolean leadWaitingPermission, List<String> working) {
}
