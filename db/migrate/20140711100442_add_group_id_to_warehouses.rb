class AddGroupIdToWarehouses < ActiveRecord::Migration
  def up
    add_column :warehouses, :group_id, :integer
  end
  def down
  	remove_column :warehouses, :group_id
  end
end
