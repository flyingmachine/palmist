= production_log_analyzer

production_log_analyzer lets you find out which actions on a Rails
site are slowing you down.

http://seattlerb.rubyforge.org/production_log_analyzer

http://rubyforge.org/projects/seattlerb

Bug reports:

http://rubyforge.org/tracker/?func=add&group_id=1513&atid=5921

== About

production_log_analyzer provides three tools to analyze log files
created by SyslogLogger.  pl_analyze for getting daily reports,
action_grep for pulling log lines for a single action and
action_errors to summarize errors with counts.

The analyzer currently requires the use of SyslogLogger because the
default Logger doesn't give any way to associate lines logged to a
request.

The PL Analyzer also includes action_grep which lets you grab lines from a log
that only match a single action.

  action_grep RssController#uber /var/log/production.log

== Installing

  sudo gem install production_log_analyzer

=== Setup

First:

Set up SyslogLogger according to the instructions here:

http://seattlerb.rubyforge.org/SyslogLogger/

Then:

Set up a cronjob (or something like that) to run log files through pl_analyze.

== Using pl_analyze

To run pl_analyze simply give it the name of a log file to analyze.

  pl_analyze /var/log/production.log

If you want, you can run it from a cron something like this:

  /usr/bin/gzip -dc /var/log/production.log.0.gz | /usr/local/bin/pl_analyze /dev/stdin

Or, have pl_analyze email you (which is preferred, because tabs get preserved):

  /usr/bin/gzip -dc /var/log/production.log.0.gz | /usr/local/bin/pl_analyze /dev/stdin -e devnull@robotcoop.com -s "pl_analyze for `date -v-1d "+%D"`"

In the future, pl_analyze will be able to read from STDIN.

== Sample output

  Request Times Summary:          Count   Avg     Std Dev Min     Max
  ALL REQUESTS:                   11      0.576   0.508   0.000   1.470
  
  ThingsController#view:          3       0.716   0.387   0.396   1.260
  TeamsController#progress:       2       0.841   0.629   0.212   1.470
  RssController#uber:             2       0.035   0.000   0.035   0.035
  PeopleController#progress:      2       0.489   0.489   0.000   0.977
  PeopleController#view:          2       0.731   0.371   0.360   1.102
  
  Average Request Time: 0.634
  Request Time Std Dev: 0.498
  
  Slowest Request Times:
          TeamsController#progress took 1.470s
          ThingsController#view took 1.260s
          PeopleController#view took 1.102s
          PeopleController#progress took 0.977s
          ThingsController#view took 0.492s
          ThingsController#view took 0.396s
          PeopleController#view took 0.360s
          TeamsController#progress took 0.212s
          RssController#uber took 0.035s
          RssController#uber took 0.035s
  
  ------------------------------------------------------------------------
  
  DB Times Summary:               Count   Avg     Std Dev Min     Max
  ALL REQUESTS:                   11      0.366   0.393   0.000   1.144
  
  ThingsController#view:          3       0.403   0.362   0.122   0.914
  TeamsController#progress:       2       0.646   0.497   0.149   1.144
  RssController#uber:             2       0.008   0.000   0.008   0.008
  PeopleController#progress:      2       0.415   0.415   0.000   0.830
  PeopleController#view:          2       0.338   0.149   0.189   0.486
  
  Average DB Time: 0.402
  DB Time Std Dev: 0.394
  
  Slowest Total DB Times:
          TeamsController#progress took 1.144s
          ThingsController#view took 0.914s
          PeopleController#progress took 0.830s
          PeopleController#view took 0.486s
          PeopleController#view took 0.189s
          ThingsController#view took 0.173s
          TeamsController#progress took 0.149s
          ThingsController#view took 0.122s
          RssController#uber took 0.008s
          RssController#uber took 0.008s
  
  ------------------------------------------------------------------------
  
  Render Times Summary:           Count   Avg     Std Dev Min     Max
  ALL REQUESTS:                   11      0.219   0.253   0.000   0.695
  
  ThingsController#view:          3       0.270   0.171   0.108   0.506
  TeamsController#progress:       2       0.000   0.000   0.000   0.000
  RssController#uber:             2       0.012   0.000   0.012   0.012
  PeopleController#progress:      2       0.302   0.302   0.000   0.604
  PeopleController#view:          2       0.487   0.209   0.278   0.695
  
  Average Render Time: 0.302
  Render Time Std Dev: 0.251
  
  Slowest Total Render Times:
          PeopleController#view took 0.695s
          PeopleController#progress took 0.604s
          ThingsController#view took 0.506s
          PeopleController#view took 0.278s
          ThingsController#view took 0.197s
          ThingsController#view took 0.108s
          RssController#uber took 0.012s
          RssController#uber took 0.012s
          TeamsController#progress took 0.000s
          TeamsController#progress took 0.000s

== What's missing

* More reports
* Command line arguments including:
  * Help
  * What type of log file you've got (if somebody sends patches with tests)
* Read from STDIN

