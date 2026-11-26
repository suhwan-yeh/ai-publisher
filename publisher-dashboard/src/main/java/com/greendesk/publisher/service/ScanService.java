/*
 * [1] 역할
 *     책 폴더와 Claude 대화 기록 파일을 읽어 DB 에 반영하는 작업을 시작시키는 서비스다.
 *     실제로 파일을 읽는 코드는 scan/BookScanner.java, scan/TranscriptScanner.java 에 있다.
 *
 * [2] 받는 것 → 내보내는 것 (실제로 실행해서 얻은 값)
 *     scanNow()  →  돌려주는 값 int 배열 [읽은 책 수, 새로 저장한 기록 수]      예) [5, 379]  (처음 시작 때)
 *
 * [3] 앞뒤 파일
 *     scan/ScanScheduler.java (10초마다), service/ChatService.java, service/OfficeService.java, controller/DashboardController.java  →  (이 파일)  →  scan/BookScanner.java, scan/TranscriptScanner.java
 *
 * [4] 메서드 목록
 *     메서드                 하는 일                                                 흐름 번호
 *     scanNow()              지금 바로 두 스캐너를 실행한다                             흐름 F-②
 *     scanIfStale(ms)        마지막으로 읽은 지 ms 밀리초가 지났을 때만 scanNow() 를 실행한다
 *
 * [5] 먼저 알 용어 (자세한 설명: docs/용어-풀이.md)
 *     @Service, volatile, System.currentTimeMillis()
 *
 * [6] 읽는 순서
 *     scanNow() → scanIfStale()
 *
 * [7] 다 읽고 확인
 *     - 화면 세 개가 동시에 3초마다 messagesAfter() 를 호출해도 파일은 2초에 한 번만 읽힌다. 어느 줄 때문인가?
 *     - scanNow() 가 돌려주는 배열의 두 값은 각각 무엇인가?
 */
package com.greendesk.publisher.service;

import com.greendesk.publisher.scan.BookScanner;
import com.greendesk.publisher.scan.TranscriptScanner;
import org.springframework.stereotype.Service;

/** 책 폴더·대화 기록 읽기를 한곳에서 부른다 (스케줄러·화면·API 공용) */
// 스프링이 객체를 하나 만들어 필요한 곳에 넣어 주는 서비스 클래스. (뜻: ChatService.java 의 @Service 설명 참고)
@Service
public class ScanService {

    private final BookScanner books;
    private final TranscriptScanner transcripts;
    // 마지막으로 읽은 시각(1970-01-01 부터 지난 밀리초).   예) 1762724793776
    // volatile: 여러 스레드(동시에 처리되는 요청들)가 이 값을 읽고 쓸 때, 항상 가장 최근에 쓴 값을 읽게 한다.
    private volatile long lastScan;

    public ScanService(BookScanner books, TranscriptScanner transcripts) {
        this.books = books;
        this.transcripts = transcripts;
    }

    /** 지금 바로 읽기. 읽은 [책 수, 기록 수] */
    // [흐름 F-②] ScanScheduler 가 10초마다, 또는 화면 요청이 필요할 때 호출한다.
    public int[] scanNow() {
        // 지금 시각을 기록한다.   System.currentTimeMillis() = 현재 시각(밀리초)
        lastScan = System.currentTimeMillis();
        // [흐름 F-③] 책 폴더(~/my-publisher/books/*)를 읽어 book 표에 반영한다. b = 읽은 책 수
        int b = books.scan();
        // [흐름 F-④] 대화 기록 파일(*.jsonl)의 새 줄을 읽어 chat_message, team_message 표에 저장한다. m = 새로 저장한 건수
        int m = transcripts.scan();
        return new int[]{b, m};
    }

    /** 화면을 보는 동안 자주 불려도 최소 간격(ms)마다 한 번만 읽는다 */
    public void scanIfStale(long minIntervalMs) {
        // 지금 시각 - 마지막으로 읽은 시각 ≥ 최소 간격 이면 읽는다.
        // 예) 지금 = 10000, lastScan = 9000, minIntervalMs = 2000 → 1000 ≥ 2000 은 거짓 → 읽지 않는다
        if (System.currentTimeMillis() - lastScan >= minIntervalMs) scanNow();
    }
}
