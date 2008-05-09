# == Schema Information
# Schema version: 1
#
# Table name: logged_requests
#
#  id                   :integer(11)     not null, primary key
#  params               :string(255)     
#  request_time         :decimal(9, 6)   
#  db_time              :decimal(9, 6)   
#  render_time          :decimal(9, 6)   
#  time_of_request      :datetime        
#  logged_queries_count :integer(11)     
#  logged_action_id     :integer(11)     
#  end_position         :integer(11)     
#  start_line_number    :integer(11)     
#

class LoggedRequest < ActiveRecord::Base
  belongs_to :logged_action
  has_many :logged_queries

  def self.per_page
    10
  end
  
  def self.last_request_for_current_site
    find(:first, :order => "logged_requests.id DESC", :include => {:logged_action => :logged_controller}, :conditions => ["logged_controllers.site = ?", $current_palmist_site['name']])
  end
  
  SORT_MAP = {
    "Time of Request" => "time_of_request DESC",
    "DB Time" => "db_time DESC", 
    "Render Time" => "render_time DESC", 
    "Total Request Time" => "request_time DESC", 
    "Number of Queries" => "logged_queries_count"
  }
  
  
  
  def self.paginate_with_filters(options, filters, sort)
    conditions = conditions_from_filters(filters)
    order = get_order(sort)
    
    paginate_options = options.merge(:conditions => conditions, :include => {:logged_action => :logged_controller } )
    if filters["query_type"]
      paginate_options[:joins] = "INNER JOIN logged_queries ON logged_queries.logged_request_id = logged_requests.id"
    end
    
    paginate_options[:order] = order
    
    paginate(paginate_options)
  end
  
  def self.get_order(sort)
    SORT_MAP[sort]
  end
  
  def self.sort_options
    SORT_MAP.keys
  end
  
  
  
  def logged_controller
    logged_action.logged_controller
  end
  
  def logged_queries_with_filters(filters)
    logged_queries.find_with_filters(filters)
  end
  
  
  ["select", "insert", "update", "delete", "show"].each do |query_type|
    module_eval <<-"end;"
      def #{query_type}_queries_count
        logged_queries.select{|lq|lq.query_type == '#{query_type.upcase}'}.size
      end
    end;
  end  
  
  def duplicate_queries
    @duplicate_queries ||= logged_queries.find(
      :all,
      :select => "query_text_id, COUNT(*) as group_count",
      :group => "query_text_id"
    )
  end
  
  def duplicate_query_count
    duplicate_queries.collect{|lq| lq.group_count.to_i - 1}.sum
  end
  
  def duplicate_query_text_ids
    @duplicate_query_text_ids ||= duplicate_queries.select{|lq|lq.group_count.to_i > 1}.collect{ |lq| lq.query_text_id.to_i }
  end
end
