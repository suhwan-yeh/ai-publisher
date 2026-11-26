/*
 * [1] 역할
 *     템플릿(HTML)에서 시각을 보기 좋은 글자로 바꿀 때 부르는 메서드 모음이다.
 *     @Component("fmt") 이므로 템플릿에서 ${@fmt.메서드(값)} 으로 부른다.  @ 는 "스프링이 관리하는 객체"라는 뜻이다.
 *
 * [2] 받는 것 → 내보내는 것 (실제로 실행해서 얻은 값)
 *     실제 템플릿 줄 → 실제로 나온 글자 (서버 시간대 UTC, 지금 2026-11-10 02:39)
 *       team.html       <td th:text="${@fmt.time(m.firstSeen)}">     →  <td>11-09 20:21:37</td>
 *       fragments.html  … + ' · ' + ${@fmt.chat(c.at)}               →  "사장님 · 11-09 10:06"
 *       team.html       <td th:text="${@fmt.ago(m.lastActive)}">     →  <td>5시간 전</td>
 *
 * [3] 앞뒤 파일
 *     templates/index.html, book.html, team.html, fragments.html(대화 말풍선)  →  (이 파일)
 *
 * [4] 메서드 목록
 *     메서드          받는 것       돌려주는 것                 예
 *     time(시각)      Instant      "MM-dd HH:mm:ss"           "11-09 20:21:37"
 *     chat(시각)      Instant      "MM-dd HH:mm"              "11-09 10:06"
 *     ago(시각)       Instant      지금부터 얼마 전인지         "12초 전", "3분 전", "2시간 전", "1일 전"
 *
 * [5] 먼저 알 용어 (자세한 설명: docs/용어-풀이.md)
 *     @Component("이름"), DateTimeFormatter, ZoneId, 타임리프 ${@빈이름.메서드()}
 *
 * [6] 읽는 순서
 *     time() → chat() → ago()
 *
 * [7] 다 읽고 확인
 *     - @Component("fmt") 를 @Component 로 바꾸면 템플릿의 ${@fmt.time(…)} 은 어떻게 되는가? (빈 이름이 viewHelpers 가 되어 오류)
 *     - ago() 에 90초 전 시각을 넣으면 무엇을 돌려주는가? ("1분 전")
 */
package com.greendesk.publisher.controller;

import org.springframework.stereotype.Component;

import java.time.Instant;
import java.time.ZoneId;
import java.time.format.DateTimeFormatter;

/** 템플릿에서 ${@fmt.time(...)} 처럼 씀 */
// @Component("fmt")
//   뜻     : 스프링이 이 클래스 객체를 만들어 "fmt" 라는 이름으로 관리한다.
//   결과   : 타임리프에서 ${@fmt.time(값)} 처럼 이름으로 불러 쓸 수 있다.
//   없으면 : 템플릿이 fmt 를 찾지 못해 화면을 그릴 때 오류(500)가 난다.
@Component("fmt")
public class ViewHelpers {

    // T: 시각을 "월-일 시:분:초" 글자로 바꾸는 규칙. withZone(ZoneId.systemDefault()) = 이 컴퓨터의 시간대로 바꿔 적는다.
    // 예) Instant 2026-11-09T20:21:37Z → UTC 서버에서 "11-09 20:21:37", 한국 시간대(UTC+9) PC 에서 "11-10 05:21:37"
    private static final DateTimeFormatter T = DateTimeFormatter.ofPattern("MM-dd HH:mm:ss").withZone(ZoneId.systemDefault());

    public String time(Instant at) {
        // 시각이 없으면 빈 글자, 있으면 규칙대로 바꾼 글자.
        return at == null ? "" : T.format(at);
    }

    // C: "월-일 시:분". chatpanel.js 가 새 말풍선에 적는 시각과 같은 모양이다.
    private static final DateTimeFormatter C = DateTimeFormatter.ofPattern("MM-dd HH:mm").withZone(ZoneId.systemDefault());

    /** 대화방 시각 (화면의 자바스크립트와 같은 모양) */
    public String chat(Instant at) {
        return at == null ? "" : C.format(at);
    }

    public String ago(Instant at) {
        if (at == null) return "";
        // (1) Instant.now().getEpochSecond()  지금 시각을 1970-01-01 부터 센 초로.
        // (2) - at.getEpochSecond()           그 시각과의 차이(초).
        // (3) Math.max(0, …)                  컴퓨터 시계 차이로 음수가 되면 0.
        // 예) 지금 02:39, at 전날 20:21 → s 는 약 22680 → 3600 이상 86400 미만 → 22680/3600 = 6 → "6시간 전"
        long s = Math.max(0, Instant.now().getEpochSecond() - at.getEpochSecond());
        if (s < 60) return s + "초 전";
        if (s < 3600) return (s / 60) + "분 전";
        if (s < 86400) return (s / 3600) + "시간 전";
        return (s / 86400) + "일 전";
    }
}
