/*
 * [1] 역할
 *     직원 영문 이름을 한글 이름·역할·팀으로 바꿔 주는 도구 클래스다. 모든 메서드가 static 이다.
 *     시작할 때 StaffDirectory 가 직원 명부(staff.yml)를 읽어 register() 로 등록한다. 등록 전에는 기본 4명이다.
 *
 * [2] 받는 것 → 내보내는 것 (실제로 실행해서 얻은 값)
 *     Names.korean("minjun")     → "민준"
 *     Names.role("seoyeon-2")    → "집필"         (번호가 붙은 이름도 같은 사람으로)
 *     Names.team("tepo")         → "ops"
 *     Names.isLead("team-lead")  → true
 *     Names.canonical("jihoon")  → "jihun"
 *     Names.seats()              → ["team-lead","minjun","jihun","seoyeon","taeyang","tepo"]
 *
 * [3] 앞뒤 파일
 *     config/StaffDirectory.java (등록)  →  (이 파일)  →  거의 모든 클래스가 이름을 바꿀 때 사용
 *
 * [4] 메서드 목록
 *     메서드                 하는 일
 *     register(쭌, 직원들)    명부 등록 (시작할 때 한 번)
 *     all()                  쭌 + 직원 목록
 *     seats()                영문 이름 목록 (자리 순서)
 *     bookTeamSize()         책 팀 인원 (점검 ① 기준)
 *     team(이름)             lead · book · ops
 *     isLead(이름)           쭌인가
 *     isStaff(이름)          명부에 있는 직원인가
 *     korean(이름)           한글 이름
 *     role(이름)             역할
 *     canonical(이름)        같은 사람의 다른 표기를 하나로
 *
 * [5] 먼저 알 용어 (자세한 설명: docs/용어-풀이.md)
 *     static 메서드, final 클래스, private 생성자, volatile, synchronized, Map, 정규식
 *
 * [6] 읽는 순서
 *     register() → canonical() → korean() → 나머지
 *
 * [7] 다 읽고 확인
 *     - canonical("Minjun-12") 의 결과는 무엇인가? ("minjun")
 *     - 명부에 없는 이름 "haneul" 을 korean() 에 넣으면 무엇을 돌려주는가? ("haneul" 그대로)
 */
package com.greendesk.publisher.domain;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;

/**
 * 영문 팀원 이름 → 한글 이름·역할·팀.
 * 기본값은 처음 4명이고, 시작할 때 직원 명부(staff.yml)를 읽으면 그 내용으로 바뀐다 (StaffDirectory).
 */
// final class : 이 클래스를 상속할 수 없다. 객체를 만들지 않고 Names.korean(…) 처럼 static 메서드만 쓰는 도구 클래스다.
public final class Names {

    public static final String LEAD = "team-lead";

    // volatile : 시작할 때 바뀐 값을 모든 스레드(동시에 처리되는 요청들)가 바로 보게 한다.
    private static volatile StaffMember lead = new StaffMember(LEAD, "쭌", "편집장", null, "lead", "#f08a5d");
    private static volatile Map<String, StaffMember> staff = defaults();

    // private 생성자 : new Names() 를 막는다.
    private Names() {
    }

    private static Map<String, StaffMember> defaults() {
        Map<String, StaffMember> m = new LinkedHashMap<>();
        m.put("minjun", new StaffMember("minjun", "민준", "기획", "planner", "book", "#5b8cff"));
        m.put("jihun", new StaffMember("jihun", "지훈", "자료 조사", "researcher", "book", "#3fbf8f"));
        m.put("seoyeon", new StaffMember("seoyeon", "서연", "집필", "writer", "book", "#b07cff"));
        m.put("taeyang", new StaffMember("taeyang", "태양", "교정·표지", "editor", "book", "#ffb547"));
        return m;
    }

    /** 직원 명부로 바꾸기 (시작할 때 한 번) */
    // synchronized : 두 스레드가 동시에 이 메서드를 실행하지 못하게 한다.
    public static synchronized void register(StaffMember newLead, List<StaffMember> members) {
        if (newLead != null) lead = newLead;
        Map<String, StaffMember> m = new LinkedHashMap<>();
        for (StaffMember s : members) m.put(s.name().toLowerCase(Locale.ROOT), s);
        staff = m;
    }

    /** 명부 전체 (쭌 먼저) */
    public static List<StaffMember> all() {
        List<StaffMember> out = new ArrayList<>();
        out.add(lead);
        out.addAll(staff.values());
        return out;
    }

    /** 사무실·회의실 자리 순서 (쭌이 맨 앞) */
    public static List<String> seats() {
        return all().stream().map(StaffMember::name).toList();
    }

    /** 책 만드는 팀 인원 (점검 ① 의 기준) */
    public static int bookTeamSize() {
        return (int) staff.values().stream().filter(s -> "book".equals(s.team())).count();
    }

    public static String team(String name) {
        if (isLead(name)) return "lead";
        StaffMember s = staff.get(canonical(name));
        return s == null ? "book" : s.team();
    }

    public static boolean isLead(String name) {
        if (name == null) return false;
        String n = name.toLowerCase(Locale.ROOT);
        return n.equals(LEAD) || n.equals("main") || n.equals("lead") || n.equals("쭌");
    }

    public static boolean isStaff(String name) {
        return name != null && staff.containsKey(canonical(name));
    }

    public static String korean(String name) {
        if (name == null) return "?";
        if (isLead(name)) return lead.korean();
        StaffMember s = staff.get(canonical(name));
        return s == null ? name : s.korean();
    }

    public static String role(String name) {
        if (isLead(name)) return lead.role();
        StaffMember s = name == null ? null : staff.get(canonical(name));
        return s == null ? "" : s.role();
    }

    /**
     * 같은 사람의 다른 표기를 하나로.
     *  - jihoon → jihun
     *  - minjun-2 → minjun : 같은 이름의 팀원이 남아 있을 때 Claude Code 가 붙이는 번호
     */
    public static String canonical(String name) {
        if (name == null) return null;
        // (1) 소문자로 바꾸고 앞뒤 공백을 지운다.
        // (2) 끝의 "-숫자" 를 지운다. 정규식 -\d+$ = 줄표 + 숫자 하나 이상 + 글자의 끝
        //     예) "minjun-2" → "minjun"   (이전 팀원이 남아 있을 때 Claude Code 가 새 팀원 이름에 번호를 붙인다)
        String n = name.toLowerCase(Locale.ROOT).trim().replaceFirst("-\\d+$", "");
        if (n.equals("jihoon")) return "jihun";
        if (isLead(n)) return LEAD;
        return n;
    }
}
