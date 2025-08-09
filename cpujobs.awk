#!/usr/bin/gawk -f

#
# Description
#
#   usage: ps uaxf | type="<calltype>" host="<hostname>" fjobs="<outputfile>" ./cpujobs.awk
#
# ChangeLog
#
#   2014-10-18, Koichi Murase <murase@nt.phys.s.u-tokyo.ac.jp>
#     * cumulative TIME and CPU (they can be obtained with `ps uaxfS').
#       初めは /proc/pid/stat から直接読み出そうと思ったが単位換算などができないので
#       結局 ps axSo で値を取得する事にした。
#     * mode=="rfh":導入部: bugfix, rfhexec.sh コマンドは rfhexec.sh では始まらない。
#       /bin/bash /.../rfhexec.sh の様になるので、その事を考慮に入れて深さ (headIndex) を決定しなければならない。
#     * mode=="sh": 手動で開始したプロセスについても長時間実行している物は列挙する様に。
#     * bugfix of guse: lava の管理プロセスも guse にカウントしていた。
#       guse, uuse の更新を output_jobline で行う様に変更して対処。
#   2013-05-08, Koichi Murase <murase@nt.phys.s.u-tokyo.ac.jp>
#     * created. extracted out of `m/rsh/get_used.sh'
#     * added support for lava
#

function extractCOMMAND(line, _m){
  # create_regex_cmdline() {
  #   local w='[^[:space:]]'
  #   local s='[[:space:]]'
  #   local f="$w+$s+"
  #   echo -n "^$s*$f$f$f$f$f$f$f$f$f$w+$s(.+)$"
  # }
  if(match(line,/^[[:space:]]*[^[:space:]]+[[:space:]]+[^[:space:]]+[[:space:]]+[^[:space:]]+[[:space:]]+[^[:space:]]+[[:space:]]+[^[:space:]]+[[:space:]]+[^[:space:]]+[[:space:]]+[^[:space:]]+[[:space:]]+[^[:space:]]+[[:space:]]+[^[:space:]]+[[:space:]]+[^[:space:]]+[[:space:]](.+)$/,_m)>0){
    return _m[1];
  }else{
    return substr(line,commandIndex);
  }
}

function get_second(time ,_m){
  if(match(time,/^([0-9]*)\:([0-9]*)$/,_m)>0){
    return _m[1]*60+_m[2];
  }else if(match(time,/^([0-9]*)\:([0-9]*)\:([0-9]*)$/,_m)>0){
    return (_m[1]*60+_m[2])*60+_m[3];
  }else if(match(time,/^([0-9]*)-([0-9]*)\:([0-9]*)\:([0-9]*)$/,_m)>0){
    return ((_m[1]*24+_m[2])*60+_m[3])*60+_m[4];
  }else{
    return time*60;
  }
}
function add_stat(s1,s2){
  if(s2~/^R/)return s2;if(s1~/^R/)return s1;
  if(s2~/^W/)return s2;if(s1~/^W/)return s1;
  if(s2~/^D/)return s2;if(s1~/^D/)return s1;
  if(s2~/^S/)return s2;if(s1~/^S/)return s1;
  if(s2~/^T/)return s2;if(s1~/^T/)return s1;
  if(s2~/^Z/)return s2;if(s1~/^Z/)return s1;
  return s2;
}

function getHeadIndexOfCOMMAND(cmdfld){
  match(cmdfld,/^([[:space:]\|]|\\_)*/);
  return RLENGTH+1;
}
function getCommandFromCOMMAND(cmdfld, _cmd){
  sub(/^([[:space:]\|]|\\_)*/,"",cmdfld);
  return cmdfld;
}

function init_cproc(_line,_ps_cmd,_f){
  proc_cproc_init=1;
  _ps_cmd="ps axSo pid,bsdtime,%cpu,etime"
  while((_ps_cmd | getline _line)>0){
    split(_line,_f);
    proc_ctime[_f[1]]=get_second(_f[2]);
    proc_cpcpu[_f[1]]=_f[3];
    proc_etime[_f[1]]=get_second(_f[4]);
  }
  close(_ps_cmd);
}
function get_ctime(pid){
  if(!proc_cproc_init)return get_second($10);
  if(!pid||pid=="")pid=$2;
  return proc_ctime[pid];
}
function get_cpcpu(pid){
  if(!proc_cproc_init)return $3;
  if(!pid||pid=="")pid=$2;
  return proc_cpcpu[pid];
}
function get_etime(pid){
  if(!proc_cproc_init)return 0;
  if(!pid||pid=="")pid=$2;
  return proc_etime[pid];
}

BEGIN{
  init_cproc();

  uuse=0;
  guse=0;

  TYPE=ENVIRON["type"];

  HOST=ENVIRON["host"];
  if(HOST==""){
    HOST=ENVIRON["HOSTNAME"];
    sub(/\..*$/,"",HOST);
  }
  if(length(HOST)>10)
    HOST=substr(HOST,1,10);

  FJOBS=ENVIRON["fjobs"];
  if(FJOBS=="")FJOBS="/dev/stdout";

  USER=ENVIRON["USER"];

  printf("%-10s %10s:%-5s %6s %5s %-4s %5s %8s %s\n","USER","HOST","PID","%CPU","%MEM","STAT","START","TIME","COMMAND") > FJOBS
}

$11=="COMMAND"{
  commandIndex=index($0,"COMMAND");
  next;
}

function output_jobline( _time,_mode,_command){
  _mode=mode;

  mode="";
  if(_mode=="lava"){
    if(user=="root"&&lavaIndex==0)return;

    if(user==USER)uuse++;
    guse++;
    _command=cmd;
    if(jobid!="-")_command="[lava:" jobid "] " cmd
  }else if(_mode=="sh"){
    _command="[manual:" tty "] " cmd;
  }else if(_mode=="rsh"){
    if(user==USER)uuse++;
    guse++;
    _command="[cpulook] " cmd;
  }else{
    return;
  }

  _time=sprintf("%d:%02d",int(time/60),time%60);
  printf("%-10s %10s:%-5s %6.1f %5.1f %-4s %5s %8.8s %s\n",user,host,pid,cpu,mem,stat,start,_time,_command) > FJOBS
}

function cumulate_values(){
  cpu+=$3;
  time+=get_ctime();
  mem+=$4;
  stat=add_stat(stat,$8);
}

function dbg(name){
  if(host!="laguerre01")return;
}

#------------------------------------------------------------------------------
# cpulook/rshexec.sh によって開始されたプロセスツリー
$0~/\yrshexec.sh --sub -c /{
  #dbg("rsh0");
  output_jobline();
  mode="rsh";

  host=HOST;
  user=$1;
  pid=$2;cpu=$3;mem=$4;
  stat=$8;start=$9;time=get_ctime();

  _cmdfld=extractCOMMAND($0);
  headIndex=match(_cmdfld,/([^[:space:]]+\/bash[[:space:]]+([^[:space:]]*\/)?rshexec.sh --sub -c )/,_m);
  cmd=substr(_cmdfld,headIndex+length(_m[1]));
  gsub(/^\. ~\/\.bashrc ; cd [^;]+ ; | &>\/dev\/null$/,"",cmd);
  next;
}

mode=="rsh"{
  #dbg("rsh1");
  _cmdfld=extractCOMMAND($0);
  if(match(substr(_cmdfld,0,headIndex),/^([[:space:]]|\\_|\|)+$/)>0){
    cumulate_values();
    next;
  }else{
    output_jobline();
  }
}

#------------------------------------------------------------------------------
# lava によって開始されたプロセスツリー
$0~/\/usr\/share\/lava\/[^[:space:]\/]+\/[^[:space:]\/]+\/sbin\/res\y/{
  #dbg("lava0");
  output_jobline();
  mode="lava";

  host=HOST;
  user=$1;
  pid=$2;cpu=$3;mem=$4;
  stat=$8;start=$9;time=get_ctime();

  _cmdfld=extractCOMMAND($0);
  headIndex=getHeadIndexOfCOMMAND(_cmdfld);
  cmd="-"; # temporal cmd
  lavaIndex=0;
  jobid="-";
  next;
}

mode=="lava"{
  #dbg("lava1");
  _cmdfld=extractCOMMAND($0);
  _headIndex2=getHeadIndexOfCOMMAND(_cmdfld);
  if(_headIndex2>headIndex){
    cumulate_values();

    lavaIndex++;
    if(lavaIndex==1){
      if(match(_cmdfld,/\.([0-9]+)$/,_capt)>=1){
        jobid=_capt[1];
        # cmd="<JOBID:" jobid ">"
      }
    }else if(lavaIndex==2){
      cmd=substr(_cmdfld,_headIndex2);
    }
    next;
  }else{
    output_jobline();
  }
}

#------------------------------------------------------------------------------
# その他(直接実行?)

mode=="sh"{
  #dbg("sh1");
  _cmdfld=extractCOMMAND($0);
  #print "dbg: headIndex=" headIndex ", substr=(" substr(_cmdfld,0,headIndex) ")" > FJOBS
  if(match(substr(_cmdfld,0,headIndex),/^([[:space:]]|\\_|\|)+$/)>0){
    cumulate_values();
    next;
  }else{
    output_jobline();
  }
}

$1!="root"&&get_ctime()>=180&&(get_ctime()>get_etime()*0.5||!($8~/^[TS]/)){
  #dbg("sh0");
  output_jobline();
  mode="sh";

  host=HOST;
  user=$1;
  pid=$2;cpu=$3;mem=$4;
  stat=$8;start=$9;time=get_ctime();

  tty=$7;if(tty~/^[-?]?$/)tty="nohup";

  _cmdfld=extractCOMMAND($0);
  headIndex=getHeadIndexOfCOMMAND(_cmdfld);
  cmd=substr(_cmdfld,headIndex);
  next;
}

#------------------------------------------------------------------------------

END{
  output_jobline();
  if(TYPE=="rsh.used")
    print uuse, guse;
}
