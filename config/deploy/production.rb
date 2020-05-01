set :domain, "b2b-apps@10.10.11.4"
role :web, domain                     # Your HTTP server, Apache/etc
role :app, domain                          # This may be the same as your `Web` server
role :db,  domain, :primary => true # This is where Rails migrations will run

set :deploy_to, "/home/b2b-apps/pratesis-b2b-system/"
set :branch, 'develop_reporting_lv1'
set :rails_env, 'production'

require "rvm/capistrano"
set :rvm_ruby_string, 'ruby-2.0.0-p481@pratesis-b2b-system'
set :rvm_type, :user
set :whenever_environment, 'production'

# If you are using Passenger mod_rails uncomment this:
 namespace :deploy do
   task :start do ; end
   task :stop do ; end
   task :restart, :roles => :app, :except => { :no_release => true } do
     run "#{try_sudo} touch #{release_path}/tmp/restart.txt"
   end
   task :create_db do
      run "cd #{release_path} && rake db:create RAILS_ENV=production"
   end

   task :migrate_with_bundle do
     run "cd #{release_path} && rake db:migrate RAILS_ENV=production"
   end

   task :bundle_install do
     run "cd #{release_path} && bundle install"
   end
 end

after "deploy", "deploy:bundle_install"
after "deploy", "deploy:migrate_with_bundle"

