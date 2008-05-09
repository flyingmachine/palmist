#!/usr/local/bin/ruby -w

$TESTING = true

require 'tempfile'
require 'test/unit'
require 'stringio'

require 'production_log/parser'

class TestLogEntry < Test::Unit::TestCase

  def setup
    @entry = LogParser::LogEntry.new <<EOF
Processing TwinklerController#index (for 81.109.96.173 at Wed Dec 01 16:01:56 CST 2004)
Parameters: {\"action\"=>\"index\", \"controller\"=>\"twinkler\"}
Browser Load First (0.001114)   SELECT * FROM browsers WHERE ubid = 'ixsXHgUo7U9PJGgBzr7e9ocaDOc=' LIMIT 1
Goal Count (0.001762)   SELECT COUNT(*) FROM goals WHERE browser_id = '96181' and is_active = 1 
Rendering twinkler/index within layouts/default
Rendering layouts/default (200 OK)
Completed in 0.616122 (1 reqs/sec) | Rendering: 0.242475 (39%) | DB: 0.002876 (0%)
EOF
  end

  def test_parse
    request = <<EOF
Processing RssController#uber (for 67.18.200.5 at Mon Mar 07 00:00:25 CST 2005)
Parameters: {:id=>"author", :"rss/uber/author.html/uber/author"=>nil, :action=>"uber", :username=>"looch", :controller=>"rss"}
Cookie set: auth=dc%2FGUP20BwziF%2BApGecc0pXB0PF0obi55az63ubAFtsnOOdJPkhfJH2U09yuzQD3WtdmWnydLzFcRA78kwi7Gw%3D%3D; path=/; expires=Thu, 05 Mar 2015 06:00:25 GMT
Cookie set: ubid=kF05DqFH%2F9hRCOxTz%2Bfb8Q7UV%2FI%3D; path=/; expires=Thu, 05 Mar 2015 06:00:25 GMT
Browser Load (0.003963)   SELECT * FROM browsers WHERE ubid = 'kF05DqFH/9hRCOxTz+fb8Q7UV/I=' LIMIT 1
Person Load (0.002445)   SELECT * FROM people WHERE username = 'looch' AND active = '1' LIMIT 1
ProfileImage Load (0.001554)   SELECT * FROM profile_images WHERE id = 2782 LIMIT 1
Rendering rss/rss2.0 (200 OK)
Completed in 0.034519 (28 reqs/sec) | Rendering: 0.011770 (34%) | DB: 0.007962 (23%)
EOF
    request = request.split "\n"

    entry = LogParser::LogEntry.new []

    entry.parse request
    assert_kind_of LogParser::LogEntry, entry
    assert_equal "RssController#uber", entry.page
    assert_equal 3, entry.queries.length
    assert_equal ['Browser Load', 0.003963], entry.queries.first
    assert_equal 0.034519, entry.request_time
  end

  def test_page
    assert_equal "TwinklerController#index", @entry.page
  end

  def test_ip
    assert_equal "81.109.96.173", @entry.ip
  end

  def test_time
    assert_equal "Wed Dec 01 16:01:56 CST 2004", @entry.time
  end

  def test_queries
    expected = []
    expected << ["Browser Load First", 0.001114]
    expected << ["Goal Count", 0.001762]
    assert_equal expected, @entry.queries
  end

  def test_request_time
    assert_equal 0.616122, @entry.request_time

    @entry = LogParser::LogEntry.new "Processing TwinklerController#add_thing (for 144.164.232.114 at Wed Dec 01 16:01:56 CST 2004)
Completed in 0.261485 (3 reqs/sec) | DB: 0.009325 (3%)"

    assert_equal 0.261485, @entry.request_time
  end

  def test_render_time
    assert_equal 0.242475, @entry.render_time

    @entry = LogParser::LogEntry.new "Processing TwinklerController#add_thing (for 144.164.232.114 at Wed Dec 01 16:01:56 CST 2004)
Completed in 0.261485 (3 reqs/sec) | DB: 0.009325 (3%)"

    assert_equal 0, @entry.render_time
  end

  def test_db_time
    assert_equal 0.002876, @entry.db_time
  end

end

class TestLogParser < Test::Unit::TestCase

  def test_class_parse
    log = StringIO.new <<-EOF
Mar  7 00:00:25 online1 rails[59628]: Processing RssController#uber (for 67.18.200.5 at Mon Mar 07 00:00:25 CST 2005)
Mar  7 00:00:25 online1 rails[59628]: Parameters: {:id=>"author", :"rss/uber/author.html/uber/author"=>nil, :action=>"uber", :username=>"looch", :controller=>"rss"}
Mar  7 00:00:25 online1 rails[59628]: Cookie set: auth=dc%2FGUP20BwziF%2BApGecc0pXB0PF0obi55az63ubAFtsnOOdJPkhfJH2U09yuzQD3WtdmWnydLzFcRA78kwi7Gw%3D%3D; path=/; expires=Thu, 05 Mar 2015 06:00:25 GMT
Mar  7 00:00:25 online1 rails[59628]: Cookie set: ubid=kF05DqFH%2F9hRCOxTz%2Bfb8Q7UV%2FI%3D; path=/; expires=Thu, 05 Mar 2015 06:00:25 GMT
Mar  7 00:00:25 online1 rails[59628]: Browser Load (0.003963)   SELECT * FROM browsers WHERE ubid = 'kF05DqFH/9hRCOxTz+fb8Q7UV/I=' LIMIT 1
Mar  7 00:00:25 online1 rails[59628]: Person Load (0.002445)   SELECT * FROM people WHERE username = 'looch' AND active = '1' LIMIT 1
Mar  7 00:00:25 online1 rails[59628]: ProfileImage Load (0.001554)   SELECT * FROM profile_images WHERE id = 2782 LIMIT 1
Mar  7 00:00:25 online1 rails[59628]: Rendering rss/rss2.0 (200 OK)
Mar  7 00:00:25 online1 rails[59628]: Completed in 0.034519 (28 reqs/sec) | Rendering: 0.011770 (34%) | DB: 0.007962 (23%)
        EOF

    entries = []

    LogParser.parse log do |entry|
      entries << entry
    end

    assert_equal 1, entries.length
    assert_equal 'RssController#uber', entries.first.page
  end

  def test_class_parse_components
    log = StringIO.new <<-EOF
Jul 11 10:05:20 www rails[61243]: Processing ChatroomsController#launch (for 213.152.37.169 at Mon Jul 11 10:05:20 CDT 2005)
Jul 11 10:05:20 www rails[61243]: Start rendering component ({:action=>"online_count", :controller=>"members"}):
Jul 11 10:05:20 www rails[34216]: Processing ChatroomsController#launch (for 213.152.37.169 at Mon Jul 11 10:05:20 CDT 2005)
Jul 11 10:05:20 www rails[34216]: Start rendering component ({:action=>"online_count", :controller=>"members"}):
Jul 11 10:05:20 www rails[34216]: Processing MembersController#online_count (for 213.152.37.169 at Mon Jul 11 10:05:20 CDT 2005)
Jul 11 10:05:20 www rails[34216]: Completed in 0.00741 (135 reqs/sec) | DB: 0.00320 (43%)
Jul 11 10:05:20 www rails[34216]: End of component rendering
Jul 11 10:05:28 www rails[34216]: Completed in 8.65005 (0 reqs/sec) | Rendering: 8.64820 (99%) | DB: 0.00000 (0%)
Jul 11 10:05:20 www rails[34216]: Processing ChatroomsController#launch (for 213.152.37.169 at Mon Jul 11 10:05:20 CDT 2005)
Jul 11 10:05:20 www rails[34216]: Start rendering component ({:action=>"online_count", :controller=>"members"}):
Jul 11 10:05:20 www rails[34216]: Processing MembersController#online_count (for 213.152.37.169 at Mon Jul 11 10:05:20 CDT 2005)
Jul 11 10:05:20 www rails[34216]: Completed in 0.00741 (135 reqs/sec) | DB: 0.00320 (43%)
Jul 11 10:05:20 www rails[34216]: End of component rendering
Jul 11 10:05:28 www rails[34216]: Completed in 8.65005 (0 reqs/sec) | Rendering: 8.64820 (99%) | DB: 0.00000 (0%)
Jul 11 10:05:20 www rails[61243]: Processing MembersController#online_count (for 213.152.37.169 at Mon Jul 11 10:05:20 CDT 2005)
Jul 11 10:05:20 www rails[61243]: Completed in 0.00741 (135 reqs/sec) | DB: 0.00320 (43%)
Jul 11 10:05:20 www rails[61243]: End of component rendering
Jul 11 10:05:28 www rails[61243]: Completed in 8.65005 (0 reqs/sec) | Rendering: 8.64820 (99%) | DB: 0.00000 (0%)
        EOF

    entries = []
    LogParser.parse(log) { |entry| entries << entry }

    assert_equal 3, entries.length
    assert_equal 'ChatroomsController#launch', entries.first.page
    assert_equal 8.65005, entries.first.request_time
  end

  def test_class_parse_entries_with_pre_processing_garbage
    log = StringIO.new <<-EOF
Jan 03 12:51:34 duo2 rails[4347]: [4;36;1mFont Load (0.000475)[0m   [0;1mSELECT * FROM fonts ORDER BY name [0m
Jan 03 12:51:34 duo2 rails[4347]: Processing StylesheetsController#show (for 127.0.0.1 at 2007-01-03 12:51:34) [GET]
Jan 03 12:51:34 duo2 rails[4347]: Parameters: {"action"=>"show", "id"=>"1", "controller"=>"stylesheets"}
Jan 03 12:51:34 duo2 rails[4347]: [4;35;1mNewspaper Load (0.000970)[0m   [0mSELECT newspapers.* FROM newspapers INNER JOIN users ON newspapers.editor_in_chief = users.id WHERE (users.login = 'geoff') LIMIT 1[0m
Jan 03 12:51:34 duo2 rails[4347]: [4;36;1mLayout Load (0.000501)[0m   [0;1mSELECT * FROM layouts WHERE (layouts.id = 1) LIMIT 1[0m
Jan 03 12:51:34 duo2 rails[4347]: Completed in 0.00807 (123 reqs/sec) | Rendering: 0.00006 (0%) | DB: 0.00195 (24%) | 200 OK [http://geoff.localhost.com/stylesheets/show/1/styles.css]
    EOF

    entries = []
    LogParser.parse(log) { |entry| entries << entry }

    assert_equal 1, entries.length, "Number of entries was incorrect"
    assert_equal 'StylesheetsController#show', entries.first.page
    assert_equal 0.00807, entries.first.request_time
  end

  def test_class_parse_rails_engines_plugin
    log = StringIO.new <<-EOF
Jan 03 12:24:21 duo2 rails[4277]: Trying to start engine 'login_engine' from '/Users/topfunky/web/rails/repos/roughunderbelly/vendor/plugins/login_engine'
Jan 03 12:24:21 duo2 rails[4277]: adding /Users/topfunky/web/rails/repos/roughunderbelly/vendor/plugins/login_engine/lib/login_engine to the load path
Jan 03 12:24:21 duo2 rails[4277]: adding /Users/topfunky/web/rails/repos/roughunderbelly/vendor/plugins/login_engine/app/views/user_notify to the load path
Jan 03 12:24:21 duo2 rails[4277]: adding /Users/topfunky/web/rails/repos/roughunderbelly/vendor/plugins/login_engine/app/views/user to the load path
Jan 03 12:24:21 duo2 rails[4277]: adding /Users/topfunky/web/rails/repos/roughunderbelly/vendor/plugins/login_engine/app/views to the load path
Jan 03 12:24:21 duo2 rails[4277]: adding /Users/topfunky/web/rails/repos/roughunderbelly/vendor/plugins/login_engine/app/models to the load path
Jan 03 12:24:21 duo2 rails[4277]: adding /Users/topfunky/web/rails/repos/roughunderbelly/vendor/plugins/login_engine/app/helpers to the load path
Jan 03 12:24:21 duo2 rails[4277]: adding /Users/topfunky/web/rails/repos/roughunderbelly/vendor/plugins/login_engine/app/controllers to the load path
Jan 03 12:24:21 duo2 rails[4277]: Attempting to copy public engine files from '/Users/topfunky/web/rails/repos/roughunderbelly/config/../vendor/plugins/login_engine/public'
Jan 03 12:24:21 duo2 rails[4277]: source dirs: ["/Users/topfunky/web/rails/repos/roughunderbelly/config/../vendor/plugins/login_engine/public/stylesheets"]
Jan 03 12:24:22 duo2 rails[4277]: finally loading from application: 'exception_notifier.rb'
Jan 03 12:24:22 duo2 rails[4277]: requiring file 'exception_notifier_helper'
Jan 03 12:24:22 duo2 rails[4277]: checking 'login_engine' for /Users/topfunky/web/rails/repos/roughunderbelly/config/../vendor/plugins/login_engine/exception_notifier_helper.rb
Jan 03 12:24:22 duo2 rails[4277]: finally loading from application: 'exception_notifier_helper.rb'
Jan 03 12:24:23 duo2 rails[4277]: finally loading from application: '/Users/topfunky/web/rails/repos/roughunderbelly/config/../app/controllers/application.rb'
Jan 03 12:24:23 duo2 rails[4277]: requiring file 'application_helper'
Jan 03 12:24:23 duo2 rails[4277]: checking 'login_engine' for /Users/topfunky/web/rails/repos/roughunderbelly/config/../vendor/plugins/login_engine/application_helper.rb
Jan 03 12:24:23 duo2 rails[4277]: finally loading from application: 'application_helper.rb'
Jan 03 12:24:23 duo2 rails[4277]: finally loading from application: 'exception_notifiable.rb'
Jan 03 12:24:23 duo2 rails[4277]: requiring file 'user_helper'
Jan 03 12:24:23 duo2 rails[4277]: checking 'login_engine' for /Users/topfunky/web/rails/repos/roughunderbelly/config/../vendor/plugins/login_engine/user_helper.rb
Jan 03 12:24:23 duo2 rails[4277]: finally loading from application: 'user_helper.rb'
Jan 03 12:24:23 duo2 rails[4277]: finally loading from application: 'user.rb'
Jan 03 12:24:23 duo2 rails[4277]: finally loading from application: 'task.rb'
Jan 03 12:24:23 duo2 rails[4277]: finally loading from application: 'client.rb'
Jan 03 12:24:23 duo2 rails[4277]: finally loading from application: 'email.rb'
Jan 03 12:24:23 duo2 rails[4277]: finally loading from application: 'worth.rb'
Jan 03 12:24:23 duo2 rails[4277]: finally loading from application: 'column_pref.rb'
Jan 03 12:24:23 duo2 rails[4277]: finally loading from application: 'timer.rb'
Jan 03 12:24:23 duo2 rails[4277]: requiring file '/Users/topfunky/web/rails/repos/roughunderbelly/config/../app/controllers/tasks_controller.rb'
Jan 03 12:24:23 duo2 rails[4277]: detected RAILS_ROOT, rewriting to 'app/controllers/tasks_controller.rb'
Jan 03 12:24:23 duo2 rails[4277]: checking 'login_engine' for /Users/topfunky/web/rails/repos/roughunderbelly/config/../vendor/plugins/login_engine/app/controllers/tasks_controller.rb
Jan 03 12:24:23 duo2 rails[4277]: finally loading from application: '/Users/topfunky/web/rails/repos/roughunderbelly/config/../app/controllers/tasks_controller.rb'
Jan 03 12:24:23 duo2 rails[4277]: requiring file 'tasks_helper'
Jan 03 12:24:23 duo2 rails[4277]: checking 'login_engine' for /Users/topfunky/web/rails/repos/roughunderbelly/config/../vendor/plugins/login_engine/tasks_helper.rb
Jan 03 12:24:23 duo2 rails[4277]: finally loading from application: 'tasks_helper.rb'
Jan 03 12:24:23 duo2 rails[4277]: requiring file 'sparklines_helper'
Jan 03 12:24:23 duo2 rails[4277]: checking 'login_engine' for /Users/topfunky/web/rails/repos/roughunderbelly/config/../vendor/plugins/login_engine/sparklines_helper.rb
Jan 03 12:24:23 duo2 rails[4277]: finally loading from application: 'sparklines_helper.rb'
Jan 03 12:24:24 duo2 rails[4277]: [4;36;1mSQL (0.000072)[0m   [0;1mBEGIN[0m
Jan 03 12:24:24 duo2 rails[4277]: [4;35;1mSQL (0.000240)[0m   [0mINSERT INTO sessions (`updated_at`, `session_id`, `data`) VALUES('2007-01-03 20:24:24', 'bdbb75323d5da69f707d5576e907706e', 'BAh7AA==\n')[0m
Jan 03 12:24:24 duo2 rails[4277]: [4;36;1mSQL (0.000400)[0m   [0;1mCOMMIT[0m
Jan 03 12:24:24 duo2 rails[4277]: Processing TasksController#index (for 127.0.0.1 at 2007-01-03 12:24:24) [GET]
Jan 03 12:24:24 duo2 rails[4277]: Parameters: {"action"=>"index", "controller"=>"tasks"}
Jan 03 12:24:24 duo2 rails[4277]: Redirected to http://localhost:3000/tasks/list
Jan 03 12:24:24 duo2 rails[4277]: Completed in 0.00112 (896 reqs/sec) | DB: 0.00071 (63%) | 302 Found [http://localhost/]
    EOF

    entries = []
    LogParser.parse(log) { |entry| entries << entry }

    assert_equal 1, entries.length, "The number of entries was incorrect"
    assert_equal 'TasksController#index', entries.first.page
    assert_equal 0.00112, entries.first.request_time
  end

  def test_class_parse_multi
    entries = []
    File.open 'test/test.syslog.log' do |fp|
      LogParser.parse fp do |entry|
        entries << entry
      end
    end

    assert_equal 12, entries.length
    assert_equal 'RssController#uber', entries.first.page

    redirect = entries[5]
    assert_equal 'TeamsController#progress', redirect.page
    assert_equal 0, redirect.render_time

    last = entries.last
    assert_equal 'PeopleController#progress', last.page
    assert_equal 0, last.request_time
  end

  def test_class_parse_0_14_x
    entries = []
    File.open 'test/test.syslog.0.14.x.log' do |fp|
      LogParser.parse fp do |entry|
        entries << entry
      end
    end
  end

end

