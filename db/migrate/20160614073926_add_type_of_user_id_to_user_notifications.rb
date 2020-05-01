class AddTypeOfUserIdToUserNotifications < ActiveRecord::Migration
  def change
    add_column :notifications, :type_of_user_id, :integer
  end
end
