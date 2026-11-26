/*
 * [1] 역할
 *     DB 표 하나와 대응하는 @Entity 클래스와, 이름·단계 같은 값 묶음(enum, record).
 *
 * [2] 받는 것 → 내보내는 것 (실제로 실행해서 얻은 값)
 *     ChatMessage 객체 하나  ↔  chat_message 표의 행 하나
 *       id=103, direction=FROM_BOSS, text='좋아요, 이대로 진행해 주세요.', channel='web', unique_key='web:web-…'
 *
 * [3] 앞뒤 파일
 *     계층 (화살표 = 부르는 방향, 거꾸로 부르지 않는다)
 *       브라우저 → controller / api → service → repository → DB
 *                                       service → client → fakechat(쭌), tmux
 *       scan(시각에 맞춰 실행) → service → scan 의 읽기 클래스 → repository → DB
 *       dto  : api 가 JSON 으로 주고받는 모양     domain : DB 표와 대응하는 엔티티     config : 설정
 *
 * [4] 파일 목록
 *     ChatMessage, BookOrder                      대화·주문
 *     Book, BookFile, BookSession                  책과 완성 파일, 책을 맡은 팀
 *     TeamMember, TeamMessage                      팀원과 팀원끼리 메시지
 *     Stage, StaffMember, Names                    단계 이름, 직원 정보, 이름 맞추기
 *
 * [5] 먼저 알 용어 (자세한 설명: docs/용어-풀이.md)
 *     @Entity, @Table, @Id, @GeneratedValue, @Lob, @Column, @Enumerated, @OneToMany, @ManyToOne
 *
 * [6] 읽는 순서
 *     ChatMessage → Book → BookFile → 나머지
 *
 * [7] 다 읽고 확인
 *     - 엔티티에 protected 기본 생성자가 꼭 있는 이유는?
 *     - 엔티티를 API 응답으로 그대로 내보내지 않는 이유는? (dto 패키지 참고)
 */
package com.greendesk.publisher.domain;
