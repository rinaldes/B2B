class AddColumnSupplierIdForUsers < ActiveRecord::Migration
  def up
    add_column :users, :supplier_id, :integer
  end

  def down
    remove_column :users, :supplier_id, :integer
  end
end
