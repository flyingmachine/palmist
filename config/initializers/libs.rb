lib_path = File.join(File.dirname(__FILE__), '..', '..', 'lib')

pl_analyzer_path = File.join(lib_path, 'production_log_analyzer-1.5.0', 'lib', 'production_log')
["action_grep", "analyzer", "palmist_analyzer", "parser"].each do |to_require|
  require File.join(pl_analyzer_path, to_require)
end