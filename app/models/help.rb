class Help < ActiveRecord::Base
  attr_accessible :attachment, :description, :page
  mount_uploader :attachment, HelpAttachmentUploader
end
