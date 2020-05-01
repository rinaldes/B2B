class RemoveWarehouseIdFromEmailNotification < ActiveRecord::Migration
  def up
  	remove_column :email_notifications, :warehouse_id
  end

  def down
  end
end
