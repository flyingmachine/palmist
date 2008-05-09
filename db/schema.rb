# This file is auto-generated from the current state of the database. Instead of editing this file, 
# please use the migrations feature of ActiveRecord to incrementally modify your database, and
# then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your database schema. If you need
# to create the application database on another system, you should be using db:schema:load, not running
# all the migrations from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 1) do

  create_table "logged_actions", :force => true do |t|
    t.string  "name"
    t.integer "logged_controller_id"
  end

  create_table "logged_controllers", :force => true do |t|
    t.string "name"
    t.string "site"
  end

  create_table "logged_queries", :force => true do |t|
    t.integer "query_text_id"
    t.decimal "execution_time",    :precision => 9, :scale => 6
    t.integer "logged_request_id"
    t.string  "query_type"
  end

  add_index "logged_queries", ["query_text_id"], :name => "index_logged_queries_on_query_text_id"
  add_index "logged_queries", ["logged_request_id"], :name => "index_logged_queries_on_logged_request_id"

  create_table "logged_requests", :force => true do |t|
    t.string   "params"
    t.decimal  "request_time",         :precision => 9, :scale => 6
    t.decimal  "db_time",              :precision => 9, :scale => 6
    t.decimal  "render_time",          :precision => 9, :scale => 6
    t.datetime "time_of_request"
    t.integer  "logged_queries_count"
    t.integer  "logged_action_id"
    t.integer  "end_position"
    t.integer  "start_line_number"
  end

  create_table "query_texts", :force => true do |t|
    t.text "query"
  end

end
