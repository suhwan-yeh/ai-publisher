/*
 * [1] 역할
 *     책 한 권과 그 책을 만드는 동안의 직원·메시지 목록을 함께 담고, 4가지 점검 결과를 계산하는 클래스다.
 *     타임리프 화면(index.html, book.html)과 BookSummaryResponse(JSON)가 이 클래스의 메서드 값을 사용한다.
 *
 * [2] 받는 것 → 내보내는 것 (실제로 실행해서 얻은 값)
 *     받는 것        Book + List<TeamMember> + List<TeamMessage> + List<ChatMessage>   (DashboardService.view() 가 만든다)
 *     내보내는 것    memberCount() = 4, peerTalkCount() = 4, reportCount() = 6, check4() = false, checksPassed() = 3   (20261109-dinosaur 책의 실제 값)
 *
 * [3] 앞뒤 파일
 *     service/DashboardService.java  →  (이 파일)  →  templates/index.html·fragments.html·book.html, dto/BookSummaryResponse.java
 *
 * [4] 메서드 목록
 *     메서드              하는 일                                                 점검
 *     expectedMembers()   직원 명부의 책 팀 인원 (기준 값)                           ① 의 기준
 *     memberCount()       이 책을 만든 책 팀 직원 수 (같은 사람은 한 번만)              ①
 *     peerTalkCount()     직원끼리 직접 주고받은 메시지 수 (쭌이 끼지 않은 것)           ②
 *     reportCount()       직원 → 쭌 [보고] 수 + 쭌 → 사장님 보고 수                  ③
 *     filesDelivered()    쭌이 사장님께 파일을 첨부해 보냈는가                        ④
 *     filesMade()         책 폴더에 PDF 또는 EPUB 이 있는가                          ④
 *     check1()~check4()   각 점검의 통과 여부
 *     checksPassed()      통과한 점검의 개수 (0~4)
 *
 * [5] 먼저 알 용어 (자세한 설명: docs/용어-풀이.md)
 *     record, stream·map·filter·distinct·count·anyMatch, 메서드 참조(TeamMessage::isPeerTalk), 삼항 연산자
 *
 * [6] 읽는 순서
 *     memberCount() → peerTalkCount() → reportCount() → filesDelivered() → check1()~checksPassed()
 *
 * [7] 다 읽고 확인
 *     - 직원 명부에 신입이 book 팀으로 한 명 추가되면 check1() 의 기준은 몇이 되는가?
 *     - 서버실의 테포(team: ops)가 이 책 팀에 섞여 있으면 memberCount() 에 포함되는가?
 */
package com.greendesk.publisher.service;

import com.greendesk.publisher.domain.*;

import java.util.List;

/**
 * 화면에 보여 줄 책 한 권의 요약과 4가지 점검.
 * ① 팀원 생성 ② 팀원끼리 메시지 ③ 보고 ④ 파일 도착
 */
// record: 값만 담는 클래스. 네 필드는 DashboardService.view() 가 넣는다. 타임리프에서는 ${v.book()} 처럼 꺼낸다.
public record BookView(Book book,
                       List<TeamMember> members,
                       List<TeamMessage> teamMessages,
                       List<ChatMessage> chat) {

    /** 점검 ① 기준: 직원 명부에서 책 만드는 팀(book) 인원 */
    public int expectedMembers() {
        // 직원 명부(staff.yml)에서 team 이 book 인 사람 수.   예) 4
        return Names.bookTeamSize();
    }

    /** 이 책을 만든 책 팀 인원 (서버 담당 테포 같은 다른 팀은 세지 않음) */
    public long memberCount() {
        // (1) members.stream()                          이 책의 직원 목록을 하나씩 처리한다.
        // (2) .map(m -> Names.canonical(m.getName()))   이름을 하나의 표기로 맞춘다.        예) "minjun-2" → "minjun"
        // (3) .filter(n -> "book".equals(Names.team(n))) 책 팀인 사람만 남긴다.             예) "tepo"(ops) 는 빠진다
        // (4) .distinct()                               같은 이름은 한 번만 남긴다.
        // (5) .count()                                  개수를 센다.                       예) 4
        return members.stream().map(m -> Names.canonical(m.getName())).filter(n -> "book".equals(Names.team(n))).distinct().count();
    }

    public long peerTalkCount() {
        // TeamMessage::isPeerTalk = "각 메시지의 isPeerTalk() 메서드" 를 가리키는 표기 (메서드 참조).
        // isPeerTalk() 가 true 인 메시지(보낸 사람·받는 사람 모두 쭌이 아닌 메시지)의 개수.
        return teamMessages.stream().filter(TeamMessage::isPeerTalk).count();
    }

    public long reportCount() {
        // 직원 메시지 중 종류가 REPORT 인 것의 개수 + 쭌이 사장님께 보낸 메시지 중 보고([제안]·[최종 보고]·📘 등)의 개수
        return teamMessages.stream().filter(m -> m.getKind() == TeamMessage.Kind.REPORT).count()
                + chat.stream().filter(ChatMessage::isReport).count();
    }

    public boolean filesDelivered() {
        // anyMatch = 하나라도 조건에 맞으면 true.
        // 조건: 쭌 → 사장님 방향(TO_BOSS)이고(&&) 첨부 파일이 있는 메시지
        return chat.stream().anyMatch(c -> c.getDirection() == ChatMessage.Direction.TO_BOSS && c.hasAttachments());
    }

    public boolean filesMade() {
        // PDF 가 있거나(||) EPUB 이 있으면 true.
        return book.hasFile(BookFile.Kind.PDF) || book.hasFile(BookFile.Kind.EPUB);
    }

    // 점검 ① 팀원 생성 : 책 팀 인원이 기준 이상이면 통과   예) 4 >= 4 → true
    public boolean check1() { return memberCount() >= expectedMembers(); }
    // 점검 ② 팀원끼리 메시지 : 한 건이라도 있으면 통과
    public boolean check2() { return peerTalkCount() > 0; }
    // 점검 ③ 보고 : 한 건이라도 있으면 통과
    public boolean check3() { return reportCount() > 0; }
    // 점검 ④ 파일 도착 : 파일이 만들어졌고(&&) 사장님께 보냈으면 통과
    public boolean check4() { return filesDelivered() && filesMade(); }

    public int checksPassed() {
        // 통과면 1, 아니면 0 으로 바꿔 더한다.   예) true,true,true,false → 1+1+1+0 = 3
        return (check1() ? 1 : 0) + (check2() ? 1 : 0) + (check3() ? 1 : 0) + (check4() ? 1 : 0);
    }
}
