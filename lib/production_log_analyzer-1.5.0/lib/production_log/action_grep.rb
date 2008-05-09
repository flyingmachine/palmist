module ActionGrep; end

class << ActionGrep

  def grep(action_name, file_name)
    unless action_name =~ /\A([A-Z][A-Za-z\d]*)(?:#([A-Za-z]\w*))?\Z/ then
      raise ArgumentError, "Invalid action name #{action_name} expected something like SomeController#action"
    end

    unless File.file? file_name and File.readable? file_name then
      raise ArgumentError, "Unable to read #{file_name}"
    end

    buckets = Hash.new { |h,k| h[k] = [] }
    comp_count = Hash.new 0

    File.open file_name do |fp|
      fp.each_line do |line|
        line =~ / ([^ ]+) ([^ ]+)\[(\d+)\]: (.*)/
        next if $2.nil? or $2 == 'newsyslog'
        bucket = [$1, $2, $3].join '-'
        data = $4

        buckets[bucket] << line

        case data
        when /^Start rendering component / then
          comp_count[bucket] += 1
        when /^End of component rendering$/ then
          comp_count[bucket] -= 1
        when /^Completed/ then
          next unless comp_count[bucket] == 0
          action = buckets.delete bucket
          next unless action.any? { |l| l =~ /: Processing #{action_name}/ }
          puts action.join
        end
      end
    end
  end

end

