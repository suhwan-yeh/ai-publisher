/*
 * [1] 역할
 *     파일 내려받기 응답(ResponseEntity)을 만드는 작은 도우미 클래스다. DashboardController.download() 와 ChatPageController.file() 이 함께 쓴다.
 *
 * [2] 받는 것 → 내보내는 것 (실제로 실행해서 얻은 값)
 *     받는 것  DownloadFile(path=…/20261109-dogwalk/dist/book.pdf, fileName="꼬리 살랑, 첫 산책.pdf", mediaType="application/pdf", inline=false)
 *     내보내는 것 (GET /download/3/pdf 의 실제 응답 머리)
 *       HTTP/1.1 200
 *       Content-Disposition: attachment; filename="=?UTF-8?Q?=EA=BC=AC=EB=A6=AC_=EC=82=B4=EB=9E=91,_=EC=B2=AB_=EC=82=B0=EC=B1=85.pdf?="; filename*=UTF-8''%EA%BC%AC%EB%A6%AC%20%EC%82%B4%EB%9E%91%2C%20%EC%B2%AB%20%EC%82%B0%EC%B1%85.pdf
 *       Content-Type: application/pdf
 *       Content-Length: 389934
 *       (몸통: 파일 바이트 389934개)
 *     표지(GET /download/3/cover)는 inline=true 라서 Content-Disposition: inline; … , Content-Type: image/svg+xml
 *
 * [3] 앞뒤 파일
 *     controller/DashboardController.java, controller/ChatPageController.java  →  (이 파일)
 *     받는 값의 모양: service/DownloadFile.java
 *
 * [4] 메서드 목록
 *     메서드          하는 일
 *     of(파일)        200 + Content-Type + Content-Disposition + 파일 몸통으로 된 응답을 만든다
 *
 * [5] 먼저 알 용어 (자세한 설명: docs/용어-풀이.md)
 *     ResponseEntity, FileSystemResource, Content-Disposition(inline / attachment), final class, private 생성자
 *
 * [6] 읽는 순서
 *     of()
 *
 * [7] 다 읽고 확인
 *     - inline 이 true 이면 브라우저는 파일을 어떻게 처리하는가? (내려받지 않고 새 탭에서 바로 연다. 예: 표지 SVG)
 *     - filename 에 UTF_8 을 주지 않으면 한글 파일 이름은 어떻게 되는가?
 */
package com.greendesk.publisher.controller;

import com.greendesk.publisher.service.DownloadFile;
import org.springframework.core.io.FileSystemResource;
import org.springframework.http.ContentDisposition;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;

import java.nio.charset.StandardCharsets;

/** 파일 내려받기 응답 만들기 (화면용 컨트롤러 공용) */
// final class: 다른 클래스가 이 클래스를 상속할 수 없다. public 이 없으므로 같은 controller 패키지에서만 쓸 수 있다.
final class FileResponses {

    // private 생성자: new FileResponses() 를 못 하게 막는다. static 메서드만 쓰는 클래스이기 때문이다.
    private FileResponses() {
    }

    static ResponseEntity<FileSystemResource> of(DownloadFile f) {
        // Content-Disposition 헤더를 만든다 (아래 두 줄)
        // (1) inline() 이면 "inline"(브라우저 안에서 열기), 아니면 "attachment"(내려받기)
        // (2) .filename(이름, UTF_8)  저장할 때의 파일 이름.  예) "꼬리 살랑, 첫 산책.pdf"  한글이 깨지지 않게 UTF-8 로 적는다.
        // (3) .build()               완성.  한글 이름은 두 가지 모양으로 함께 적힌다.
        //     filename="=?UTF-8?Q?…?="            옛 브라우저용
        //     filename*=UTF-8''%EA%BC%AC…        요즘 브라우저용 (UTF-8 바이트를 %XX 로 적은 것)
        //     브라우저는 저장할 때 "꼬리 살랑, 첫 산책.pdf" 로 되돌린다.
        ContentDisposition cd = (f.inline() ? ContentDisposition.inline() : ContentDisposition.attachment())
                .filename(f.fileName(), StandardCharsets.UTF_8).build();
        // 응답을 만든다 (아래 네 줄)
        //   ok()                     상태코드 200
        //   contentType(…)           Content-Type: application/pdf
        //   header(…)                Content-Disposition: attachment; …
        //   body(FileSystemResource)  몸통 = 디스크의 파일. 스프링이 파일을 읽어 바이트로 보낸다.
        return ResponseEntity.ok()
                .contentType(MediaType.parseMediaType(f.mediaType()))
                .header(HttpHeaders.CONTENT_DISPOSITION, cd.toString())
                .body(new FileSystemResource(f.path()));
    }
}
