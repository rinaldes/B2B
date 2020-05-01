class RemoveColumnStateOnNotifications < ActiveRecord::Migration
  def up
  	remove_column :notifications, :state
  end

  def down
  end
end
