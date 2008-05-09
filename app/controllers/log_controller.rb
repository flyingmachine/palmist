class LogController < ApplicationController
  def refresh
    analyzer = PalmistAnalyzer.new $current_palmist_site["log_location"]
    last_request = LoggedRequest.last_request_for_current_site
    end_position = last_request ? last_request.end_position : 0
    analyzer.process(end_position)
    redirect_to :back
  end
  
  # It would be awesome to have javascript just detect if the window was being viewed and start/stop
  # refreshing based on that
  def continuously_refresh
    session[:continuously_refresh] = true
    redirect_to :back
  end
  
  def stop_automatic_refresh
    session[:continuously_refresh] = false
    redirect_to :back
  end
end
