/*
 * [1] 역할
 *     책 한 권의 요약과 4가지 점검 결과를 응답 JSON 으로 내보낼 때의 모양이다.
 *
 * [2] 받는 것 → 내보내는 것 (실제로 실행해서 얻은 값)
 *     받는 것        service/BookView (책 엔티티 + 그 책의 직원·메시지 목록)
 *     내보내는 것    {"id":2,"folder":"20261109-dinosaur","title":"20261109-dinosaur","genre":"동화","stage":"기획 완료","stageIndex":1,
 *                    "chapters":0,"chars":0,"members":4,"expectedMembers":4,"peerTalk":4,"reports":6,
 *                    "filesMade":false,"filesDelivered":false,"checksPassed":3}
 *
 * [3] 앞뒤 파일
 *     service/BookView.java  →  (이 파일)  →  api/BookApiController.java, dto/OfficeResponse.java 의 book 필드  →  static/js/office.js, meeting.js
 *
 * [4] 필드와 메서드 목록
 *     필드              자료형    뜻                                             예
 *     id                Long      책 번호                                        2
 *     folder            String    책 작업 폴더 이름                               "20261109-dinosaur"
 *     title             String    제목 (아직 정해지지 않았으면 폴더 이름)           "20261109-dinosaur"
 *     genre             String    장르                                           "동화"
 *     stage             String    진행 단계의 한글 이름                           "기획 완료"
 *     stageIndex        int       진행 단계의 순서 (0 = 주문 접수 … 5 = 전자책 완성)  1
 *     chapters          int       쓴 장의 수                                      0
 *     chars             int       쓴 글자 수                                      0
 *     members           long      이 책을 만든 책 팀 직원 수 (점검 ①)              4
 *     expectedMembers   int       직원 명부에 있는 책 팀 인원                      4
 *     peerTalk          long      직원끼리 직접 주고받은 메시지 수 (점검 ②)         4
 *     reports           long      보고 수 (점검 ③)                                6
 *     filesMade         boolean   PDF·EPUB 파일이 만들어졌는가                     false
 *     filesDelivered    boolean   파일을 사장님께 보냈는가 (점검 ④)                 false
 *     checksPassed      int       4가지 점검 중 통과한 개수                        3
 *
 *     메서드            하는 일
 *     from()            BookView 를 받아 BookSummaryResponse 를 만든다
 *
 * [5] 먼저 알 용어 (자세한 설명: docs/용어-풀이.md)
 *     record, static 메서드, var, enum 의 ordinal()
 *
 * [6] 읽는 순서
 *     필드 목록 → from()
 *
 * [7] 다 읽고 확인
 *     - stage 와 stageIndex 는 같은 정보를 두 가지 형태로 보낸다. office.js 는 각각 어디에 쓰는가?
 *     - members 가 4 이고 expectedMembers 가 4 이면 점검 ① 은 통과인가?
 */
package com.greendesk.publisher.dto;

import com.greendesk.publisher.service.BookView;

/** 책 한 권의 요약과 4가지 점검 */
// record
//   뜻     : 값만 담는 클래스를 짧게 선언하는 자바 문법이다. 괄호 안에 적은 이름들이 필드가 된다.
//   결과   : 자바가 생성자, 필드 값을 꺼내는 메서드(예: text()), equals, toString 을 자동으로 만든다.
//            값을 바꾸는 메서드(setter)는 만들지 않는다. 한 번 만든 객체의 값은 바뀌지 않는다.
//   JSON   : 스프링이 이 객체를 JSON 으로 바꿀 때 필드 이름이 JSON 의 이름이 된다.
public record BookSummaryResponse(Long id, String folder, String title, String genre,
                                  String stage, int stageIndex, int chapters, int chars,
                                  long members, int expectedMembers, long peerTalk, long reports,
                                  boolean filesMade, boolean filesDelivered, int checksPassed) {

    // ▶ 받는 값: BookView v (책 한 권의 정보 묶음)      ▶ 돌려주는 값: BookSummaryResponse
    public static BookSummaryResponse from(BookView v) {
        // v.book() 으로 책 엔티티(Book)를 꺼내 변수 b 에 넣는다.
        // var = 오른쪽 값의 자료형을 자바가 알아내서 변수의 자료형으로 정한다. 여기서 b 의 자료형은 Book 이다.
        var b = v.book();
        // 아래 네 줄의 값 순서는 record 선언의 필드 순서와 같다.
        //   b.getStage().getLabel()    단계의 한글 이름                  예) "기획 완료"
        //   b.getStage().ordinal()     단계가 enum 에서 몇 번째인지 (0부터) 예) 1
        //   v.check4()                 점검 ④ 통과 여부 → filesDelivered
        return new BookSummaryResponse(b.getId(), b.getFolder(), b.displayTitle(), b.getGenre(),
                b.getStage().getLabel(), b.getStage().ordinal(), b.getChapterCount(), b.getCharCount(),
                v.memberCount(), v.expectedMembers(), v.peerTalkCount(), v.reportCount(),
                v.filesMade(), v.check4(), v.checksPassed());
    }
}
