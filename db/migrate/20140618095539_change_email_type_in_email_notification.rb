class ChangeEmailTypeInEmailNotification < ActiveRecord::Migration
  def change
  	remove_column :email_notifications, :email_type
  	add_column :email_notifications, :email_type, :integer
  end
end
