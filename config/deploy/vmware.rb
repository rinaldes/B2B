set :domain, "pratesis@172.16.121.128"
role :web, domain                     # Your HTTP server, Apache/etc
role :app, domain                          # This may be the same as your `Web` server
role :db,  domain, :primary => true # This is where Rails migrations will run

set :deploy_to, "/home/pratesis/pratesis-b2b-system/"

set :branch, 'develop_b2b_phase_2'
set :rails_env, 'vmware'

require "rvm/capistrano"
set :rvm_ruby_string, 'ruby-2.0.0-p481@pratesis-b2b-system'
set :rvm_type, :user
set :whenever_environment, 'vmware'