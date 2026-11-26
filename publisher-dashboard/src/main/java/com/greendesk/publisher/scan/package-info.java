/*
 * [1] 역할
 *     브라우저 요청 없이 시각에 맞춰 실행되는 묶음(흐름 F). 책 폴더와 Claude Code 대화 기록을 읽어 DB 를 채운다.
 *
 * [2] 받는 것 → 내보내는 것 (실제로 실행해서 얻은 값)
 *     실제 로그) 관리 화면 준비 완료: 책 5권, 기록 383건 읽음 → http://localhost:8080
 *
 * [3] 앞뒤 파일
 *     계층 (화살표 = 부르는 방향, 거꾸로 부르지 않는다)
 *       브라우저 → controller / api → service → repository → DB
 *                                       service → client → fakechat(쭌), tmux
 *       scan(시각에 맞춰 실행) → service → scan 의 읽기 클래스 → repository → DB
 *       dto  : api 가 JSON 으로 주고받는 모양     domain : DB 표와 대응하는 엔티티     config : 설정
 *
 * [4] 파일 목록
 *     ScanScheduler        시작 직후 한 번, 그 뒤 10초마다 ScanService.scanNow() 를 부른다     흐름 F-①
 *     BookScanner          books/ → book, book_file 표                                        흐름 F-③
 *     TranscriptScanner    *.jsonl → chat_message, team_message, team_member, book_session     흐름 F-④
 *
 * [5] 먼저 알 용어 (자세한 설명: docs/용어-풀이.md)
 *     @Scheduled, @EventListener, @Transactional, synchronized, Files·Path, 정규식
 *
 * [6] 읽는 순서
 *     ScanScheduler → (service/ScanService) → BookScanner → TranscriptScanner
 *
 * [7] 다 읽고 확인
 *     - 쭌의 답장이 대화방에 나타나기까지 거치는 클래스를 순서대로 적어 보라. (TranscriptScanner → chat_message → 폴링 흐름 B′)
 *     - 프로그램을 다시 켜면 대화 기록을 처음부터 다시 읽는데도 메시지가 두 번 저장되지 않는 이유는?
 */
package com.greendesk.publisher.scan;
