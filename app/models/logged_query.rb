# == Schema Information
# Schema version: 1
#
# Table name: logged_queries
#
#  id                :integer(11)     not null, primary key
#  query             :text            
#  execution_time    :decimal(9, 6)   
#  logged_request_id :integer(11)     
#  query_type        :string(255)     
#

class LoggedQuery < ActiveRecord::Base
  belongs_to :logged_request, :counter_cache => true
  belongs_to :query_text
  before_save :set_query_type
  
  def self.find_with_filters(filters)
    conditions = conditions_from_filters(filters)
    find(
      :all,
      :conditions => conditions,
      :include => { :logged_request => { :logged_action => :logged_controller  } }
    )
  end
  
  def set_query_type
    self.query_type = /\w+/.match(self.query)[0]
  end
  
  def is_select?
    query_type == 'SELECT'
  end
  
  def query
    query_text.query
  end
end
