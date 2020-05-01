class ImageBlast < ActiveRecord::Base
  attr_accessible :description, :front_img, :title, :valid_until, :valid_from
  mount_uploader :front_img, IblastUploader
end
