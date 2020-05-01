class AddSupplierIdToNotifications < ActiveRecord::Migration
  def up
    add_column :notifications, :supplier_id, :integer
  end
  def down
  	remove_column :notifications, :supplier_id
  end
end
