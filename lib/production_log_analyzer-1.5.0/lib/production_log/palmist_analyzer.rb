class PalmistAnalyzer < Analyzer
  def process(offset = 0)
    File.open @logfile_name do |fp|
      if offset > 0
        fp.seek(offset)
      end
      
      LogParser.parse fp do |entry|
        entry_page = entry.page
        next if entry_page.nil? || entry.end_position.to_i == 0
        controller = LoggedController.find_or_create_by_name_and_site(entry.controller, $current_palmist_site["name"])
        action = LoggedAction.find_or_create_by_name_and_logged_controller_id(entry.action, controller.id)
        request = LoggedRequest.create(
          :params => nil,
          :request_time => entry.request_time,
          :db_time => entry.db_time,
          :render_time => entry.render_time,
          :time_of_request => entry.time,
          :logged_action_id => action.id,
          :end_position => entry.end_position,
          :start_line_number => entry.start_line_number
        )
        
        entry.queries.each do |query|
          query_text = QueryText.find_or_create_by_query(query[2])
          LoggedQuery.create(
            :execution_time => query[1].to_f,
            :query_text => query_text,
            :logged_request => request
          )
        end
      end
    end
  end
end