class AddNewfieldToEmailNotification < ActiveRecord::Migration
  def change
  	add_column :email_notifications, :type_po, :string
  	add_column :email_notifications, :state, :string
  end
end
