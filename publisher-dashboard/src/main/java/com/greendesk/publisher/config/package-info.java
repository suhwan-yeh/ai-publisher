/*
 * [1] 역할
 *     설정 값과 보안 설정 묶음. application.yml 의 publisher.* 값을 객체로 읽고, 서버(prod) 모드의 로그인 규칙을 정한다.
 *
 * [2] 받는 것 → 내보내는 것 (실제로 실행해서 얻은 값)
 *     application.yml  publisher.root: ${PUBLISHER_ROOT:~/my-publisher}
 *       → PublisherProperties.rootPath() = /root/my-publisher
 *
 * [3] 앞뒤 파일
 *     계층 (화살표 = 부르는 방향, 거꾸로 부르지 않는다)
 *       브라우저 → controller / api → service → repository → DB
 *                                       service → client → fakechat(쭌), tmux
 *       scan(시각에 맞춰 실행) → service → scan 의 읽기 클래스 → repository → DB
 *       dto  : api 가 JSON 으로 주고받는 모양     domain : DB 표와 대응하는 엔티티     config : 설정
 *
 * [4] 파일 목록
 *     PublisherProperties     publisher.* 설정 값과 폴더 경로
 *     StaffDirectory          직원 명부(staff.yml) 읽기
 *     SecurityConfig          로그인·CSRF 규칙 (publisher.security.enabled=true 일 때)
 *
 * [5] 먼저 알 용어 (자세한 설명: docs/용어-풀이.md)
 *     @Configuration, @ConfigurationProperties, @Bean, Spring Security(SecurityFilterChain)
 *
 * [6] 읽는 순서
 *     PublisherProperties → StaffDirectory → SecurityConfig
 *
 * [7] 다 읽고 확인
 *     - 환경변수 PUBLISHER_ROOT 를 /tmp/pub 으로 주면 rootPath() 는 무엇이 되는가?
 *     - 내 PC 모드에서 로그인 화면이 나오지 않는 이유는?
 */
package com.greendesk.publisher.config;
