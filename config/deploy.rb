require 'capistrano/ext/multistage'

set :application, "pratesis-b2b-system"
set :stages, %w(staging production vmware)
set :default_stage, 'staging'
set :use_sudo, false
set :scm, :git
set :scm_verbose, true
set :keep_releases, 5
set :repository, "ssh://git@gitlab.kiranatama.net:222/pratesis/b2b.git"
set :deploy_via, :remote_cache
set :normalize_asset_timestamps, false

load 'config/deploy/cap_notify.rb'
set :notify_emails, ["resha.j.p@kiranatama.com", "leonardo.s@kiranatama.com", "rita.j@kiranatama.com"]

namespace :deploy do
  desc "Send email notification"
  task :send_notification do
    Notifier.deploy_notification(self).deliver
  end

  desc "Run precompile assets"
  task :precompile do
    run "cd #{current_path} && bundle exec rake assets:precompile RAILS_ENV=#{self.stage} --trace"
  end

  desc "Create symlinks database.yml "
  task :link_db do
    db_config = "#{shared_path}/config/database.yml"
    run "rm -rf #{current_path}/config/database.yml"
    run "ln -nsf #{db_config} #{current_path}/config/database.yml"
  end

  desc "Run pending migrations on already deployed code"
  task :migrate do
    run "cd #{current_path}; RAILS_ENV=#{self.stage} bundle exec rake db:migrate --trace"
  end

  desc "Run bundle install and ensure all gem requirements are met"
  task :bundle do
    run "cd #{current_path} && bundle install  --without=test development"
  end

  desc "drop, create, migrate, seed master data"
  task :reset do
    run "cd #{current_path}; rake db:drop db:create db:migrate db:seed RAILS_ENV=#{self.stage}"
  end

  desc "Update the crontab file"
  task :update_crontab, :roles => :db do
    run "cd #{current_path} && RAILS_ENV=#{self.stage} whenever --update-crontab #{self.application} --set environment=#{self.stage}"
  end

  desc "Removed cache tmp"
  task :rm_cache do
    run "rm -rf #{current_path}/tmp/cache/*"
  end
end

after "deploy", "deploy:link_db"
before "deploy:restart", "deploy:bundle"
after "deploy", "deploy:migrate"
# after "deploy", "deploy:precompile"
after "deploy", "deploy:cleanup"

# Start and stop server staging and vmware
namespace :rails do
  desc 'stop think rails server'
  task :stop do
    run "kill -9 $(cat #{current_path}/tmp/pids/thin.pid)"
  end
  desc 'start think rails server'
  task :start do
    run "cd #{current_path} && thin -p 3073 -e #{self.stage} -d start"
  end
  desc 'restart think rails server'
  task :restart do
    run "cd #{current_path} && kill -9 $(cat tmp/pids/thin.pid) && thin -p 3073 -e #{self.stage} -d start "
  end
end

# Symlinks
after  'deploy', 'symlinks:uploads', "deploy:update_crontab"
namespace :symlinks do
  desc "Create sysmlinks for public/uploads directory"
  task :uploads do
    uploads = "#{shared_path}/public/uploads"
    run "rm -rf #{current_path}/public/uploads"
    run "ln -nsf #{uploads} #{current_path}/public/uploads"
  end
end

# Delayed_job
namespace :delayed_job do
  desc "Restart the delayed_job process"
  task :restart, :roles => :app do
    run "cd #{current_path}; RAILS_ENV=#{rails_env} script/delayed_job restart"
  end

  desc "Stop the delayed_job process"
  task :stop, :roles => :app do
    run "cd #{current_path}; RAILS_ENV=#{rails_env} script/delayed_job stop"
  end

  desc "Start the delayed_job process"
  task :start, :roles => :app do
    run "cd #{current_path}; RAILS_ENV=#{rails_env} script/delayed_job start"
  end
end

after "deploy:link_db", "delayed_job:restart"