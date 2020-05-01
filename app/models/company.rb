class Company < ActiveRecord::Base
  has_many :addresses ,as: :location
  has_many :ldap_settings
  has_one :type_of_user
  attr_accessible :name, :email, :brand, :addresses_attributes, :code, :npwp, :asset_name, :brand_tmp

  mount_uploader :asset_name, AssetUploader

  accepts_nested_attributes_for :addresses, :allow_destroy => true, :reject_if => proc { |obj| obj.blank? }
  validates_associated :addresses
  validates :name, presence: {message: "Can't be blank", :allow_nil=>false, allow_blank: false}
  validates :brand, presence: {message: "Can't be blank", :allow_nil=>false, allow_blank: false}
  validates :npwp, presence: {message: "Can't be blank", allow_nil: false, :allow_blank=> false }


end
