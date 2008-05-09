#!/usr/local/bin/ruby -w

require 'stringio'
require 'tempfile'
require 'test/unit'

require 'production_log/action_grep'

class TestActionGrep < Test::Unit::TestCase

  def setup
    @syslog_file_name = File.expand_path(File.join(File.dirname(__FILE__),
                                                   'test.syslog.log'))
  end

  def test_module_grep
    old_stdout = $stdout.dup
    stdout = StringIO.new
    $stdout = stdout

    ActionGrep.grep 'RssController', @syslog_file_name

    stdout.rewind

    lines = stdout.readlines

    assert_equal 19, lines.length

  ensure
    $stdout = old_stdout
  end

  def test_module_grep_arguments
    file = Tempfile.new File.basename(__FILE__)

    assert_raises ArgumentError do
      ActionGrep.grep 'Foo_Controller', '/tmp/no_such_file/no_really/'
    end

    assert_raises ArgumentError do
      ActionGrep.grep 'FooController#5', '/tmp/no_such_file/no_really/'
    end

    assert_raises ArgumentError do
      ActionGrep.grep '5', '/tmp/no_such_file/no_really/'
    end

    assert_raises ArgumentError do
      ActionGrep.grep 'FooController', '/tmp/no_such_file/no_really'
    end

    assert_nothing_raised do
      ActionGrep.grep 'FooController', file.path
      ActionGrep.grep 'FooController5', file.path
      ActionGrep.grep 'FooController#action', file.path
      ActionGrep.grep 'FooController#action_thingy', file.path
      ActionGrep.grep 'FooController#action_thingy5', file.path
      ActionGrep.grep 'FooController5#action', file.path
      ActionGrep.grep 'FooController5#action_thingy', file.path
      ActionGrep.grep 'FooController5#action_thingy5', file.path
    end

  ensure
    file.close
  end

end

