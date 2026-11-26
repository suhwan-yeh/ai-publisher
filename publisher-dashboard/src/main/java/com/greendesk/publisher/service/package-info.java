/*
 * [1] 역할
 *     업무 규칙을 정하는 @Service 묶음. 무엇을 어떤 순서로 할지 정하고, repository 와 client 를 부른다.
 *
 * [2] 받는 것 → 내보내는 것 (실제로 실행해서 얻은 값)
 *     ChatService.send("좋아요, 이대로 진행해 주세요.")
 *       (1) 글 확인  (2) FakechatClient 로 쭌에게 전달  (3) insert into chat_message …  (4) ChatMessage 엔티티를 돌려준다
 *
 * [3] 앞뒤 파일
 *     계층 (화살표 = 부르는 방향, 거꾸로 부르지 않는다)
 *       브라우저 → controller / api → service → repository → DB
 *                                       service → client → fakechat(쭌), tmux
 *       scan(시각에 맞춰 실행) → service → scan 의 읽기 클래스 → repository → DB
 *       dto  : api 가 JSON 으로 주고받는 모양     domain : DB 표와 대응하는 엔티티     config : 설정
 *
 * [4] 파일 목록
 *     ChatService            보내기·주문·폴링·첨부 파일                       흐름 B-③, B′, C-③
 *     DashboardService       첫 화면·책 상세·직원 현황 값 모으기               흐름 A
 *     OfficeService          사무실·회의실 값 모으기                          흐름 E
 *     ScanService            scan 패키지의 읽기 클래스를 차례로 부른다          흐름 F-②
 *     BookView, ChapterPreview, DownloadFile, PaneReading   화면에 넘길 값 모양
 *     NotFoundException, FileAccessDeniedException          404, 400 이 되는 예외
 *
 * [5] 먼저 알 용어 (자세한 설명: docs/용어-풀이.md)
 *     @Service, @Transactional, 생성자 주입, 예외 던지기(throw)
 *
 * [6] 읽는 순서
 *     ChatService → DashboardService → OfficeService → ScanService
 *
 * [7] 다 읽고 확인
 *     - 쭌에게 전달은 됐는데 DB 저장이 실패하면 @Transactional 이 되돌리는 것과 못 되돌리는 것은 각각 무엇인가?
 *     - 컨트롤러 대신 서비스에 규칙을 두면 좋은 점은? (화면 컨트롤러와 API 컨트롤러가 같은 규칙을 함께 쓴다)
 */
package com.greendesk.publisher.service;
