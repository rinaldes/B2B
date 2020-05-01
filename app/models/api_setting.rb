class ApiSetting < ActiveRecord::Base
  attr_accessible :api, :password

  validates :api, :presence => {:message => "API URL can't be Empty", :allow_blank => false}
  validates :password, :presence => {:message => "API Password can't be Empty", :allow_blank => false}

  def self.finds(type)
  	if type == 'api'
  		setting = ApiSetting.first.api
  	else
  		setting = ApiSetting.first.password
  	end

  	return setting
  end
end
