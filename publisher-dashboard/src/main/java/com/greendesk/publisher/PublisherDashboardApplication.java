/*
 * [1] 역할
 *     관리 화면 프로그램의 시작점(main 메서드)이다. 이 클래스를 실행하면 스프링 부트가 시작된다.
 *     IntelliJ 의 "관리화면 실행" 도, java -jar publisher-dashboard.jar 도 결국 이 main 을 실행한다.
 *
 * [2] 받는 것 → 내보내는 것 (실제로 실행해서 얻은 값)
 *     실행 명령  java -jar publisher-dashboard.jar
 *     실제 콘솔 출력(마지막 줄)  관리 화면 준비 완료: 책 5권, 기록 379건 읽음 → http://localhost:8080
 *
 * [3] 앞뒤 파일
 *     (이 파일)  →  스프링 부트가 같은 패키지와 그 아래(com.greendesk.publisher.*)의 @Controller, @Service, @Component, Repository 를 찾아 객체를 만든다
 *
 * [4] 메서드 목록
 *     메서드          하는 일
 *     main(args)      스프링 부트를 시작한다: 설정 읽기 → 객체 만들기 → 내장 웹 서버(톰캣) 8080 포트 열기
 *
 * [5] 먼저 알 용어 (자세한 설명: docs/용어-풀이.md)
 *     main 메서드, @SpringBootApplication, @EnableScheduling, @EnableConfigurationProperties
 *
 * [6] 읽는 순서
 *     어노테이션 세 개 → main()
 *
 * [7] 다 읽고 확인
 *     - 이 파일을 com.greendesk 패키지로 옮기면 무엇이 달라지는가? (찾는 범위가 넓어진다. 지금 구조에서는 같은 결과)
 *     - @EnableScheduling 을 지우면 ScanScheduler 의 10초 반복은 어떻게 되는가? (실행되지 않는다)
 */
package com.greendesk.publisher;

import com.greendesk.publisher.config.PublisherProperties;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.context.properties.EnableConfigurationProperties;
import org.springframework.scheduling.annotation.EnableScheduling;

/**
 * 1인 AI 출판사 관리 화면.
 * 책 폴더(~/my-publisher/books)와 Claude 대화 기록(~/.claude/projects)을 읽기만 해서
 * 팀원 생성 · 팀원 간 메시지 · 보고 · 파일 도착을 한눈에 보여 준다.
 */
// @SpringBootApplication
//   뜻     : 스프링 부트 프로그램의 시작 클래스라는 표시. 세 가지를 한꺼번에 켠다.
//            (1) 이 패키지 아래의 @Component 계열 클래스를 찾아 객체로 만든다
//            (2) build.gradle 에 넣은 라이브러리(web, JPA, Thymeleaf…)에 맞는 기본 설정을 자동으로 한다
//            (3) 이 클래스를 설정 클래스로 쓴다
@SpringBootApplication
// @EnableScheduling : @Scheduled 가 붙은 메서드(ScanScheduler.tick)를 정해진 간격으로 실행하는 기능을 켠다.
@EnableScheduling
// @EnableConfigurationProperties : application.yml 의 publisher.* 값을 PublisherProperties 객체로 만들어 스프링에 등록한다.
@EnableConfigurationProperties(PublisherProperties.class)
public class PublisherDashboardApplication {
    public static void main(String[] args) {
        // 스프링 부트를 시작한다. 이 줄은 프로그램이 끝날 때까지 돌아오지 않는다(웹 서버가 요청을 계속 기다린다).
        // args = 명령줄 인자.   예) --spring.profiles.active=prod
        SpringApplication.run(PublisherDashboardApplication.class, args);
    }
}
