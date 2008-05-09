class SettingsController < ApplicationController
  def update
    ["logged_controller_id", "logged_action_id", "query_type"].each do |filter_name|
      if (value = params[:filters][filter_name]) && !params[:filters][filter_name].blank?
        session[:filters][filter_name] = value
      else
        session[:filters][filter_name] = nil
      end
    end
    session[:sort_by] = params[:sort_by]
    $current_palmist_site = APP_CONFIG["palmist"][params[:site]]
    
    redirect_to :back
  end
end
