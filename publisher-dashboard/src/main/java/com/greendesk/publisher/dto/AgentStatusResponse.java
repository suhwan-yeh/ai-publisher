/*
 * [1] 역할
 *     사무실 화면의 책상 하나(쭌 또는 직원 한 명)에 표시할 값을 담는다. OfficeResponse 의 agents 목록에 들어간다.
 *
 * [2] 받는 것 → 내보내는 것 (실제로 실행해서 얻은 값)
 *     내보내는 것
 *       {"name":"team-lead","korean":"쭌","role":"편집장","team":"lead","status":"IDLE","statusLabel":"대기",
 *        "activity":null,"spinner":null,"task":null,"screen":[],"lastActive":"2026-11-09T21:02:42.256Z","sent":0}
 *
 * [3] 앞뒤 파일
 *     service/OfficeService.java 의 office() 가 만든다  →  dto/OfficeResponse.java 의 agents  →  static/js/office.js 의 updateDesk()
 *
 * [4] 필드 목록
 *     필드          자료형         뜻                                                      예
 *     name          String         영문 이름 (Claude Code 팀원 이름)                         "team-lead"
 *     korean        String         한글 이름                                                "쭌"
 *     role          String         역할                                                    "편집장"
 *     team          String         lead(편집장) · book(책 팀) · ops(서버실)                   "lead"
 *     status        String         WORKING · WAITING · IDLE · OFFLINE                       "IDLE"
 *     statusLabel   String         status 의 한글 표시                                      "대기"
 *     activity      String         화면에 마지막으로 표시된 작업 줄 (없으면 null)              null
 *     spinner       String         작업 중일 때 Claude Code 가 표시하는 진행 문구 (없으면 null) null
 *     task          String         쭌이 맡긴 일의 이름 (없으면 null)                          null
 *     screen        List<String>   tmux 칸의 마지막 줄들 (tmux 를 읽지 못하면 빈 목록)         []
 *     lastActive    Instant        마지막으로 활동한 시각                                    "2026-11-09T21:02:42.256Z"
 *     sent          long           이 사람이 보낸 직원 메시지 수                              0
 *
 * [5] 먼저 알 용어 (자세한 설명: docs/용어-풀이.md)
 *     record, null, List<String>
 *
 * [6] 읽는 순서
 *     필드 목록이 전부다.
 *
 * [7] 다 읽고 확인
 *     - status 가 "WORKING" 이면 office.js 는 책상 요소에 어떤 CSS 클래스를 붙이는가? ( s-WORKING )
 *     - JSON 의 null 은 자바에서 무엇에 해당하는가?
 */
package com.greendesk.publisher.dto;

import java.time.Instant;
import java.util.List;

/**
 * 사무실 책상 하나 (쭌 또는 직원).
 * status : WORKING(작업 중) · WAITING(허용 기다림) · IDLE(대기) · OFFLINE(자리 비움)
 * screen : tmux 칸의 마지막 줄들 (tmux 를 못 읽으면 빈 목록)
 * task   : 쭌이 맡긴 일 (쭌 칸의 팀 목록에서)
 * team   : lead · book(책 팀) · ops(서버실)
 */
// record
//   뜻     : 값만 담는 클래스를 짧게 선언하는 자바 문법이다. 괄호 안에 적은 이름들이 필드가 된다.
//   결과   : 자바가 생성자, 필드 값을 꺼내는 메서드(예: text()), equals, toString 을 자동으로 만든다.
//            값을 바꾸는 메서드(setter)는 만들지 않는다. 한 번 만든 객체의 값은 바뀌지 않는다.
//   JSON   : 스프링이 이 객체를 JSON 으로 바꿀 때 필드 이름이 JSON 의 이름이 된다.
public record AgentStatusResponse(String name, String korean, String role, String team, String status, String statusLabel,
                                  String activity, String spinner, String task, List<String> screen,
                                  Instant lastActive, long sent) {
}
