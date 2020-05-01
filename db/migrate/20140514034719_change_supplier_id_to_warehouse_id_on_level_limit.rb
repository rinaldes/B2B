class ChangeSupplierIdToWarehouseIdOnLevelLimit < ActiveRecord::Migration
  def up
  	add_column :level_limits, :warehouse_id, :integer
  	remove_column :level_limits, :supplier_id
  end

  def down
  end
end
