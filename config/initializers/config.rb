# APP_CONFIG
# SITES
# LOCAL_SQL_CONFIG

# APP_CONFIG
raw_config = File.read(RAILS_ROOT + "/config/config.yml") 
APP_CONFIG = YAML.load(raw_config)[RAILS_ENV] 

# set log_location, mysql configuration, defaults
APP_CONFIG["palmist"].each do |key, value_hash|
  # make this easier to read, understand
  current_config = APP_CONFIG["palmist"][key]

  # defaults
  current_config["environment"] ||= "development"
  current_config["log_name"] ||= current_config["environment"] + ".log"
  current_config["name"] ||= key

  current_config["log_location"] = File.join(current_config["rails_location"], "log", current_config["log_name"])
  
  remote_environment = current_config["environment"]
  current_config["remote_sql_config"] = YAML.load(open(File.join(current_config["rails_location"], 'config', 'database.yml')))[remote_environment]
end

$current_palmist_site = APP_CONFIG["palmist"][APP_CONFIG["palmist"].keys.first]

# SITES
SITES = APP_CONFIG["palmist"].keys

# LOCAL_SQL_CONFIG
LOCAL_SQL_CONFIG = YAML.load(open(File.join(RAILS_ROOT, 'config', 'database.yml')))["development"]