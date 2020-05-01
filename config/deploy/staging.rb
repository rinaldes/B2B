set :domain, "resha@202.138.229.148"
role :web, domain
role :app, domain
role :db,  domain, :primary => true

set :deploy_to, "/home/resha/projects/b2b/"
set :branch, 'develop_b2b_phase_2'
set :rails_env, 'staging'

require "rvm/capistrano"
set :rvm_ruby_string, 'ruby-2.0.0-p576@pratesis-b2b'
set :rvm_type, :user