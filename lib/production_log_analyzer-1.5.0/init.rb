require_path = File.join(File.dirname(__FILE__), 'lib', 'production_log')
["action_grep", "analyzer", "palmist_analyzer", "parser"].each do |to_require|
  require File.join(require_path, to_require)
end