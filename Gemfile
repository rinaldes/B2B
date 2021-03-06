source 'http://rubygems.org'

gem 'rails', '3.2.21'
gem 'json', '1.8.3'
gem 'jquery-rails', '3.0.4'
gem "kaminari", '0.14.1'

#Authentication user
gem 'devise', '3.0.2'
gem 'cancan'
gem 'rolify'
gem "devise_ldap_authenticatable" #, :git => "git://github.com/cschiewek/devise_ldap_authenticatable.git"
gem 'devise_security_extension'

#generate barcode
gem 'barby'
gem 'chunky_png'
#state machine
gem 'state_machine'
#logger
gem 'public_activity'

gem 'wkhtmltopdf-binary'
gem 'wicked_pdf'

gem 'carrierwave', '0.9.0'
gem 'rmagick', '2.13.2', :require => 'RMagick'
gem 'mini_magick'

gem "seedbank", '0.3.0.pre'

gem "crummy", "~> 1.8.0"
gem "remotipart", "~> 1.2.1"
gem 'exception_notification', '4.0.0', :group => [:production, :staging, :vmware]
gem 'spreadsheet', '0.9.5'
gem 'verbs'

gem 'rails_config', '~> 0.4.2'
gem 'thin', '1.5.1'

gem 'pg'
gem 'breadcrumbs_on_rails', '~>2.2.0'

#Cronjob
gem 'delayed_job_active_record'
gem 'whenever', :require => false

group :assets do
  gem 'sass-rails',   '~> 3.2.3'
  gem 'coffee-rails', '~> 3.2.1'
  gem 'therubyracer'
  gem 'uglifier', '>= 1.0.3'
end

group :development do
  gem 'capistrano','2.13.5', :require => false
  gem 'capistrano-ext','1.2.1'
  gem 'rvm-capistrano','1.2.7'
  gem "brakeman"
  gem "rails_best_practices"
  gem "byebug"
  gem "mailcatcher"
  gem 'rspec-rails', '~> 2.14.1'
  gem 'factory_girl_rails'
end

group :test do
  gem 'faker'
  gem 'capybara'
  gem 'guard-rspec'
  gem 'launchy'
end

gem 'newrelic_rpm'