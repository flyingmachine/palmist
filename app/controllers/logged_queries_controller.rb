class LoggedQueriesController < ApplicationController
  
  #this is a bit of a mess right now
  def explain
    ActiveRecord::Base.establish_connection(LOCAL_SQL_CONFIG)
    
    @query = LoggedQuery.find(params[:id])
    @query.query
    
    ActiveRecord::Base.establish_connection($current_palmist_site["remote_sql_config"])
    @explained = ActiveRecord::Base.connection.execute("EXPLAIN #{@query.query}")
    
    ActiveRecord::Base.establish_connection(LOCAL_SQL_CONFIG)
  end  
end
