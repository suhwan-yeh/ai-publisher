/*
 * [1] 역할
 *     내려받을 파일의 정보(경로, 받을 때 이름, 파일 종류, 브라우저에서 바로 열지 여부)를 담는 값 객체다.
 *     서비스가 이 객체를 만들고, 화면용 컨트롤러가 이 값으로 파일 응답을 만든다.
 *
 * [2] 받는 것 → 내보내는 것 (실제로 실행해서 얻은 값)
 *     예) DownloadFile(path=/home/…/dist/book.pdf, fileName="꼬리 살랑, 첫 산책.pdf", mediaType="application/pdf", inline=false)
 *        → 응답 헤더  Content-Type: application/pdf
 *                    Content-Disposition: attachment; filename*=UTF-8''%EA%BC%AC…pdf
 *
 * [3] 앞뒤 파일
 *     service/DashboardService.java 의 download(), controller/ChatPageController.java  →  (이 파일)  →  controller/FileResponses.java
 *
 * [4] 필드 목록
 *     필드        자료형    뜻
 *     path        Path      서버 컴퓨터의 파일 위치
 *     fileName    String    브라우저가 저장할 때 쓸 파일 이름
 *     mediaType   String    파일 종류 (Content-Type 헤더 값)       예) "application/pdf", "image/svg+xml"
 *     inline      boolean   true = 브라우저 창에서 바로 연다, false = 파일로 저장한다
 *
 * [5] 먼저 알 용어 (자세한 설명: docs/용어-풀이.md)
 *     record, Content-Type, Content-Disposition
 *
 * [6] 읽는 순서
 *     필드 목록이 전부다.
 *
 * [7] 다 읽고 확인
 *     - 표지 그림(cover.svg)은 inline 이 true 다. 브라우저에서 어떻게 다르게 동작하는가?
 *     - 이 객체는 JSON 으로 응답되는가? (아니다. 파일 응답을 만드는 데에만 쓴다)
 */
package com.greendesk.publisher.service;

import java.nio.file.Path;

/** 내려받을 파일 정보 (컨트롤러가 응답을 만들 때 씀) */
// record: 값만 담는 클래스. (자세한 설명: dto/SendMessageRequest.java 의 record 설명)
public record DownloadFile(Path path, String fileName, String mediaType, boolean inline) {
}
