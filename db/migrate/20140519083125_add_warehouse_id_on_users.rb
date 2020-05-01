class AddWarehouseIdOnUsers < ActiveRecord::Migration
  def up
  	add_column :users, :warehouse_id, :integer
  end

  def down
  	remove_column :users, :warehouse_id
  end
end
