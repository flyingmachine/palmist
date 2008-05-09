class LoggedRequestsController < ApplicationController
  def index
    @logged_requests = LoggedRequest.paginate_with_filters({:order => "time_of_request DESC", :page => params[:page]}, @filters, @sort_by)
  end
end
