class EmailLevelLimit < ActiveRecord::Base
  belongs_to :warehouse
  attr_accessible :description, :subject, :email_type

  validates_length_of :subject, :minimum => 5, :allow_blank => true
  validates_length_of :description, :minimum => 10, :allow_blank => true,  :tokenizer => lambda { |str| ActionController::Base.helpers.strip_tags(str) }
end
