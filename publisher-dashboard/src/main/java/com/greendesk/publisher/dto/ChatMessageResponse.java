/*
 * [1] 역할
 *     대화 메시지 한 건을 응답 JSON 으로 내보낼 때의 모양을 정한 클래스다.
 *     엔티티(ChatMessage)를 그대로 응답하지 않고, 화면에 필요한 값만 이 객체로 옮겨서 응답한다.
 *
 * [2] 받는 것 → 내보내는 것 (실제로 실행해서 얻은 값)
 *     받는 것        엔티티 ChatMessage(id=103, direction=FROM_BOSS, text="좋아요, 이대로 진행해 주세요.", channel="web", …)
 *     내보내는 것    {"id":103,"fromBoss":true,"text":"좋아요, 이대로 진행해 주세요.","at":"2026-11-09T21:46:33.776008Z","channel":"web","files":[]}
 *     첨부가 있는 예  "files":[{"name":"book.pdf","url":"/chat/59/file/0"}]
 *
 * [3] 앞뒤 파일
 *     domain/ChatMessage.java (엔티티)  →  (이 파일)  →  api/ChatApiController.java 가 응답으로 return  →  static/js/chatpanel.js 의 render()
 *
 * [4] 필드와 메서드 목록
 *     필드       자료형           뜻                                       예
 *     id         Long             메시지 번호 (DB 가 붙인 번호)              103
 *     fromBoss   boolean          사장님이 보낸 것이면 true, 쭌이면 false     true
 *     text       String           메시지 글자                               "좋아요, 이대로 진행해 주세요."
 *     at         Instant          보낸 시각 (JSON 에서는 글자로 나간다)       "2026-11-09T21:46:33.776008Z"
 *     channel    String           web(관리 화면) 또는 telegram               "web"
 *     files      List<FileLink>   첨부 파일의 이름과 내려받기 주소            []
 *
 *     메서드     하는 일
 *     from()     엔티티 ChatMessage 를 받아 ChatMessageResponse 를 만든다
 *
 * [5] 먼저 알 용어 (자세한 설명: docs/용어-풀이.md)
 *     record, 엔티티와 DTO 의 구분, static 메서드, List, Instant
 *
 * [6] 읽는 순서
 *     필드 목록 → from()
 *
 * [7] 다 읽고 확인
 *     - 엔티티에는 attachmentPaths(파일의 전체 경로)가 있다. 응답 JSON 에는 그 값이 있는가? 대신 무엇이 있는가?
 *     - fromBoss 의 값은 from() 의 어느 식에서 정해지는가?
 */
package com.greendesk.publisher.dto;

import com.greendesk.publisher.domain.ChatMessage;

import java.nio.file.Path;
import java.time.Instant;
import java.util.ArrayList;
import java.util.List;

/** 대화 메시지 하나 (엔티티를 그대로 내보내지 않고 화면에 필요한 값만) */
// record
//   뜻     : 값만 담는 클래스를 짧게 선언하는 자바 문법이다. 괄호 안에 적은 이름들이 필드가 된다.
//   결과   : 자바가 생성자, 필드 값을 꺼내는 메서드(예: text()), equals, toString 을 자동으로 만든다.
//            값을 바꾸는 메서드(setter)는 만들지 않는다. 한 번 만든 객체의 값은 바뀌지 않는다.
//   JSON   : 스프링이 이 객체를 JSON 으로 바꿀 때 필드 이름이 JSON 의 이름이 된다.
public record ChatMessageResponse(Long id, boolean fromBoss, String text, Instant at, String channel, List<FileLink> files) {

    // [흐름 B-⑤] 엔티티를 응답용 객체로 바꾼다. ChatApiController 가 ChatMessageResponse.from(엔티티) 로 호출한다.
    // static   : 객체를 만들지 않고 "클래스이름.메서드이름()" 으로 호출하는 메서드다.
    // ▶ 받는 값: ChatMessage m                 예) m.getId() = 103, m.getText() = "좋아요, 이대로 진행해 주세요."
    // ▶ 돌려주는 값: ChatMessageResponse        예) id=103, fromBoss=true, files=[]
    public static ChatMessageResponse from(ChatMessage m) {
        // 빈 목록을 만든다. 자료형: List<FileLink>.  아래 for 문에서 첨부 파일 수만큼 원소를 넣는다.   예) 처음에는 []
        List<FileLink> files = new ArrayList<>();
        // 엔티티에서 첨부 파일의 전체 경로 목록을 꺼낸다. 자료형: List<String>
        //   예) 첨부가 없으면 []      첨부가 있으면 ["/home/사용자/my-publisher/books/20261109-dogwalk/dist/book.pdf"]
        List<String> paths = m.attachmentPathList();
        // paths 의 원소 수만큼 반복한다. i 는 0 부터 시작한다.   예) 첨부가 1개면 i = 0 으로 한 번 실행
        for (int i = 0; i < paths.size(); i++) {
            // 아래 한 줄은 다음 순서로 실행된다.  (예: i = 0, paths.get(0) = "/home/…/dist/book.pdf", m.getId() = 59)
            //   (1) paths.get(i)                                 i 번째 경로를 꺼낸다.              "/home/…/dist/book.pdf"
            //   (2) Path.of(…).getFileName().toString()          경로에서 파일 이름만 남긴다.       "book.pdf"
            //   (3) "/chat/" + m.getId() + "/file/" + i          내려받기 주소를 만든다.            "/chat/59/file/0"
            //   (4) new FileLink((2), (3))                       이름과 주소를 담은 객체를 만든다.
            //   (5) files.add(…)                                 목록에 넣는다.
            // 전체 경로를 응답에 넣지 않는 이유: 서버 컴퓨터의 폴더 구조를 브라우저에 알릴 필요가 없기 때문이다.
            files.add(new FileLink(Path.of(paths.get(i)).getFileName().toString(), "/chat/" + m.getId() + "/file/" + i));
        }
        // 아래 두 줄로 응답용 객체를 만들어 return 한다. 괄호 안의 값 순서는 맨 위 record 선언의 필드 순서와 같다.
        //   m.getId()                                              → id        예) 103
        //   m.getDirection() == ChatMessage.Direction.FROM_BOSS    → fromBoss  방향이 FROM_BOSS 이면 true, 아니면 false
        //   m.getText()                                            → text
        //   m.getAt()                                              → at
        //   m.getChannel()                                         → channel   예) "web"
        //   files                                                  → files     위에서 만든 목록
        return new ChatMessageResponse(m.getId(), m.getDirection() == ChatMessage.Direction.FROM_BOSS,
                m.getText(), m.getAt(), m.getChannel(), files);
    }
}
