/*
 * [1] 역할
 *     책의 진행 단계 여섯 가지를 정한 enum 이다. BookScanner 가 책 폴더에 생긴 파일을 보고 단계를 정한다.
 *
 * [2] 받는 것 → 내보내는 것 (실제로 실행해서 얻은 값)
 *     Stage.WRITING.getLabel() = "집필 중",  Stage.WRITING.ordinal() = 2,  Stage.WRITING.step() = 3
 *
 * [3] 앞뒤 파일
 *     scan/BookScanner.java (단계를 정함)  →  domain/Book.java 의 stage  →  templates/fragments.html (단계 표시), dto/BookSummaryResponse.java
 *
 * [4] 상수 목록
 *     상수         한글 이름       언제
 *     ORDERED      주문 접수       책 폴더가 생김
 *     PLANNED      기획 완료       plan/title.txt 가 생김
 *     WRITING      집필 중         manuscript/*.md 가 생김
 *     REVIEWING    교정 중         review/*.md 가 생김
 *     COVER        표지 완료       design/cover.svg 가 생김
 *     DONE         전자책 완성     dist/book.pdf 또는 book.epub 이 생김
 *
 * [5] 먼저 알 용어 (자세한 설명: docs/용어-풀이.md)
 *     enum, ordinal()
 *
 * [6] 읽는 순서
 *     상수 → getLabel() → step()
 *
 * [7] 다 읽고 확인
 *     - 타임리프의 ${T(com.greendesk.publisher.domain.Stage).values()} 는 무엇을 돌려주는가?
 *     - 상수의 순서를 바꾸면 화면의 단계 표시는 어떻게 되는가?
 */
package com.greendesk.publisher.domain;

/** 책 진행 단계 (폴더 안에 생긴 파일로 판단) */
// enum: 정해진 값 여섯 개 중 하나만 가질 수 있는 자료형. 괄호 안 글자는 각 값의 한글 이름이다.
public enum Stage {
    ORDERED("주문 접수"),
    PLANNED("기획 완료"),
    WRITING("집필 중"),
    REVIEWING("교정 중"),
    COVER("표지 완료"),
    DONE("전자책 완성");

    private final String label;

    Stage(String label) {
        this.label = label;
    }

    public String getLabel() {
        return label;
    }

    // ordinal() = 선언 순서(0부터). step() = 1부터 세는 번호.   예) ORDERED → 1
    public int step() {
        return ordinal() + 1;
    }
}
