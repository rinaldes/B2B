class GeneralSetting < ActiveRecord::Base
  attr_accessible :desc, :value, :value2, :input_type, :background_image
  mount_uploader :background_image, BackgroundImageUploader
end
