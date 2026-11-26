-- V1: 처음 표 만들기 (서버 MySQL 용, Flyway 가 한 번만 실행)
-- 내 PC(H2)에서는 JPA 가 엔티티를 보고 표를 만들기 때문에 이 파일을 쓰지 않습니다.
-- 엔티티(domain/*.java)를 바꾸면 이 파일을 고치지 말고 V2__설명.sql 을 새로 만드세요.

create table book (
    id            bigint       not null auto_increment,
    folder        varchar(255) not null,
    title         varchar(255),
    subtitle      varchar(255),
    genre         varchar(255),
    stage         enum ('ORDERED','PLANNED','WRITING','REVIEWING','COVER','DONE'),
    chapter_count integer      not null,
    char_count    integer      not null,
    created_at    datetime(6),
    updated_at    datetime(6),
    primary key (id),
    constraint uk_book_folder unique (folder)
) engine=InnoDB default charset=utf8mb4;

create table book_file (
    id      bigint not null auto_increment,
    book_id bigint not null,
    kind    enum ('PDF','EPUB','HTML','COVER'),
    size    bigint not null,
    primary key (id),
    constraint fk_book_file_book foreign key (book_id) references book (id)
) engine=InnoDB default charset=utf8mb4;

create table book_order (
    id       bigint not null auto_increment,
    text     longtext,
    chat_key varchar(255),
    at       datetime(6),
    primary key (id),
    constraint uk_book_order_chat_key unique (chat_key)
) engine=InnoDB default charset=utf8mb4;

create table book_session (
    id        bigint not null auto_increment,
    folder    varchar(255),
    team_name varchar(255),
    primary key (id),
    constraint uk_book_session unique (folder, team_name)
) engine=InnoDB default charset=utf8mb4;

create table chat_message (
    id               bigint       not null auto_increment,
    unique_key       varchar(255) not null,
    direction        enum ('FROM_BOSS','TO_BOSS'),
    text             longtext,
    attachments      varchar(255),
    attachment_paths longtext,
    channel          varchar(255),
    team_name        varchar(255),
    at               datetime(6),
    primary key (id),
    constraint uk_chat_message_key unique (unique_key)
) engine=InnoDB default charset=utf8mb4;

create table team_member (
    id          bigint not null auto_increment,
    team_name   varchar(255),
    name        varchar(255),
    role        varchar(255),
    first_seen  datetime(6),
    last_active datetime(6),
    primary key (id),
    constraint uk_team_member unique (team_name, name)
) engine=InnoDB default charset=utf8mb4;

create table team_message (
    id         bigint       not null auto_increment,
    unique_key varchar(255) not null,
    team_name  varchar(255),
    from_name  varchar(255),
    to_name    varchar(255),
    text       longtext,
    kind       enum ('TALK','REPORT','CONTROL'),
    at         datetime(6),
    primary key (id),
    constraint uk_team_message_key unique (unique_key)
) engine=InnoDB default charset=utf8mb4;
