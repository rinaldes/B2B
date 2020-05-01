class AddEmailTypeToEmailNotification < ActiveRecord::Migration
  def change
    add_column :email_notifications, :email_type, :string
  end
end
