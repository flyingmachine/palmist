class InitialSchema < ActiveRecord::Migration
  def self.up
    create_table :logged_controllers do |t|
      t.column :name, :string
      t.column :site, :string
    end
    execute("ALTER TABLE logged_controllers ENGINE=MyISAM")
    
    create_table :logged_actions do |t|
      t.column :name, :string
      t.column :logged_controller_id, :integer
    end
    execute("ALTER TABLE logged_actions ENGINE=MyISAM")
    
    create_table :logged_requests do |t|
      t.column :params, :string
      t.column :request_time, :decimal, :precision => 9, :scale => 6
      t.column :db_time, :decimal, :precision => 9, :scale => 6
      t.column :render_time, :decimal, :precision => 9, :scale => 6
      t.column :time_of_request, :datetime
      t.column :logged_queries_count, :integer
      t.column :logged_action_id, :integer
      t.column :end_position, :integer
      t.column :start_line_number, :integer
    end
    execute("ALTER TABLE logged_requests ENGINE=MyISAM")
    
    create_table :logged_queries do |t|
      t.column :query_text_id, :integer
      t.column :execution_time, :decimal, :precision => 9, :scale => 6
      t.column :logged_request_id, :integer
      t.column :query_type, :string
    end
    execute("ALTER TABLE logged_queries ENGINE=MyISAM")
    add_index(:logged_queries, :query_text_id)
    add_index(:logged_queries, :logged_request_id)
    
    create_table :query_texts do |t|
      t.column :query, :text
    end

    analyzer = PalmistAnalyzer.new $current_palmist_site["log_location"]
    analyzer.process
  end

  def self.down
  end
end
