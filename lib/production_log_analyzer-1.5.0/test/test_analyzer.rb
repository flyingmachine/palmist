#!/usr/local/bin/ruby -w

$TESTING = true

require 'test/unit'

require 'production_log/analyzer'

class TestEnumerable < Test::Unit::TestCase

  def test_sum
    assert_equal 45, (1..9).sum
  end

  def test_average
    # Ranges don't have a length
    assert_in_delta 5.0, (1..9).to_a.average, 0.01
  end

  def test_sample_variance
    assert_in_delta 6.6666, (1..9).to_a.sample_variance, 0.0001
  end

  def test_standard_deviation
    assert_in_delta 2.5819, (1..9).to_a.standard_deviation, 0.0001
  end

end

class TestSizedList < Test::Unit::TestCase

  def setup
    @list = SizedList.new 10 do |arr,|
      arr.delete_at 0
    true
    end
  end

  def test_append
    assert_equal [], @list.entries

    (1..10).each { |i| @list << i }
    assert_equal 10, @list.length
    assert_equal((1..10).to_a, @list.entries)

    @list << 11
    assert_equal 10, @list.length
    assert_equal((2..11).to_a, @list.entries)
  end

end

class TestSlowestTimes < Test::Unit::TestCase

  def setup
    @list = SlowestTimes.new 10
  end

  def test_that_it_works
    expected = []

    10.downto(1) do |i|
      @list << [i, nil]
      expected << [i, nil]
    end

    assert_equal expected, @list.entries

    @list << [11, nil]
    expected.pop
    expected.push [11, nil]

    assert_equal 10, @list.length
    assert_equal expected, @list.entries

    @list << [0, nil]

    assert_equal expected, @list.entries
  end

end

class TestAnalyzer < Test::Unit::TestCase

  def setup
    @analyzer = Analyzer.new 'test/test.syslog.log'
    @analyzer.process
  end

  def test_self_email
    email = Analyzer.email('test/test.syslog.log', 'devnull@robotcoop.com',
                           nil, 1)
    expected = <<-EOF
Subject: pl_analyze
To: devnull@robotcoop.com
Content-Type: text/html

<pre>Request Times Summary:    	Count	Avg	Std Dev	Min	Max
ALL REQUESTS:             	11	0.576	0.508	0.000	1.470

ThingsController#view:    	3	0.716	0.387	0.396	1.260
TeamsController#progress: 	2	0.841	0.629	0.212	1.470
RssController#uber:       	2	0.035	0.000	0.035	0.035
PeopleController#progress:	2	0.489	0.489	0.000	0.977
PeopleController#view:    	2	0.731	0.371	0.360	1.102

Slowest Request Times:
\tTeamsController#progress took 1.470s

------------------------------------------------------------------------

DB Times Summary:         	Count	Avg	Std Dev	Min	Max
ALL REQUESTS:             	11	0.366	0.393	0.000	1.144

ThingsController#view:    	3	0.403	0.362	0.122	0.914
TeamsController#progress: 	2	0.646	0.497	0.149	1.144
RssController#uber:       	2	0.008	0.000	0.008	0.008
PeopleController#progress:	2	0.415	0.415	0.000	0.830
PeopleController#view:    	2	0.338	0.149	0.189	0.486

Slowest Total DB Times:
\tTeamsController#progress took 1.144s

------------------------------------------------------------------------

Render Times Summary:     	Count	Avg	Std Dev	Min	Max
ALL REQUESTS:             	11	0.219	0.253	0.000	0.695

ThingsController#view:    	3	0.270	0.171	0.108	0.506
TeamsController#progress: 	2	0.000	0.000	0.000	0.000
RssController#uber:       	2	0.012	0.000	0.012	0.012
PeopleController#progress:	2	0.302	0.302	0.000	0.604
PeopleController#view:    	2	0.487	0.209	0.278	0.695

Slowest Total Render Times:
\tPeopleController#view took 0.695s
</pre>
      EOF

    assert_equal expected, email
  end

  def test_self_envelope
    expected = [
      "Subject: pl_analyze",
      "To: devnull@example.com",
      "Content-Type: text/html"
    ]

    assert_equal expected, Analyzer.envelope('devnull@example.com')
  end

  def test_self_envelope_subject
    expected = [
      "Subject: happy fancy boom",
      "To: devnull@example.com",
      "Content-Type: text/html"
    ]

    assert_equal(expected,
                 Analyzer.envelope('devnull@example.com', 'happy fancy boom'))
  end

  def test_average_db_time
    assert_in_delta 0.4023761, @analyzer.average_db_time, 0.0000001
  end

  def test_average_render_time
    assert_in_delta 0.3015584, @analyzer.average_render_time, 0.0000001
  end

  def test_average_request_time
    assert_in_delta 0.6338176, @analyzer.average_request_time, 0.0000001
  end

  def test_db_time_std_dev
    assert_in_delta 0.3941380, @analyzer.db_time_std_dev, 0.0000001
  end

  def test_db_times_summary
    expected = <<EOF.strip
DB Times Summary:         	Count	Avg	Std Dev	Min	Max
ALL REQUESTS:             	11	0.366	0.393	0.000	1.144

ThingsController#view:    	3	0.403	0.362	0.122	0.914
TeamsController#progress: 	2	0.646	0.497	0.149	1.144
RssController#uber:       	2	0.008	0.000	0.008	0.008
PeopleController#progress:	2	0.415	0.415	0.000	0.830
PeopleController#view:    	2	0.338	0.149	0.189	0.486
EOF

    assert_equal expected, @analyzer.db_times_summary
  end

  def test_empty_syslog
    analyzer = Analyzer.new 'test/test.syslog.empty.log'
    assert_nothing_raised do
      analyzer.process
      analyzer.report(1)
    end
    assert_equal "No requests to analyze", analyzer.report(1)
  end

  def test_logfile_name
    assert_equal 'test/test.syslog.log', @analyzer.logfile_name
  end

  def test_longest_request_name
    assert_equal false, @analyzer.instance_variables.include?('@longest_req')

    request_times = {
      "ThingsController#view"     => [0],
      "TeamsController#progress"  => [1],
      "RssController#uber"        => [0],
      "PeopleController#progress" => [0],
      nil                         => [0],
    }

    @analyzer.instance_variable_set('@request_times', request_times)

    assert_equal 26, @analyzer.longest_request_name
  end

  def test_pad_request_name
    assert_equal 26, @analyzer.longest_request_name
    assert_equal("PeopleController#view:    ",
                 @analyzer.pad_request_name("PeopleController#view"))
  end

  def test_pad_request_name_nil
    assert_equal 26, @analyzer.longest_request_name
    assert_equal("Unknown:                  ",
                 @analyzer.pad_request_name(nil))
  end

  def test_pad_request_name_short
    analyzer = Analyzer.new 'test/test.syslog.1.2.shortname.log'
    analyzer.process
    longer_request_name_value = " " * (analyzer.longest_request_name + 1)
    assert_nothing_raised do
      analyzer.pad_request_name(longer_request_name_value)
    end
    assert_equal longer_request_name_value + ":", analyzer.pad_request_name(longer_request_name_value)
  end

  def test_process
    expected_request_times = {
      "PeopleController#view"     => [1.102098, 0.36021],
      "ThingsController#view"     => [0.396183, 0.49176, 1.259728],
      "TeamsController#progress"  => [1.469788, 0.211973],
      "RssController#uber"        => [0.034519, 0.034519],
      "PeopleController#progress" => [0.977398, 0]
    }
    assert_equal expected_request_times, @analyzer.request_times

    expected_db_times = {
      "PeopleController#view"     => [0.486258, 0.189119],
      "ThingsController#view"     => [0.122158, 0.172767, 0.914192],
      "TeamsController#progress"  => [1.143577, 0.149357],
      "RssController#uber"        => [0.007962, 0.007962],
      "PeopleController#progress" => [0.830409, 0]
    }
    assert_equal expected_db_times, @analyzer.db_times

    expected_render_times = {
      "PeopleController#view"     => [0.695476, 0.277921],
      "ThingsController#view"     => [0.107987, 0.197126, 0.505973],
      "TeamsController#progress"  => [0, 0],
      "RssController#uber"        => [0.01177, 0.01177],
      "PeopleController#progress" => [0.604444, 0]
    }
    assert_equal expected_render_times, @analyzer.render_times
  end

  def test_render_time_std_dev
    assert_in_delta 0.2513925, @analyzer.render_time_std_dev, 0.0000001
  end

  def test_render_times_summary
    expected = <<EOF.strip
Render Times Summary:     	Count	Avg	Std Dev	Min	Max
ALL REQUESTS:             	11	0.219	0.253	0.000	0.695

ThingsController#view:    	3	0.270	0.171	0.108	0.506
TeamsController#progress: 	2	0.000	0.000	0.000	0.000
RssController#uber:       	2	0.012	0.000	0.012	0.012
PeopleController#progress:	2	0.302	0.302	0.000	0.604
PeopleController#view:    	2	0.487	0.209	0.278	0.695
EOF

    assert_equal expected, @analyzer.render_times_summary
  end

  def test_report
    expected = <<-EOF
Request Times Summary:    	Count	Avg	Std Dev	Min	Max
ALL REQUESTS:             	11	0.576	0.508	0.000	1.470

ThingsController#view:    	3	0.716	0.387	0.396	1.260
TeamsController#progress: 	2	0.841	0.629	0.212	1.470
RssController#uber:       	2	0.035	0.000	0.035	0.035
PeopleController#progress:	2	0.489	0.489	0.000	0.977
PeopleController#view:    	2	0.731	0.371	0.360	1.102

Slowest Request Times:
\tTeamsController#progress took 1.470s
\tThingsController#view took 1.260s
\tPeopleController#view took 1.102s
\tPeopleController#progress took 0.977s
\tThingsController#view took 0.492s
\tThingsController#view took 0.396s
\tPeopleController#view took 0.360s
\tTeamsController#progress took 0.212s
\tRssController#uber took 0.035s
\tRssController#uber took 0.035s

------------------------------------------------------------------------

DB Times Summary:         	Count	Avg	Std Dev	Min	Max
ALL REQUESTS:             	11	0.366	0.393	0.000	1.144

ThingsController#view:    	3	0.403	0.362	0.122	0.914
TeamsController#progress: 	2	0.646	0.497	0.149	1.144
RssController#uber:       	2	0.008	0.000	0.008	0.008
PeopleController#progress:	2	0.415	0.415	0.000	0.830
PeopleController#view:    	2	0.338	0.149	0.189	0.486

Slowest Total DB Times:
\tTeamsController#progress took 1.144s
\tThingsController#view took 0.914s
\tPeopleController#progress took 0.830s
\tPeopleController#view took 0.486s
\tPeopleController#view took 0.189s
\tThingsController#view took 0.173s
\tTeamsController#progress took 0.149s
\tThingsController#view took 0.122s
\tRssController#uber took 0.008s
\tRssController#uber took 0.008s

------------------------------------------------------------------------

Render Times Summary:     	Count	Avg	Std Dev	Min	Max
ALL REQUESTS:             	11	0.219	0.253	0.000	0.695

ThingsController#view:    	3	0.270	0.171	0.108	0.506
TeamsController#progress: 	2	0.000	0.000	0.000	0.000
RssController#uber:       	2	0.012	0.000	0.012	0.012
PeopleController#progress:	2	0.302	0.302	0.000	0.604
PeopleController#view:    	2	0.487	0.209	0.278	0.695

Slowest Total Render Times:
\tPeopleController#view took 0.695s
\tPeopleController#progress took 0.604s
\tThingsController#view took 0.506s
\tPeopleController#view took 0.278s
\tThingsController#view took 0.197s
\tThingsController#view took 0.108s
\tRssController#uber took 0.012s
\tRssController#uber took 0.012s
\tTeamsController#progress took 0.000s
\tTeamsController#progress took 0.000s
      EOF

    assert_equal expected, @analyzer.report(10)
  end

  def test_request_time_std_dev
    assert_in_delta 0.4975667, @analyzer.request_time_std_dev, 0.0000001
  end

  def test_request_times_summary
    expected = <<EOF.strip
Request Times Summary:    	Count	Avg	Std Dev	Min	Max
ALL REQUESTS:             	11	0.576	0.508	0.000	1.470

ThingsController#view:    	3	0.716	0.387	0.396	1.260
TeamsController#progress: 	2	0.841	0.629	0.212	1.470
RssController#uber:       	2	0.035	0.000	0.035	0.035
PeopleController#progress:	2	0.489	0.489	0.000	0.977
PeopleController#view:    	2	0.731	0.371	0.360	1.102
EOF

    assert_equal expected, @analyzer.request_times_summary
  end

  def test_slowest_db_times
    times = @analyzer.slowest_db_times 3
    assert_equal 3, times.length
    expected = [
      [1.143577, "TeamsController#progress"],
      [0.914192, "ThingsController#view"],
      [0.830409, "PeopleController#progress"]
    ]
    assert_equal expected, times
  end

  def test_slowest_request_times
    times = @analyzer.slowest_request_times 3
    assert_equal 3, times.length
    expected = [
      [1.469788, "TeamsController#progress"],
      [1.259728, "ThingsController#view"],
      [1.102098, "PeopleController#view"]
    ]
    assert_equal expected, times
  end

  def test_slowest_render_times
    times = @analyzer.slowest_render_times 3
    assert_equal 3, times.length
    expected = [
      [0.695476, "PeopleController#view"],
      [0.604444, "PeopleController#progress"],
      [0.505973, "ThingsController#view"]
    ]
    assert_equal expected, times
  end

end

