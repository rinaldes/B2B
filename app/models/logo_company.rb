class LogoCompany < ActiveRecord::Base
  attr_accessible :logo

  mount_uploader :logo, LogoUploader

  after_save :remove_previously_stored_logo
end
