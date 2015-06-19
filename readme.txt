
Configuration

  cpulist.cfg

Commands

  cpulook

  cpusub [options] command

  cpuseekd [options]

  cputop HOST

  cpups HOST

  cpulast HOST

  cpukill CPUJOBID


ChangeLog
  2014-04-25
    * cpukill, cpusub, cpuseekd (echox): echox を .mwg/libexec/echox に配置変更
    * install.sh: インストールスクリプトを作成

  2013-11-17
    * cpulook: 表示色変更 for terminfo colors#256

  2013-10-23
    * cpuseekd (allocate_cpu): bugfix, cpu を使い果たした直後に allocate_cpu を呼び出すと、
      直前に投げたジョブが cpulook の結果に反映されず一つの cpu に2つずつタスクを割り当ててしまうバグ。
      cpulook の結果が新しい場合には、最低 1 分待って再度 cpulook を実行する様に変更。

  2013-05-18  K. Murase <murase@nt.phys.s.u-tokyo.ac.jp>
    * m/rsh/get_used.src: cpujobs.awk を用いて uuse, guse を取得する様に変更
    * m/rsh/rshexec.sh: 子プロセスを自身 (rshexec.sh) で実行するように変更。
      更に、コマンドの実行は bash -c を用いるのではなく eval を用いる様に変更。
    * cpujobs.awk: `bash -c ' ではなく `rshexec.sh --sub -c ' を目印に、
      m/rsh によるタスクを判定するように変更。
    * m/rsh/rshkill.sh: `bash -c ' ではなく `rshexec.sh --sub -c ' を目印に。

  2013-05-13  K. Murase <murase@nt.phys.s.u-tokyo.ac.jp>
    * cputop: 右端で自動で折り返す terminal で行が増えるのを防ぐ為、
      COLUMNS に 1 文字分余裕を持たせる様に変更。

  2013-05-07  K. Murase <murase@nt.phys.s.u-tokyo.ac.jp>
    * cpulook: *.stat を待つ時に、中身がある事を確認する迄待つ様に変更。
    * cpugetdata.sh: load が gauge の幅を超えた時の表示を追加。
    * cpujobs.awk: 作成。m/rsh/get_used.src から機能を独立して作成。
    * cpujobs.awk: lava の job に対応。

  2013-05-06  K. Murase <murase@nt.phys.s.u-tokyo.ac.jp>
    * cpugetdata.sh: [bugfix] gawk に渡すパラメータの内に空文字列があるとパラメータがずれる問題。
      引数を ':' で区切って渡す事にした (引数内に文字 ':' が混入しなければOK)
    * m/bsub/get_used.src: [bugfix] 変数名 cpu を host に変更したのを適用していなかった。
    * m/bsub/get_used@local.src: 出力ファイル名と形式を変更
    * m/bsub/get_used.src: get_used@local の出力から uuse と guse の両方を計算するように変更
    * m/bsub/cpukill.src: 作成
    * cpugetdata.sh: gauge に表示する内容で load と util を別々に表示する様に変更した。
      util の方を今迄通りに棒グラフで示し load については # 記号の位置で表す事にする。

  2013-05-05  K. Murase <murase@nt.phys.s.u-tokyo.ac.jp>
    * cpulook, m/rsh/get_used.src: 現在実行されている job の一覧を表示する機能
    * cpulook, cpuseekd: tmp/cpulook.cache を tmp/cpustat.txt に名称変更
    * cpusub: ログファイルの指定方法を変更 (どうせ今迄ログファイルを指定した事は無い)。
      オプションとして `-l <filename>' 等と指定すると、stdout, stderr の接続先が指定される。
      代わりに `-o <filename>' または `-e <filename>' と指定する事で
      stdout または stderr の接続先ファイルをそれぞれ指定する事も出来る。
    * cpusub: その場で実行する時の host 名を短縮名で指定できるように変更。  
    * cpukill: 作成。リモートのジョブをキャンセルする時に使用する。m/rsh/cpukill.src で対応。
    * cpulook: cpu のメータ部分のフィールド名が変な記号だったのを GAUGE に変更

  2013-05-04  K. Murase <murase@nt.phys.s.u-tokyo.ac.jp>
    * cpugetdata.sh, get_used.src: used 変数の名前を uuse に変更
    * cpugetdata.sh, get_used.src: 全体で使用されている数を表す guse を追加
    * cpulook, cpugetdata.sh: host の情報を記録する一行ファイルの名前を *.stat.tmp から tmp/*.stat に変更
    * cpulook: cpulook.tmp を tmp/cpulook.time に変更
    * cpulook, cpuseekd: cpustat.txt を tmp/cpulook.cache に変更
    * cpulook: 表示で `AC' (allocated cpus?) となっていたのを `UC' (used cores) に変更
      また、分離記号に `w' が使われていたのを `:' に変更
      (覚えていないが、元々は分離記号ではなくて何かの値だった様な…?)。
    * m/rsh/submit.src, m/rsh/rshexec.sh:
      大量の rsh を発行するとエラーになるので rsh を必要最小限に抑える為、
      複数のコマンド起動を一つの rsh でまとめて実行するように変更。

  2013-04-24  K. Murase <murase@nt.phys.s.u-tokyo.ac.jp>
    * cputop: Changed to show command line arguments instead of only a program name.
    * cpugethost.sh: Created. 短縮名からホスト名を取得するスクリプト。
    * cputop, cpups, cpulast: 短縮名を用いてホストを指定できる様に変更
    * readme.txt: Created

  2013-03-20  K. Murase <murase@nt.phys.s.u-tokyo.ac.jp>
    * cpulook:
      host からの返答を自分でチェックし、揃ったらその時点で結果を出力する様に変更。
      引数に指定した待ち時間はタイムアウトの時間として解釈される。

  2013-03-16  K. Murase <murase@nt.phys.s.u-tokyo.ac.jp>
    * cpulook: 列名 `SERVER' を `HOST' に変更
    * cpuseekd: (minor) 英語の修正、待ち時間の調整
    * cpuseekd: 端末題名の設定に terminfo を使用するように変更

  2013-03-11  K. Murase <murase@nt.phys.s.u-tokyo.ac.jp>
    * cputop: Changed to show working processes only.
      To show all processes, specify the command line option `-a'
    * cpuseekd: 待ち時間の調整、v モードの判定の仕方の変更

  2013-02-21  K. Murase <murase@nt.phys.s.u-tokyo.ac.jp>
    * cpulook: cpulist.txt でなく cpulist.cfg を用いる様に変更
    * cpulook: 列幅の調整

  2012-05-22  K. Murase <murase@nt.phys.s.u-tokyo.ac.jp>
    * cpulist.cfg: 列を追加。ユーザ当たりのタスク数上限
    * cpugetdata.sh: ユーザ当たりのタスク数の上限を考慮に入れた idle 値の計算
    * cpuseekd: cpulist.cfg を使用するように変更

  2012-04-24  K. Murase <murase@nt.phys.s.u-tokyo.ac.jp>
    * cpuseekd: 過去の task.eat のバックアップを取るように変更

  2012-04-24  K. Murase <murase@nt.phys.s.u-tokyo.ac.jp>
    * cpuseekd: 環境依存の部分を m/ ディレクトリに分離

  2011-12-27  K. Murase <murase@nt.phys.s.u-tokyo.ac.jp>
    * cpugetdata.sh: bugfix

  2011-11-27  K. Murase <murase@nt.phys.s.u-tokyo.ac.jp>
    * cpulist.cfg: Created
    * cpugetdata.sh: タスク数の上限を考慮に入れた idle 値の計算

  2011-11-23  K. Murase <murase@nt.phys.s.u-tokyo.ac.jp>
    * cpugetdata.sh: progress bar の見た目を変更
    * cpuseekd: (minor) 条件式を等価書換

  2011-09-30  K. Murase <murase@nt.phys.s.u-tokyo.ac.jp>
    * cpusub: その場で rsh で実行する為のオプション `-i HOST' を追加。

  2011-08-29  K. Murase <murase@nt.phys.s.u-tokyo.ac.jp>
    * cputop, cpups, cpulast: Created.

  2011-08-28  K. Murase <murase@nt.phys.s.u-tokyo.ac.jp>
    * cpuseekd

  2011-08-16  K. Murase <murase@nt.phys.s.u-tokyo.ac.jp>
    * cpugetdata.sh: util 値の取得方法の修正

  2011-07-20  K. Murase <murase@nt.phys.s.u-tokyo.ac.jp>
    * cpulook: 待ち時間を引数に指定できる様に変更
    * cpugetdata.sh: 様々なパラメータを参照して idle 値を計算

  2011-07-19  K. Murase <murase@nt.phys.s.u-tokyo.ac.jp>
    * cpusub, cpuseekd: Created.

  2011-07-17  K. Murase <murase@nt.phys.s.u-tokyo.ac.jp>
    * cpulook, cpugetdata.sh: Created

Memo
  
B0001 "rsh でコマンドを実行すると poll: protocol failure in circuit setup というエラーが出る事"
  [日付] 2013/05/04 - 2013/05/05 03:47:26 [完]

  [状況]
  沢山の core 空きがある状況で、沢山の rsh を同時に実行すると、幾つかの rsh で
  poll: protocol failure in circuit setup
  というメッセージが表示されてコマンドの起動に失敗する。
  実際にそのホストへ行って見るとコマンドは起動されていない様であり、
  また、同時に実行した別の (エラーメッセージを出していない) rsh によるコマンドの起動は成功している様子である。

  [対処]
  http://www.novell.com/support/kb/doc.php?id=3077223
  上記のページによると rsh がコマンドを起動する時、
  1 local => remote:514 にアクセスをし local のポート番号 (p1 とする) を伝える
  2 remote => local:p1 にアクセスをし接続を確認して? からコマンドを起動する
  という手順になっているらしい(? 多分…)。しかし p1 の範囲として使われるのは 1016-1022 であり、
  これらのポートが既に使われている場合に circuit setup エラーが発生する。

  つまり、同時に rsh がコマンドの起動を試みている状況ではポート番号の取り合いになって、
  ポート番号が枯渇してしまうという事だろうか。

  また、上の状況が発生した後暫くは rsh でコマンドを実行する事が出来なくなった。
  (もしポート番号の取り合いが原因だとしたら) 幾つかの rsh は暫くはそのポート番号を保持し続けるという事だろうか。

  また別のサイトでは、よく分からない記述が為されている。
  http://wall-climb.com/2007/01/26/rsh%E3%82%92%E3%83%90%E3%83%83%E3%82%AF%E3%82%B0%E3%83%A9%E3%82%A6%E3%83%B3%E3%83%89%E3%81%A7%E5%AE%9F%E8%A1%8C%E3%81%99%E3%82%8B/
  「ローカルの rsh もリモートの rsh もバックグラウンドで動作するのがうまくいかないと rsh が連続で同時に発行され」の意味が分からない。
  しかし、コマンドが起動したら rsh が即座に終了するように設定しておけばこの問題は生じないらしい?

  実際に、
  rsh laguerre02 -n "( sleep 10; echo hello; ) &>/dev/null </dev/null &"
  というコマンドを実行してみたら呼び出した rsh が即座に終了してくれた。
  これを真似してコマンドを起動してやれば rsh が終わった時には、
  既に rsh セッションは終了した事になっているので、現状の問題は生じないはずである。

  但し、毎回この様な長いコマンドを作文して rsh に直接渡すのは嫌なので、この部分をスクリプトにしてしまいたい。
  そう思って m/rsh/rshexec.sh というスクリプトを作り、
  rsh から rshexec.sh に起動したいコマンドを引数として渡す事によってコマンドを非同期に実行できるようにした。
  submit.src もその様に書き換えたのだが…。

  ふと思って、
  for((i=0;i<100;i++)); do
    echo hello$i >~/tmp/a.txt
    rsh laguerre02 cat ~/tmp/a.txt
  done
  の様なスクリプトを作って実行してみたら…
    poll: protocol failure in circuit setup
  のエラーが発生してしまった…。つまり、rsh が起動中だとかそうでないとかそういう事は関係なく、
  連続で rsh を沢山実行すると結局このエラーが出てしまうと言う事のようだ。
  (多分、上記の処置の方法は、単体の rsh の実行でもこのエラーメッセージが出てしまった場合に有効なのであろう。)

  という訳で、方針を変更して複数の rsh 要求を 1 つに纏めて発行する様にする。
  例えば 5 秒待っても新しいコマンドが追加されなかったらその時点で rsh を実行する、など。
  取り敢えず実装した。複数の cpuseekd インスタンスがあっても大丈夫な様に設計したつもり…だがテストはしていない。
