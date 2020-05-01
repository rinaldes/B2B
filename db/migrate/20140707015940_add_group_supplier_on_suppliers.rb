class AddGroupSupplierOnSuppliers < ActiveRecord::Migration
  def up
    add_column :suppliers, :group_id, :integer
  end

  def down
  	remove_column :suppliers, :group_id
  end
end
