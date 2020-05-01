class UserLevelDispute < ActiveRecord::Base
  attr_accessible :user_id, :level, :dispute_setting_id, :supplier_id
  
  belongs_to :supplier
  belongs_to :user
  belongs_to :dispute_setting
end
