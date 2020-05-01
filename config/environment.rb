# Load the rails application
require File.expand_path('../application', __FILE__)

# Initialize the rails application
B2bSystem::Application.initialize!

ActionView::Base.field_error_proc = Proc.new do |html_tag, instance_tag|
  "<span class=\" control-group error\">#{html_tag}</span>".html_safe
end

DELAY_LEVEL_LIMIT = 1.minutes.from_now
DELAY_NOTIF = 1.minutes.from_now
API_LIMIT = 100
