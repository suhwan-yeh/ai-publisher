/*
 * [1] 역할
 *     이 프로그램 밖의 것과 연결하는 클래스 묶음. HTTP 로 fakechat(쭌)에 보내고, tmux 명령으로 팀원 화면을 읽는다.
 *
 * [2] 받는 것 → 내보내는 것 (실제로 실행해서 얻은 값)
 *     FakechatClient.send(…)  →  POST http://127.0.0.1:8787/upload (multipart)  →  204
 *     TmuxClient              →  tmux capture-pane 명령의 출력 글자
 *
 * [3] 앞뒤 파일
 *     계층 (화살표 = 부르는 방향, 거꾸로 부르지 않는다)
 *       브라우저 → controller / api → service → repository → DB
 *                                       service → client → fakechat(쭌), tmux
 *       scan(시각에 맞춰 실행) → service → scan 의 읽기 클래스 → repository → DB
 *       dto  : api 가 JSON 으로 주고받는 모양     domain : DB 표와 대응하는 엔티티     config : 설정
 *
 * [4] 파일 목록
 *     FakechatClient                  쭌에게 메시지 전달                        흐름 B-③
 *     ChannelUnavailableException     연결 실패 → 503                          흐름 D-②
 *     TmuxClient                      tmux 칸 목록·화면 글자 읽기                흐름 E
 *
 * [5] 먼저 알 용어 (자세한 설명: docs/용어-풀이.md)
 *     @Component, @Value, HttpClient, ProcessBuilder
 *
 * [6] 읽는 순서
 *     FakechatClient → ChannelUnavailableException → TmuxClient
 *
 * [7] 다 읽고 확인
 *     - 쭌이 출근하지 않았을 때 FakechatClient 는 무엇을 던지는가?
 *     - 이 패키지의 클래스는 DB 를 다루는가? (아니다)
 */
package com.greendesk.publisher.client;
