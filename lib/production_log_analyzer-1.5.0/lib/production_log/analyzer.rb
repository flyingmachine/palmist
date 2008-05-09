$TESTING = false unless defined? $TESTING

module Enumerable

  ##
  # Sum of all the elements of the Enumerable
  
  # had to comment this out because it interferes with rails method
  # def sum
  #   return self.inject(0) { |acc, i| acc + i }
  # end

  ##
  # Average of all the elements of the Enumerable
  #
  # The Enumerable must respond to #length

  def average
    return self.sum / self.length.to_f
  end

  ##
  # Sample variance of all the elements of the Enumerable
  #
  # The Enumerable must respond to #length

  def sample_variance
    avg = self.average
    sum = self.inject(0) { |acc, i| acc + (i - avg) ** 2 }
    return (1 / self.length.to_f * sum)
  end

  ##
  # Standard deviation of all the elements of the Enumerable
  #
  # The Enumerable must respond to #length

  def standard_deviation
    return Math.sqrt(self.sample_variance)
  end

end

##
# A list that only stores +limit+ items.

class SizedList < Array

  ##
  # Creates a new SizedList that can hold up to +limit+ items.  Whenever
  # adding a new item to the SizedList would make the list larger than
  # +limit+, +delete_block+ is called.
  #
  # +delete_block+ is passed the list and the item being added.
  # +delete_block+ must take action to remove an item and return true or
  # return false if the item should not be added to the list.

  def initialize(limit, &delete_block)
    @limit = limit
    @delete_block = delete_block
  end

  ##
  # Attempts to add +obj+ to the list.

  def <<(obj)
    return super if self.length < @limit
    return super if @delete_block.call self, obj
  end

end

##
# Stores +limit+ time/object pairs, keeping only the largest +limit+ items.
#
# Sample usage:
#
#   l = SlowestTimes.new 5
#   
#   l << [Time.now, 'one']
#   l << [Time.now, 'two']
#   l << [Time.now, 'three']
#   l << [Time.now, 'four']
#   l << [Time.now, 'five']
#   l << [Time.now, 'six']
#
#   p l.map { |i| i.last }

class SlowestTimes < SizedList

  ##
  # Creates a new SlowestTimes SizedList that holds only +limit+ time/object
  # pairs.

  def initialize(limit)
    super limit do |arr, new_item|
      fastest_time = arr.sort_by { |time, name| time }.first
      if fastest_time.first < new_item.first then
        arr.delete_at index(fastest_time)
        true
      else
        false
      end
    end
  end

end

##
# Calculates statistics for production logs.

class Analyzer

  ##
  # The version of the production log analyzer you are using.

  VERSION = '1.5.0'

  ##
  # The logfile being read by the Analyzer.

  attr_reader :logfile_name

  ##
  # An Array of all the request total times for the log file.

  attr_reader :request_times

  ##
  # An Array of all the request database times for the log file.

  attr_reader :db_times

  ##
  # An Array of all the request render times for the log file.

  attr_reader :render_times

  ##
  # Generates and sends an email report with lots of fun stuff in it.  This
  # way, Mail.app will behave when given tabs.

  def self.email(file_name, recipient, subject, count = 10)
    analyzer = self.new file_name
    analyzer.process
    body = analyzer.report count

    email = self.envelope(recipient, subject)
    email << nil
    email << "<pre>#{body}</pre>"
    email = email.join($/) << $/

    return email if $TESTING

    IO.popen("/usr/sbin/sendmail -i -t", "w+") do |sm|
      sm.print email
      sm.flush
    end
  end

  def self.envelope(recipient, subject = nil) # :nodoc:
    envelope = {}
    envelope['To'] = recipient
    envelope['Subject'] = subject || "pl_analyze"
    envelope['Content-Type'] = "text/html"

    return envelope.map { |(k,v)| "#{k}: #{v}" }
  end

  ##
  # Creates a new Analyzer that will read data from +logfile_name+.

  def initialize(logfile_name)
    @logfile_name  = logfile_name
    @request_times = Hash.new { |h,k| h[k] = [] }
    @db_times      = Hash.new { |h,k| h[k] = [] }
    @render_times  = Hash.new { |h,k| h[k] = [] }
  end

  ##
  # Processes the log file collecting statistics from each found LogEntry.

  def process
    File.open @logfile_name do |fp|
      LogParser.parse fp do |entry|
        entry_page = entry.page
        next if entry_page.nil?
        @request_times[entry_page] << entry.request_time
        @db_times[entry_page] << entry.db_time
        @render_times[entry_page] << entry.render_time
      end
    end
  end

  ##
  # The average total request time for all requests.

  def average_request_time
    return time_average(@request_times)
  end

  ##
  # The standard deviation of the total request time for all requests.

  def request_time_std_dev
    return time_std_dev(@request_times)
  end

  ##
  # The +limit+ slowest total request times.

  def slowest_request_times(limit = 10)
    return slowest_times(@request_times, limit)
  end

  ##
  # The average total database time for all requests.

  def average_db_time
    return time_average(@db_times)
  end

  ##
  # The standard deviation of the total database time for all requests.

  def db_time_std_dev
    return time_std_dev(@db_times)
  end

  ##
  # The +limit+ slowest total database times.

  def slowest_db_times(limit = 10)
    return slowest_times(@db_times, limit)
  end

  ##
  # The average total render time for all requests.

  def average_render_time
    return time_average(@render_times)
  end

  ##
  # The standard deviation of the total render time for all requests.

  def render_time_std_dev
    return time_std_dev(@render_times)
  end

  ##
  # The +limit+ slowest total render times for all requests.

  def slowest_render_times(limit = 10)
    return slowest_times(@render_times, limit)
  end

  ##
  # A list of count/min/max/avg/std dev for request times.

  def request_times_summary
    return summarize("Request Times", @request_times)
  end

  ##
  # A list of count/min/max/avg/std dev for database times.

  def db_times_summary
    return summarize("DB Times", @db_times)
  end

  ##
  # A list of count/min/max/avg/std dev for request times.

  def render_times_summary
    return summarize("Render Times", @render_times)
  end

  ##
  # Builds a report containing +count+ slow items.

  def report(count)
    return "No requests to analyze" if request_times.empty?

    text = []

    text << request_times_summary
    text << nil
    text << "Slowest Request Times:"
    slowest_request_times(count).each do |time, name|
      text << "\t#{name} took #{'%0.3f' % time}s"
    end
    text << nil
    text << "-" * 72
    text << nil

    text << db_times_summary
    text << nil
    text << "Slowest Total DB Times:"
    slowest_db_times(count).each do |time, name|
      text << "\t#{name} took #{'%0.3f' % time}s"
    end
    text << nil
    text << "-" * 72
    text << nil

    text << render_times_summary
    text << nil
    text << "Slowest Total Render Times:"
    slowest_render_times(count).each do |time, name|
      text << "\t#{name} took #{'%0.3f' % time}s"
    end
    text << nil

    return text.join($/)
  end

  private unless $TESTING

  def summarize(title, records) # :nodoc:
    record = nil
    list = []

    # header
    record = [pad_request_name("#{title} Summary"), 'Count', 'Avg', 'Std Dev',
              'Min', 'Max']
    list << record.join("\t")

    # all requests
    times = records.values.flatten
    record = [times.average, times.standard_deviation, times.min, times.max]
    record.map! { |v| "%0.3f" % v }
    record.unshift [pad_request_name('ALL REQUESTS'), times.size]
    list << record.join("\t")

    # spacer
    list << nil

    records.sort_by { |k,v| v.size}.reverse_each do |req, times|
      record = [times.average, times.standard_deviation, times.min, times.max]
      record.map! { |v| "%0.3f" % v }
      record.unshift ["#{pad_request_name req}", times.size]
      list << record.join("\t")
    end

    return list.join("\n")
  end

  def slowest_times(records, limit) # :nodoc:
    slowest_times = SlowestTimes.new limit

    records.each do |name, times|
      times.each do |time|
        slowest_times << [time, name]
      end
    end

    return slowest_times.sort_by { |time, name| time }.reverse
  end

  def time_average(records) # :nodoc:
    times = records.values.flatten
    times.delete 0
    return times.average
  end

  def time_std_dev(records) # :nodoc:
    times = records.values.flatten
    times.delete 0
    return times.standard_deviation
  end

  def longest_request_name # :nodoc:
    return @longest_req if defined? @longest_req

    names = @request_times.keys.map do |name|
      (name||'Unknown').length + 1 # + : - HACK where does nil come from?
    end

    @longest_req = names.max

    @longest_req = 'Unknown'.length + 1 if @longest_req.nil?

    return @longest_req
  end

  def pad_request_name(name) # :nodoc:
    name = (name||'Unknown') + ':' # HACK where does nil come from?
    padding_width = longest_request_name - name.length
    padding_width = 0 if padding_width < 0
    name += (' ' * padding_width)
  end

end

