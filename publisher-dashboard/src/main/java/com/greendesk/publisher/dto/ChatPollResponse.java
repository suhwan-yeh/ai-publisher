/*
 * [1] 역할
 *     GET /api/chat 응답 몸통의 모양이다. 쭌과 연결돼 있는지와 새 메시지 목록을 함께 담는다.
 *
 * [2] 받는 것 → 내보내는 것 (실제로 실행해서 얻은 값)
 *     내보내는 것  {"online":true,"messages":[{"id":103,"fromBoss":true,"text":"좋아요, 이대로 진행해 주세요.","at":"2026-11-09T21:46:33.776008Z","channel":"web","files":[]}]}
 *
 * [3] 앞뒤 파일
 *     api/ChatApiController.java 의 poll() 이 만들어 return  →  static/js/chatpanel.js 의 poll()
 *
 * [4] 필드 목록
 *     필드       자료형                      뜻                                  예
 *     online     boolean                     쭌에게 메시지를 전달할 수 있는 상태인가   true
 *     messages   List<ChatMessageResponse>   새 메시지 목록 (없으면 빈 목록)          [ {…103번…} ]
 *
 * [5] 먼저 알 용어 (자세한 설명: docs/용어-풀이.md)
 *     record, List, JSON 배열
 *
 * [6] 읽는 순서
 *     필드 두 개가 전부다.
 *
 * [7] 다 읽고 확인
 *     - 새 메시지가 없을 때 messages 는 JSON 에서 어떻게 표시되는가? ( [] )
 *     - chatpanel.js 는 online 값을 어디에 쓰는가? (status() 함수: "🟢 쭌과 연결됨" 표시)
 */
package com.greendesk.publisher.dto;

import java.util.List;

/** GET /api/chat 응답: 쭌 연결 상태 + 새 메시지들 */
// record
//   뜻     : 값만 담는 클래스를 짧게 선언하는 자바 문법이다. 괄호 안에 적은 이름들이 필드가 된다.
//   결과   : 자바가 생성자, 필드 값을 꺼내는 메서드(예: text()), equals, toString 을 자동으로 만든다.
//            값을 바꾸는 메서드(setter)는 만들지 않는다. 한 번 만든 객체의 값은 바뀌지 않는다.
//   JSON   : 스프링이 이 객체를 JSON 으로 바꿀 때 필드 이름이 JSON 의 이름이 된다.
// [흐름 B′-④] ChatApiController.poll() 이 new ChatPollResponse(연결 여부, 메시지 목록) 으로 만든다.
public record ChatPollResponse(boolean online, List<ChatMessageResponse> messages) {
}
