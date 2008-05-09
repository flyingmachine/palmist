# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  helper :all # include all helpers, all the time

  # See ActionController::RequestForgeryProtection for details
  # Uncomment the :secret if you're not using the cookie session store
  protect_from_forgery # :secret => 'eb43edf01a4dc437ca3298d65262f6f9'
  
  before_filter(:set_default_variables)
  
  def set_default_variables
    session[:filters] ||= {}
    session[:sort_by] ||= "Time of Request"
    @filters = session[:filters]
    @sort_by = session[:sort_by]
    @logged_controllers = LoggedController.find(:all, :order => "name", :conditions => {:site => $current_palmist_site["name"]})
    @logged_actions = LoggedController.find(@filters["logged_controller_id"]).logged_actions if @filters["logged_controller_id"]
  end
end
