class Area < ActiveRecord::Base
  attr_accessible :area_name, :area_code
  has_many :warehouses

  paginates_per 5
  max_paginates_per 100
end
