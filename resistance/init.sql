create table player(id char(32) not null primary key, room int(4), role boolean, voted boolean, msgid bigint(20));
create table name(id char(32) not null primary key, name tinytext, nick tinytext);
create table room(roomid int(4), roleflag int(3), totalnumber int(4), currentnumber int(4), turn int(1), votes int(2), disagree int(1), status int(1), success int(1), fail int(1), deny int(1), last char(100));
