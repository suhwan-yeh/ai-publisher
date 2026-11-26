/*
 * [1] 역할
 *     이름 맞추기(domain/Names.java)를 시험한다. Claude Code 는 같은 직원을 jihoon, minjun-2 처럼 다르게 부를 때가 있다.
 *
 * [2] 받는 것 → 내보내는 것 (실제로 실행해서 얻은 값)
 *     Names.canonical("jihoon") → "jihun",  canonical("minjun-2") → "minjun",  canonical("Seoyeon-12") → "seoyeon"
 *     Names.korean("minjun-2") → "민준",  Names.role("seoyeon-2") → "집필",  Names.isStaff("taeyang-3") → true
 *
 * [3] 앞뒤 파일
 *     (이 파일)  →  domain/Names.java
 *
 * [4] 메서드 목록
 *     메서드          확인하는 것
 *     canonical()     다른 표기를 한 사람으로
 *
 * [5] 먼저 알 용어 (자세한 설명: docs/용어-풀이.md)
 *     @Test, @DisplayName, assertThat(…).isEqualTo(…), 스프링 없이 하는 시험(단위 시험)
 *
 * [6] 읽는 순서
 *     canonical()
 *
 * [7] 다 읽고 확인
 *     - 이 시험은 @SpringBootTest 가 없다. 그래서 무엇이 빠른가? (스프링·DB 를 켜지 않아 0.1초 안에 끝난다)
 *     - canonical("jihun-7") 은 무엇을 돌려줄까?
 */
package com.greendesk.publisher;

import com.greendesk.publisher.domain.Names;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;

class NamesTest {

    @Test
    @DisplayName("같은 사람의 다른 표기(jihoon, minjun-2)를 한 사람으로 본다")
    // 스프링을 켜지 않고 메서드만 불러 결과를 본다(단위 시험).
    void canonical() {
        assertThat(Names.canonical("jihoon")).isEqualTo("jihun");
        // 뒤의 "-숫자"를 지운다. Claude Code 가 같은 이름의 팀원을 다시 만들 때 붙인다.
        assertThat(Names.canonical("minjun-2")).isEqualTo("minjun");
        assertThat(Names.canonical("Seoyeon-12")).isEqualTo("seoyeon");
        assertThat(Names.canonical("team-lead")).isEqualTo("team-lead");
        assertThat(Names.korean("minjun-2")).isEqualTo("민준");
        assertThat(Names.role("seoyeon-2")).isEqualTo("집필");
        assertThat(Names.isStaff("taeyang-3")).isTrue();
    }
}
