class AddColumnAreaIdForWarehouses < ActiveRecord::Migration
  def up
    add_column :warehouses, :area_id, :integer
  end

  def down
    remove_column :warehouses, :area_id
  end
end
