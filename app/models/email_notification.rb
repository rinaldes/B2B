class EmailNotification < ActiveRecord::Base
  attr_accessible :description, :subject, :email_type
  attr_protected :warehouse_id

  validates_length_of :subject, :minimum => 5, :allow_blank => false
  validates_length_of :description, :minimum => 10,  :tokenizer => lambda { |str| ActionController::Base.helpers.strip_tags(str) }
end
