/*
 * [1] 역할
 *     정해진 때에 ScanService.scanNow() 를 부르는 클래스다. 브라우저 요청 없이 서버 혼자 실행된다.
 *       - 프로그램 시작이 끝났을 때 한 번 (first)
 *       - 그 뒤로 10초마다 (tick)
 *     scanNow() 가 책 폴더(books/)와 Claude Code 대화 기록(jsonl)을 읽어 DB 를 채운다.
 *
 * [2] 받는 것 → 내보내는 것 (실제로 실행해서 얻은 값)
 *     받는 것  : 없음 (요청이 아니라 시각에 맞춰 실행된다)
 *     내보내는 것: 콘솔 로그 한 줄 (실제 로그)
 *       INFO ... c.g.publisher.scan.ScanScheduler : 관리 화면 준비 완료: 책 5권, 기록 383건 읽음 → http://localhost:8080
 *
 * [3] 앞뒤 파일
 *     (스프링이 부름)  →  (이 파일)  →  service/ScanService.java 의 scanNow()
 *                                         →  scan/BookScanner.java, scan/TranscriptScanner.java
 *
 * [4] 메서드 목록
 *     메서드     언제 실행되나                          하는 일                       흐름 번호
 *     first()    프로그램 시작이 끝난 직후 한 번           책·기록을 읽고 로그를 남긴다      흐름 F-①
 *     tick()     시작 10초 뒤부터 10초 간격으로 계속        책·기록을 다시 읽는다             흐름 F-①
 *
 * [5] 먼저 알 용어 (자세한 설명: docs/용어-풀이.md)
 *     @Component, @EventListener, ApplicationReadyEvent, @Scheduled(fixedDelay), @EnableScheduling(PublisherDashboardApplication)
 *
 * [6] 읽는 순서
 *     생성자 → first() → tick()
 *
 * [7] 다 읽고 확인
 *     - application.yml 에서 publisher.scan-interval-ms 를 3000 으로 바꾸면 tick() 은 몇 초마다 실행되는가?
 *     - PublisherDashboardApplication 의 @EnableScheduling 을 지우면 tick() 은 실행되는가? (아니다. first() 는 실행된다)
 */
package com.greendesk.publisher.scan;

import com.greendesk.publisher.service.ScanService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.context.event.ApplicationReadyEvent;
import org.springframework.context.event.EventListener;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

/** 시작할 때 한 번, 그 뒤로 주기적으로 책 폴더와 대화 기록을 읽는다 */
// @Component
//   뜻     : 스프링이 이 클래스의 객체를 하나 만들어 관리한다.
//   결과   : 스프링이 객체를 만들 때 아래 @EventListener, @Scheduled 를 찾아 시각에 맞춰 메서드를 부른다.
//   없으면 : 객체가 만들어지지 않아 first(), tick() 이 한 번도 실행되지 않는다. 화면에 책이 하나도 안 보인다.
@Component
public class ScanScheduler {

    private static final Logger log = LoggerFactory.getLogger(ScanScheduler.class);
    // scans: 실제로 읽기 작업을 하는 ScanService 객체. 생성자로 받는다(생성자 주입).
    private final ScanService scans;

    public ScanScheduler(ScanService scans) {
        this.scans = scans;
    }

    // [흐름 F-①] 시작 직후 한 번
    // @EventListener(ApplicationReadyEvent.class)
    //   뜻     : 지정한 사건(event)이 일어나면 이 메서드를 부른다.
    //   받는 것: ApplicationReadyEvent = "스프링 시작이 모두 끝나 요청을 받을 수 있다"는 사건
    //   결과   : 프로그램을 켜고 몇 초 뒤 first() 가 한 번 실행된다.
    @EventListener(ApplicationReadyEvent.class)
    public void first() {
        // scanNow() 는 두 칸짜리 int 배열을 돌려준다.  n[0] = 읽은 책 폴더 수, n[1] = 새로 저장한 기록 수.
        // 예) n = [5, 383]
        int[] n = scans.scanNow();
        // {} 자리에 뒤의 값이 차례로 들어간다.
        // 실제 로그) 관리 화면 준비 완료: 책 5권, 기록 383건 읽음 → http://localhost:8080
        log.info("관리 화면 준비 완료: 책 {}권, 기록 {}건 읽음 → http://localhost:8080", n[0], n[1]);
    }

    // [흐름 F-①] 10초마다
    // @Scheduled(fixedDelayString = "...", initialDelayString = "...")
    //   뜻     : 이 메서드를 일정한 간격으로 계속 부른다.
    //   받는 것: fixedDelayString   = 앞 실행이 끝난 뒤 다음 실행까지 기다릴 밀리초. "${publisher.scan-interval-ms:10000}" → 설정값, 없으면 10000(10초)
    //            initialDelayString = 프로그램 시작 뒤 첫 실행까지 기다릴 밀리초 (first() 와 겹치지 않게 같은 10초)
    //   결과   : 시작 10초 뒤, 20초 뒤, 30초 뒤 … tick() 이 실행된다.
    //   fixedDelay 는 "끝난 뒤부터" 센다. 읽기가 3초 걸리면 실행 시작 간격은 13초가 된다.
    @Scheduled(fixedDelayString = "${publisher.scan-interval-ms:10000}", initialDelayString = "${publisher.scan-interval-ms:10000}")
    public void tick() {
        scans.scanNow();
    }
}
