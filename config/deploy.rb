require 'deprec/recipes'

# =============================================================================
# ROLES
# =============================================================================
# You can define any number of roles, each of which contains any number of
# machines. Roles might include such things as :web, or :app, or :db, defining
# what the purpose of each machine is. You can also specify options that can
# be used to single out a specific subset of boxes in a particular role, like
# :primary => true.

set :domain, "query_viewer.com"
role :web, domain
role :app, domain
role :db,  domain, :primary => true

# =============================================================================
# REQUIRED VARIABLES
# =============================================================================
# You must always specify the application and repository for every recipe. The
# repository must be the URL of the repository you want this recipe to
# correspond to. The deploy_to path must be the path on each machine that will
# form the root of the application path.

set :application, "query_viewer"
set :deploy_to, "/var/www/apps/#{application}"

# XXX we may not need this - it doesn't work on windows
set :user, 'deploy'
set :repository, "svn://localhost"
set :rails_env, "production"

# Automatically symlink these directories from current/public to shared/public.
# set :app_symlinks, %w{photo, document, asset}

# =============================================================================
# APACHE OPTIONS
# =============================================================================
set :apache_server_name, domain
# set :apache_server_aliases, %w{alias1 alias2}
# set :apache_default_vhost, true # force use of apache_default_vhost_config
# set :apache_default_vhost_conf, "/etc/httpd/conf/default.conf"
# set :apache_conf, "/etc/httpd/conf/apps/#{application}.conf"
# set :apache_ctl, "/etc/init.d/httpd"
# set :apache_proxy_port, 8000
set :apache_proxy_servers, 4
# set :apache_proxy_address, "127.0.0.1"
# set :apache_ssl_enabled, false
# set :apache_ssl_ip, "127.0.0.1"
# set :apache_ssl_forward_all, false
# set :apache_ssl_chainfile, false


# =============================================================================
# MONGREL OPTIONS
# =============================================================================
# set :mongrel_servers, apache_proxy_servers
# set :mongrel_port, apache_proxy_port
set :mongrel_address, apache_proxy_address
# set :mongrel_environment, "production"
# set :mongrel_config, "/etc/mongrel_cluster/#{application}.conf"
# set :mongrel_user, user
# set :mongrel_group, group

# =============================================================================
# MYSQL OPTIONS
# =============================================================================


# =============================================================================
# SSH OPTIONS
# =============================================================================
# ssh_options[:keys] = %w(/path/to/my/key /path/to/another/key)
# ssh_options[:port] = 25
# ssh_option[:host] = '208.75.87.31'

task :update_code, :roles => [:app, :db, :web] do
  on_rollback { delete release_path, :recursive => true }

  # this directory will store our local copy of the code
  temp_dest = "to_deploy"
  
  # the name of our code tarball
  tgz = "to_deploy.tgz"

  # export the current code into the above directory
  system("svn export -q #{configuration.repository} #{temp_dest}")

  # create a tarball and send it to the server
  system("tar -C #{temp_dest} -czf #{tgz} .")
  put(File.read(tgz), tgz)

  # untar the code on the server
  run <<-CMD
  mkdir -p  #{release_path}             &&
  tar -C    #{release_path} -xzf #{tgz} 
  CMD

  # symlink the shared paths into our release directory
  run <<-CMD
    rm -rf #{release_path}/log #{release_path}/public/system    &&
    ln -nfs #{shared_path}/log #{release_path}/log              &&
    ln -nfs #{shared_path}/system #{release_path}/public/system
  CMD

  # clean up our archives
  run "rm -f #{tgz}"
  system("rm -rf #{temp_dest} #{tgz}")
end

task :after_update_code, :roles => :app do
  %w{candidate}.each do |share|
    run "rm -rf #{release_path}/public/#{share}"
    # run "mkdir -p #{shared_path}/system/#{share}"
    run "ln -nfs #{shared_path}/system/#{share} #{release_path}/public/#{share}"
  end
  run "chmod -R 775 #{release_path}/tmp"
end

desc <<DESC
Backup remote database from primary server.
DESC
task :remote_backup, :roles => :db, :only => { :primary => true } do
  filename = "dump.#{Time.now.strftime '%Y%m%dT%:%H%M%S'}.sql" 
  on_rollback { delete "/tmp/#{filename}" }
  run "mysqldump -uroot --password= query_viewer_production > \n
  #{shared_path}/system/#{filename}" do |channel, stream, data|
    puts data
  end
end