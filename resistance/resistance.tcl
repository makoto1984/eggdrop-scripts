set db(user) "thumed"
set db(password) "1727"
set db(name) "resistance"
set chan "#resistance-game"
array set roles {
    5 2
    6 2
    7 3
    8 3
    9 3
    10 4
}
array set tasks {
    5 {2 3 2 3 3}
    6 {2 3 4 3 4}
    7 {2 3 3 4 4}
    8 {3 4 4 5 5}
    9 {3 4 4 5 5}
    10 {3 4 4 5 5}
}
array set rolename {
    0 "抵抗者"
    1 "间谍"
}

package require mysqltcl

bind join - * resistance:join
bind nick - * resistance:nick
bind part - * resistance:part
bind msg - "name" resistance:name
bind msg - "n" resistance:name
bind msg - "名字" resistance:name
bind msg - "help" resistance:help
bind msg - "h" resistance:help
bind msg - "帮助" resistance:help
bind msg - "create" resistance:create
bind msg - "c" resistance:create
bind msg - "创建" resistance:create
bind msg - "join" resistance:enter
bind msg - "j" resistance:enter
bind msg - "加入" resistance:enter
bind msg - "quit" resistance:quit
bind msg - "q" resistance:quit
bind msg - "退出" resistance:quit
bind msg - "1" resistance:pros
bind msg - "0" resistance:cons
#bind msg - "deny" resistance:deny
#bind msg - "d" resistance:deny

proc roleflag {number} {
    global roles
    set pool {}
    set i 0
    while {$i < $roles($number)} {
	lappend pool 1
	incr i
    }
    set i 0
    while {$i < $number - $roles($number)} {
	lappend pool 0
	incr i
    }
    set len $number
    while {$len} {
        set i [expr {int($len*rand())}]
        set tmp [lindex $pool $i]
        lset pool $i [lindex $pool [incr len -1]]
        lset pool $len $tmp
    }
    set i 0
    set flag 0
    while {$i < $number} {
	incr flag [expr int([lindex $pool $i]*[expr pow(2,$i)])]
	incr i
    }
    return $flag
}

proc getrole {roleflag order} {
    set role [expr $roleflag & int(pow(2,$order-1))]
    if {$role > 0} {
	return 1
    } else {
	return 0
    }
}


proc resistance:join {nick host handle channel} {
    global db
    putserv "PRIVMSG $channel :欢迎$nick。"
    set id [md5 $host]
    set link [mysqlconnect -user $db(user) -password $db(password) -db $db(name)]
    mysqluse $link $db(name)
    set fetchname [mysqlsel $link "SELECT name FROM name WHERE id=\"$id\" LIMIT 1" -flatlist]
    mysqlendquery $link
    mysqlclose $link
    putserv "PRIVMSG $nick :欢迎来到抵抗组织IRC频道\002#resistance-game\002。我是\002resistance\002人工智能(zhàng)，请多指教。"
    if {$fetchname == ""} {
	putserv "PRIVMSG $nick :您好像是第一次来哦。如果不了解抵抗组织的游戏规则，请参考\026http://hahamirror.ga/resistance.jpg\026"
	putserv "PRIVMSG $nick :在频道中您可以和其他玩家进行交流，您发的信息是公开的。如果您是第一次来，请设定您的昵称以便其他玩家知道您是谁。方法是在这里输入\002name 您的昵称\002"
	putserv "PRIVMSG $nick :name后有空格。昵称为空时查询当前昵称。昵称可以更改。注意，当您变更登录地点后可能需要重新设定昵称。"
	putserv "PRIVMSG $nick :游戏中您发送的指令不应在频道中——您应该发在这里。"
	putserv "PRIVMSG $nick :关于如何游戏，请在这里输入\002help\002。"
    } else {
	putserv "PRIVMSG $channel :$nick在游戏中的昵称是$fetchname。"
	putserv "PRIVMSG $nick :欢迎回来，$fetchname。"
	putserv "PRIVMSG $nick :要改变昵称，请在这里输入\002name 您的昵称\002"
	putserv "PRIVMSG $nick :忘记了命令？请在这里输入\002help\002"
    }
}

proc resistance:nick {nick host handle channel newnick} {
    global db
    set id [md5 $host]
    set link [mysqlconnect -user $db(user) -password $db(password) -db $db(name)]
    mysqluse $link $db(name)
    set fetchnick [mysqlsel $link "SELECT nick FROM name WHERE id=\"$id\" LIMIT 1" -flatlist]
    mysqlendquery $link
    mysqlsel $link "UPDATE name SET nick=\"$newnick\" WHERE id=\"$id\""
    mysqlendquery $link
    mysqlclose $link
}

proc resistance:part {nick host handle channel msg} {
    putserv "PRIVMSG $nick :祝您身体健康，再见。"
}

proc resistance:name {nick host handle text} {
    global db chan
    set id [md5 $host]
    set name [string trim $text]
    set link [mysqlconnect -user $db(user) -password $db(password) -db $db(name)]
    mysqluse $link $db(name)
    set fetchname [mysqlsel $link "SELECT name FROM name WHERE id=\"$id\" LIMIT 1" -flatlist]
    mysqlendquery $link
    if {$name == ""} {
	if {$fetchname == ""} {
	    putserv "PRIVMSG $nick :您尚未设定昵称。"
	} else {
	    putserv "PRIVMSG $nick :您的昵称是$fetchname。"
	}
    } else {
	if {$fetchname == ""} {
	    mysqlsel $link "INSERT INTO name (id,name,nick) VALUES (\"$id\",\"$name\",\"$nick\")"
	    mysqlendquery $link
	    putserv "PRIVMSG $nick :您的昵称已设为$name。"
	    putserv "PRIVMSG $chan :$nick将自己的昵称设为$name。"
	} else {
	    set ingame [mysqlsel $link "SELECT id FROM player WHERE id=\"$id\" LIMIT 1"]
	    mysqlendquery $link
	    if {$ingame == 0} {
		mysqlsel $link "UPDATE name SET name=\"$name\" WHERE id=\"$id\""
		mysqlendquery $link
		putserv "PRIVMSG $nick :您的昵称已改为$name。"
		putserv "PRIVMSG $chan :$nick\($fetchname\)将自己的昵称改为$name。"
	    } else {
		putserv "PRIVMSG $nick :请在游戏结束后更改昵称。"
	    }
	}
   }
    mysqlclose $link
}

proc resistance:help {nick host handle text} {
    puthelp "PRIVMSG $nick :请先了解游戏规则。"
    puthelp "PRIVMSG $nick :可以使用的命令如下，所有单词均可简化为首字母，注意单词后有空格。"
    puthelp "PRIVMSG $nick :\002name 昵称\002 \t\t设定昵称。"
    puthelp "PRIVMSG $nick :\002create 游戏人数\002 \t创建一个新游戏房间，游戏人数为5至10人。获取房间号。"
    puthelp "PRIVMSG $nick :\002join 房间号\002 \t\t加入一个已经创建的房间。"
    puthelp "PRIVMSG $nick :\0021\002 \t赞成组队提议或做任务。"
    puthelp "PRIVMSG $nick :\0020\002 \t反对组队提议或破坏任务。"
#    puthelp "PRIVMSG $nick :\002deny\002 \t发动“不受信任”，推翻成功的组队。未持有此卡者请勿发动。"
    puthelp "PRIVMSG $nick :\002quit\002 \t\t终止游戏，注销房间。所有人离开房间。"
}

proc resistance:create {nick host handle text} {
    global db chan roles rolename
    regexp {^([5-9]|10)$} [string trim $text] number
    if {[info exists number]} {
	set id [md5 $host]
	set link [mysqlconnect -user $db(user) -password $db(password) -db $db(name)]
	mysqluse $link $db(name)
	set fetchname [mysqlsel $link "SELECT name FROM name WHERE id=\"$id\" LIMIT 1" -flatlist]
	mysqlendquery $link
	if {$fetchname == ""} {
	    putserv "PRIVMSG $nick :请先设定昵称。"
	} else {
	    set testroom [mysqlsel $link "SELECT room FROM player WHERE id=\"$id\"" -flatlist]
	    mysqlendquery $link
	    if {$testroom == ""} {
		set testlimit [mysqlsel $link "SELECT COUNT(*) AS totalrooms FROM room" -flatlist]
		mysqlendquery $link
		if {$testlimit == 9000} {
		    putserv "PRIVMSG $nick :总房间数已达上限，请稍后再来。"
		    return
		}
		set roomlist [mysqlsel $link "SELECT roomid FROM room" -flatlist]
		mysqlendquery $link
		while 1 {
		    set roomid [expr int([expr rand() * 8999 + 1000])]
		    if {[lsearch $roomlist $roomid] < 0} {
			break
		    }
		}
		set flags [roleflag $number]
		set flag [getrole $flags 1]
		mysqlsel $link "INSERT INTO player (id,room,role,voted) VALUES (\"$id\",$roomid,$flag,FALSE)"
		mysqlendquery $link
		mysqlsel $link "INSERT INTO room (roomid,roleflag,totalnumber,currentnumber,turn,votes,disagree,status,success,fail,deny,last) VALUES ($roomid,$flags,$number,1,0,0,0,0,0,0,0,\"还没有进行过投票。\")"
		mysqlendquery $link
		putserv "PRIVMSG $nick :您创建了$number人房间，房间号$roomid。"
		putserv "PRIVMSG $nick :抵抗者[expr $number-$roles($number)]人，间谍$roles($number)人。"
		putserv "PRIVMSG $nick :您的身份是$rolename($flag)。"
		putserv "PRIVMSG $chan :$nick\($fetchname\)创建了游戏房间$roomid。"
	    } else {
		putserv "PRIVMSG $nick :您已在房间$testroom中。"
	    }
	}
	mysqlclose $link
    } else {
	putserv "PRIVMSG $nick :请输入正确人数(5~10)。"
    }
}

proc resistance:enter {nick host handle text} {
    global db chan roles rolename tasks
    regexp {^\d{4}$} [string trim $text] room
    if {[info exists room]} {
	set id [md5 $host]
	set link [mysqlconnect -user $db(user) -password $db(password) -db $db(name)]
	mysqluse $link $db(name)
	set fetchname [mysqlsel $link "SELECT name FROM name WHERE id=\"$id\" LIMIT 1" -flatlist]
	mysqlendquery $link
	if {$fetchname == ""} {
	    putserv "PRIVMSG $nick :请先设定昵称。"
	} else {
	    set testroom [mysqlsel $link "SELECT room FROM player WHERE id=\"$id\" LIMIT 1" -flatlist]
	    mysqlendquery $link
	    if {$testroom == ""} {
		set testexist [mysqlsel $link "SELECT totalnumber,currentnumber,roleflag FROM room WHERE roomid=$room LIMIT 1" -flatlist]
		mysqlendquery $link
		if {$testexist == ""} {
		    putserv "PRIVMSG $nick :该房间不存在。"
		} else {
		    if {[lindex $testexist 0] == [lindex $testexist 1]} {
			putserv "PRIVMSG $nick :该房间已满。"
		    } else {
			set flag [getrole [lindex $testexist 2] [expr [lindex $testexist 1]+1]]
			putserv "PRIVMSG $nick :您已加入[lindex $testexist 0]人房间$room。"
			putserv "PRIVMSG $nick :您的身份是$rolename($flag)。"
			set idlist [mysqlsel $link "SELECT id FROM player WHERE room=$room" -flatlist]
			mysqlendquery $link
			set calllist {}
			foreach member $idlist {
			    set callid [mysqlsel $link "SELECT nick FROM name WHERE id=\"$member\" LIMIT 1" -flatlist]
			    mysqlendquery $link
			    lappend calllist $callid
			    putserv "PRIVMSG $callid :$fetchname加入了游戏。"
			}
			mysqlsel $link "INSERT INTO player (id,room,role,voted) VALUES (\"$id\",$room,$flag,FALSE)"
			mysqlendquery $link
			mysqlsel $link "UPDATE room SET currentnumber=[expr [lindex $testexist 1]+1] WHERE roomid=$room"
			mysqlendquery $link
			putserv "PRIVMSG $chan :$nick\($fetchname\)加入了游戏房间$room。"
			if {[lindex $testexist 0] == [expr [lindex $testexist 1]+1]} {
			    mysqlsel $link "UPDATE room SET status=1 WHERE roomid=$room"
			    mysqlendquery $link
			    set spylist [mysqlsel $link "SELECT id FROM player WHERE room=$room AND role=1" -flatlist]
			    mysqlendquery $link
			    set spycallids {}
			    set spynames {}
			    foreach member $spylist {
				set temp [mysqlsel $link "SELECT nick,name FROM name WHERE id=\"$member\" LIMIT 1" -flatlist]
				lappend spycallids [lindex $temp 0]
				lappend spynames [lindex $temp 1]
			    }
			    foreach member $spycallids {
				putserv "PRIVMSG $member :间谍有$spynames。"
			    }
			    lappend calllist $nick
			    foreach member $calllist {
				putserv "PRIVMSG $member :房间已满。抵抗者[expr [lindex $testexist 0]-$roles([lindex $testexist 0])]人，间谍$roles([lindex $testexist 0])人。"
				putserv "PRIVMSG $member :请领袖选出[lindex $tasks([lindex $testexist 0]) 0]人组队。"
			    }
			} else {
			    putserv "PRIVMSG $nick :还需要[expr [lindex $testexist 0]-[lindex $testexist 1]-1]位玩家。"
			}
		    }
		}
	    } else {
		putserv "PRIVMSG $nick :您已在房间$testroom中。"
	    }
	}
	mysqlclose $link
    } else {
	putserv "PRIVMSG $nick :房间号为四位数，请重新输入。"
    }
}

proc resistance:quit {nick host handle text} {
    global db chan
    set id [md5 $host]
    set link [mysqlconnect -user $db(user) -password $db(password) -db $db(name)]
    mysqluse $link $db(name)
    set testroom [mysqlsel $link "SELECT room FROM player WHERE id=\"$id\" LIMIT 1" -flatlist]
    mysqlendquery $link
    if {$testroom == ""} {
	putserv "PRIVMSG $nick :您不在任何房间中。"
    } else {
	set user [mysqlsel $link "SELECT name FROM name WHERE id=\"$id\" LIMIT 1" -flatlist]
	mysqlendquery $link
	set idlist [mysqlsel $link "SELECT id FROM player WHERE room=$testroom" -flatlist]
	mysqlendquery $link
	mysqlsel $link "DELETE FROM player WHERE room=$testroom"
	mysqlendquery $link
	mysqlsel $link "DELETE FROM room WHERE roomid=$testroom"
	mysqlendquery $link
	foreach member $idlist {
	    set callid [mysqlsel $link "SELECT nick FROM name WHERE id=\"$member\" LIMIT 1" -flatlist]
	    mysqlendquery $link
	    putserv "PRIVMSG $callid :$user注销了房间$testroom。"
	}
	putserv "PRIVMSG $chan :房间$testroom被注销。"
    }
    mysqlclose $link
}

proc resistance:pros {nick host handle text} {
    global db tasks chan
    set id [md5 $host]
    set link [mysqlconnect -user $db(user) -password $db(password) -db $db(name)]
    mysqluse $link $db(name)
    set testid [mysqlsel $link "SELECT room,role,voted FROM player WHERE id=\"$id\" LIMIT 1" -flatlist]
    mysqlendquery $link
    if {$testid == ""} {
	putserv "PRIVMSG $nick :您不在任何房间中。"
    } else {
	if {[lindex $testid 2] == 1} {
	    putserv "PRIVMSG $nick :您已投票。"
	} else {
	    set testroom [mysqlsel $link "SELECT totalnumber,currentnumber,turn,votes,disagree,status,success,fail,deny FROM room WHERE roomid=[lindex $testid 0] LIMIT 1" -flatlist]
	    mysqlendquery $link
	    set votes [lindex $testroom 3]
	    set disagree [lindex $testroom 4]
	    switch [lindex $testroom 5] {
		0 {
		    putserv "PRIVMSG $nick :房间未满，还需要[expr [lindex $testroom 0]-[lindex $testroom 1]]位玩家。"
		}
		1 {
		    incr votes
		    putserv "PRIVMSG $nick :投票成功。"
		    mysqlsel $link "UPDATE player SET voted=TRUE WHERE id=\"$id\""
		    mysqlendquery $link
		    mysqlsel $link "UPDATE room SET disagree=$disagree,votes=$votes WHERE roomid=[lindex $testid 0]"
		    mysqlendquery $link
		    if {$votes == [lindex $testroom 0]} {
			mysqlsel $link "UPDATE player SET voted=FALSE WHERE room=[lindex $testid 0]"
			mysqlendquery $link
			mysqlsel $link "UPDATE room SET votes=0,disagree=0 WHERE roomid=[lindex $testid 0]"
			mysqlendquery $link
			set idlist [mysqlsel $link "SELECT id FROM player WHERE room=[lindex $testid 0]" -flatlist]
			mysqlendquery $link
			set calllist {}
			foreach member $idlist {
			    set callid [mysqlsel $link "SELECT nick FROM name WHERE id=\"$member\" LIMIT 1" -flatlist]
			    mysqlendquery $link
			    lappend calllist $callid
			}
			if {$disagree >= ceil($votes/2)} {
			    set deny [expr [lindex $testroom 8]+1]
			    set msg "[expr $votes-$disagree]人支持，$disagree人反对，组队失败。这是第$deny次组队失败。"
			    if {$deny == 5} {
				set tempmsg "游戏结束，间谍胜利。"
				set msg $msg$tempmsg
				foreach member $calllist {
				    putserv "PRIVMSG $member :$msg"
				}
				mysqlsel $link "DELETE FROM player WHERE room=[lindex $testid 0]"
				mysqlendquery $link
				mysqlsel $link "DELETE FROM room WHERE roomid=[lindex $testid 0]"
				mysqlendquery $link
				mysqlclose $link
				putserv "PRIVMSG $chan :房间[lindex $testid 0]游戏结束，间谍胜利。"
				return
			    }
			    foreach member $calllist {
				putserv "PRIVMSG $member :$msg"
			    }
			    mysqlsel $link "UPDATE room SET deny=$deny,last=\"$msg\" WHERE roomid=[lindex $testid 0]"
			    mysqlendquery $link
			} else {
			    set msg "[expr $votes-$disagree]人支持，$disagree人反对，组队成功。请开始做任务。"
			    foreach member $calllist {
				putserv "PRIVMSG $member :$msg"
			    }
			    mysqlsel $link "UPDATE room SET turn=[expr [lindex $testroom 2]+1],status=2,last=\"$msg\" WHERE roomid=[lindex $testid 0]"
			    mysqlendquery $link
			}
		    }
		}
		2 {
		    set maxtask [lindex $tasks([lindex $testroom 0]) [expr [lindex $testroom 2]-1]]
		    incr votes
		    putserv "PRIVMSG $nick :投票成功（抵抗者一律视为做任务）。"
		    mysqlsel $link "UPDATE player SET voted=TRUE WHERE id=\"$id\""
		    mysqlendquery $link
		    mysqlsel $link "UPDATE room SET votes=$votes WHERE roomid=[lindex $testid 0]"
		    mysqlendquery $link
		    set idlist [mysqlsel $link "SELECT id FROM player WHERE room=[lindex $testid 0]" -flatlist]
		    mysqlendquery $link
		    set calllist {}
		    foreach member $idlist {
			set callid [mysqlsel $link "SELECT nick FROM name WHERE id=\"$member\" LIMIT 1" -flatlist]
			mysqlendquery $link
			lappend calllist $callid
		    }
		    if {$votes == $maxtask} {
			mysqlsel $link "UPDATE player SET voted=FALSE WHERE room=[lindex $testid 0]"
			mysqlendquery $link
			mysqlsel $link "UPDATE room SET votes=0,disagree=0,deny=0 WHERE roomid=[lindex $testid 0]"
			mysqlendquery $link
			if {[lindex $testroom 0] >= 7 && [lindex $testroom 2] == 4} {
			    set allowfail 1
			} else {
			    set allowfail 0
			}
			if {$disagree > $allowfail} {
			    set msg "$disagree人破坏任务，第[lindex $testroom 2]回合任务失败。"
			    set fail [expr [lindex $testroom 7]+1]
			    if {$fail == 3} {
				set temp "游戏结束，间谍胜利。"
				set msg $msg$temp
				foreach member $calllist {
				    putserv "PRIVMSG $member :$msg"
				}
				mysqlsel $link "DELETE FROM player WHERE room=[lindex $testid 0]"
				mysqlendquery $link
				mysqlsel $link "DELETE FROM room WHERE roomid=[lindex $testid 0]"
				mysqlendquery $link
				mysqlclose $link
				putserv "PRIVMSG $chan :房间[lindex $testid 0]游戏结束，间谍胜利。"
				return
			    }
			    foreach member $calllist {
				putserv "PRIVMSG $member :$msg"
			    }
			    mysqlsel $link "UPDATE room SET status=1,fail=$fail,last=\"$msg\" WHERE roomid=[lindex $testid 0]"
			    mysqlendquery $link
			} else {
			    set msg "$disagree人破坏任务，第[lindex $testroom 2]回合任务成功。"
			    set success [expr [lindex $testroom 6]+1]
			    if {$success == 3} {
				set temp "游戏结束，抵抗者胜利。"
				set msg $msg$temp
				foreach member $calllist {
				    putserv "PRIVMSG $member :$msg"
				}
				mysqlsel $link "DELETE FROM player WHERE room=[lindex $testid 0]"
				mysqlendquery $link
				mysqlsel $link "DELETE FROM room WHERE roomid=[lindex $testid 0]"
				mysqlendquery $link
				mysqlclose $link
				putserv "PRIVMSG $chan :房间[lindex $testid 0]游戏结束，抵抗者胜利。"
				return
			    }
			    foreach member $calllist {
				putserv "PRIVMSG $member :$msg"
			    }
			    mysqlsel $link "UPDATE room SET status=1,success=$success,last=\"$msg\" WHERE roomid=[lindex $testid 0]"
			    mysqlendquery $link
			}
		    }
		    foreach member $calllist {
			putserv "PRIVMSG $member :进入第[expr [lindex $testroom 2]+1]轮，请领袖选出[lindex $tasks([lindex $testroom 0]) [lindex $testroom 2]]人做任务。"
		    }
		}
		default {
		    #extend
		}
	    }
	}
	mysqlclose $link
    }
}

proc resistance:cons {nick host handle text} {
    global db tasks chan
    set id [md5 $host]
    set link [mysqlconnect -user $db(user) -password $db(password) -db $db(name)]
    mysqluse $link $db(name)
    set testid [mysqlsel $link "SELECT room,role,voted FROM player WHERE id=\"$id\" LIMIT 1" -flatlist]
    mysqlendquery $link
    if {$testid == ""} {
	putserv "PRIVMSG $nick :您不在任何房间中。"
    } else {
	if {[lindex $testid 2] == 1} {
	    putserv "PRIVMSG $nick :您已投票。"
	} else {
	    set testroom [mysqlsel $link "SELECT totalnumber,currentnumber,turn,votes,disagree,status,success,fail,deny FROM room WHERE roomid=[lindex $testid 0] LIMIT 1" -flatlist]
	    mysqlendquery $link
	    set votes [lindex $testroom 3]
	    set disagree [lindex $testroom 4]
	    switch [lindex $testroom 5] {
		0 {
		    putserv "PRIVMSG $nick :房间未满，还需要[expr [lindex $testroom 0]-[lindex $testroom 1]]位玩家。"
		}
		1 {
		    incr votes
		    putserv "PRIVMSG $nick :投票成功。"
		    incr disagree
		    mysqlsel $link "UPDATE player SET voted=TRUE WHERE id=\"$id\""
		    mysqlendquery $link
		    mysqlsel $link "UPDATE room SET disagree=$disagree,votes=$votes WHERE roomid=[lindex $testid 0]"
		    mysqlendquery $link
		    if {$votes == [lindex $testroom 0]} {
			mysqlsel $link "UPDATE player SET voted=FALSE WHERE room=[lindex $testid 0]"
			mysqlendquery $link
			mysqlsel $link "UPDATE room SET votes=0,disagree=0 WHERE roomid=[lindex $testid 0]"
			mysqlendquery $link
			set idlist [mysqlsel $link "SELECT id FROM player WHERE room=[lindex $testid 0]" -flatlist]
			mysqlendquery $link
			set calllist {}
			foreach member $idlist {
			    set callid [mysqlsel $link "SELECT nick FROM name WHERE id=\"$member\" LIMIT 1" -flatlist]
			    mysqlendquery $link
			    lappend calllist $callid
			}
			if {$disagree >= ceil($votes/2)} {
			    set deny [expr [lindex $testroom 8]+1]
			    set msg "[expr $votes-$disagree]人支持，$disagree人反对，组队失败。这是第$deny次组队失败。"
			    if {$deny == 5} {
				set tempmsg "游戏结束，间谍胜利。"
				set msg $msg$tempmsg
				foreach member $calllist {
				    putserv "PRIVMSG $member :$msg"
				}
				mysqlsel $link "DELETE FROM player WHERE room=[lindex $testid 0]"
				mysqlendquery $link
				mysqlsel $link "DELETE FROM room WHERE roomid=[lindex $testid 0]"
				mysqlendquery $link
				mysqlclose $link
				putserv "PRIVMSG $chan :房间[lindex $testid 0]游戏结束，间谍胜利。"
				return
			    }
			    foreach member $calllist {
				putserv "PRIVMSG $member :$msg"
			    }
			    mysqlsel $link "UPDATE room SET deny=$deny,last=\"$msg\" WHERE roomid=[lindex $testid 0]"
			    mysqlendquery $link
			} else {
			    set msg "[expr $votes-$disagree]人支持，$disagree人反对，组队成功。请开始做任务。"
			    foreach member $calllist {
				putserv "PRIVMSG $member :$msg"
			    }
			    mysqlsel $link "UPDATE room SET turn=[expr [lindex $testroom 2]+1],status=2,last=\"$msg\" WHERE roomid=[lindex $testid 0]"
			    mysqlendquery $link
			}
		    }
		}
		2 {
		    set maxtask [lindex $tasks([lindex $testroom 0]) [expr [lindex $testroom 2]-1]]
		    if {[lindex $testid 1] == 1} {
			incr disagree
		    }
		    incr votes
		    putserv "PRIVMSG $nick :投票成功（抵抗者一律视为做任务）。"
		    mysqlsel $link "UPDATE player SET voted=TRUE WHERE id=\"$id\""
		    mysqlendquery $link
		    mysqlsel $link "UPDATE room SET disagree=$disagree,votes=$votes WHERE roomid=[lindex $testid 0]"
		    mysqlendquery $link
		    set idlist [mysqlsel $link "SELECT id FROM player WHERE room=[lindex $testid 0]" -flatlist]
		    mysqlendquery $link
		    set calllist {}
		    foreach member $idlist {
			set callid [mysqlsel $link "SELECT nick FROM name WHERE id=\"$member\" LIMIT 1" -flatlist]
			mysqlendquery $link
			lappend calllist $callid
		    }
		    if {$votes == $maxtask} {
			mysqlsel $link "UPDATE player SET voted=FALSE WHERE room=[lindex $testid 0]"
			mysqlendquery $link
			mysqlsel $link "UPDATE room SET votes=0,disagree=0,deny=0 WHERE roomid=[lindex $testid 0]"
			mysqlendquery $link
			if {[lindex $testroom 0] >= 7 && [lindex $testroom 2] == 4} {
			    set allowfail 1
			} else {
			    set allowfail 0
			}
			if {$disagree > $allowfail} {
			    set msg "$disagree人破坏任务，第[lindex $testroom 2]回合任务失败。"
			    set fail [expr [lindex $testroom 7]+1]
			    if {$fail == 3} {
				set temp "游戏结束，间谍胜利。"
				set msg $msg$temp
				foreach member $calllist {
				    putserv "PRIVMSG $member :$msg"
				}
				mysqlsel $link "DELETE FROM player WHERE room=[lindex $testid 0]"
				mysqlendquery $link
				mysqlsel $link "DELETE FROM room WHERE roomid=[lindex $testid 0]"
				mysqlendquery $link
				mysqlclose $link
				putserv "PRIVMSG $chan :房间[lindex $testid 0]游戏结束，间谍胜利。"
				return
			    }
			    foreach member $calllist {
				putserv "PRIVMSG $member :$msg"
			    }
			    mysqlsel $link "UPDATE room SET status=1,fail=$fail,last=\"$msg\" WHERE roomid=[lindex $testid 0]"
			    mysqlendquery $link
			} else {
			    set msg "$disagree人破坏任务，第[lindex $testroom 2]回合任务成功。"
			    set success [expr [lindex $testroom 6]+1]
			    if {$success == 3} {
				set temp "游戏结束，抵抗者胜利。"
				set msg $msg$temp
				foreach member $calllist {
				    putserv "PRIVMSG $member :$msg"
				}
				mysqlsel $link "DELETE FROM player WHERE room=[lindex $testid 0]"
				mysqlendquery $link
				mysqlsel $link "DELETE FROM room WHERE roomid=[lindex $testid 0]"
				mysqlendquery $link
				mysqlclose $link
				putserv "PRIVMSG $chan :房间[lindex $testid 0]游戏结束，抵抗者胜利。"
				return
			    }
			    foreach member $calllist {
				putserv "PRIVMSG $member :$msg"
			    }
			    mysqlsel $link "UPDATE room SET status=1,success=$success,last=\"$msg\" WHERE roomid=[lindex $testid 0]"
			    mysqlendquery $link
			}
		    }
		    foreach member $calllist {
			putserv "PRIVMSG $member :进入第[expr [lindex $testroom 2]+1]轮，请领袖选出[lindex $tasks([lindex $testroom 0]) [lindex $testroom 2]]人做任务。"
		    }
		}
		default {
		    #extend
		}
	    }
	}
	mysqlclose $link
    }
}

#proc resistance:deny {nick host handle text} {
#}
