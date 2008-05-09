##
# LogParser parses a Syslog log file looking for lines logged by the 'rails'
# program.  A typical log line looks like this:
#
#   Mar  7 00:00:20 online1 rails[59600]: Person Load (0.001884)   SELECT * FROM people WHERE id = 10519 LIMIT 1
#
# LogParser does not work with Rails' default logger because there is no way
# to group all the log output of a single request.  You must use SyslogLogger.

module LogParser

  ##
  # LogEntry contains a summary of log data for a single request.

  class LogEntry

    ##
    # Controller and action for this request

    attr_reader :page

    ##
    # Requesting IP

    attr_reader :ip

    ##
    # Time the request was made

    attr_reader :time

    ##
    # Array of SQL queries containing query type and time taken and query.
    attr_reader :queries

    ##
    # Total request time, including database, render and other.

    attr_reader :request_time

    ##
    # Total render time.

    attr_reader :render_time

    ##
    # Total database time

    attr_reader :db_time
    
    ##
    # Position, for analyzing the same file after this position
    
    attr_reader :end_position
    
    attr_reader :start_line_number

    ##
    # Creates a new LogEntry from the log data in +entry+.

    def initialize(entry, end_position = 0, start_line_number = 0)
      @page = nil
      @ip = nil
      @time = nil
      @queries = []
      @request_time = 0
      @render_time = 0
      @db_time = 0
      @in_component = 0
      @end_position = end_position
      @start_line_number = start_line_number

      parse entry
    end

    ##
    # Extracts log data from +entry+, which is an Array of lines from the
    # same request.

    def parse(entry)
      entry.each do |line|
        case line
        when /^Parameters/, /^Cookie set/, /^Rendering/,
          /^Redirected/ then
          # nothing
        when /^Processing ([\S]+) \(for (.+) at (.*)\)/ then
          next if @in_component > 0
          @page = $1
          @ip   = $2
          @time = $3
        when /^Completed in ([\S]+) .+ Rendering: ([\S]+) .+ DB: ([\S]+)/ then
          next if @in_component > 0
          @request_time = $1.to_f
          @render_time = $2.to_f
          @db_time = $3.to_f
        when /^Completed in ([\S]+) .+ DB: ([\S]+)/ then # Redirect
          next if @in_component > 0
          @request_time = $1.to_f
          @render_time = 0
          @db_time = $2.to_f
        when /(.+?) \(([^)]+)\).*?((?:SELECT|UPDATE|DELETE|INSERT|SHOW).*?).[\[\n]/ then
          @queries << [$1, $2.to_f, $3]
        when /^Start rendering component / then
          @in_component += 1
        when /^End of component rendering$/ then
          @in_component -= 1
        when /^Fragment hit: / then
        else # noop
#          raise "Can't handle #{line.inspect}" if $TESTING
        end
      end
    end
    
    ##
    # Controller, derived from page
    
    def controller
      /(.*)Controller/.match(@page)[1]
    end
    
    ##
    # Action, derived from page
    def action
      /#(.*)/.match(@page)[1]
    end
    
    def ==(other) # :nodoc:
      other.class == self.class and
      other.page == self.page and
      other.ip == self.ip and
      other.time == self.time and
      other.queries == self.queries and
      other.request_time == self.request_time and
      other.render_time == self.render_time and
      other.db_time == self.db_time
    end

  end

  ##
  # Parses IO stream +stream+, creating a LogEntry for each recognizable log
  # entry.
  #
  # Log entries are recognised as starting with Processing, continuing with
  # the same process id through Completed.

  def self.parse(stream) # :yields: log_entry
    buckets = Hash.new { |h,k| h[k] = [] }
    comp_count = Hash.new 0
    
    start_line_number = 1
    begin
      while line = stream.readline
        line =~ / ([^ ]+) ([^ ]+)\[(\d+)\]: (.*)/
        next if $2.nil? or $2 == 'newsyslog'
        bucket = [$1, $2, $3].join '-'
        data = $4

        buckets[bucket] << data

        case data
        when /^Start rendering component / then
          comp_count[bucket] += 1
        when /^End of component rendering$/ then
          comp_count[bucket] -= 1
        when /^Completed/ then
          next unless comp_count[bucket] == 0
          entry = buckets.delete bucket
          next unless entry.any? { |l| l =~ /^Processing/ }
          yield LogEntry.new(entry, stream.pos, start_line_number)
          start_line_number = stream.lineno + 1
        end
      end
    rescue #need to just rescur  EOF errors
    end

    buckets.each do |bucket, data|
      yield LogEntry.new(data)
    end
  end

end

