class AddSupplierIdToUserLevelDisputes < ActiveRecord::Migration
  def change
    add_column :user_level_disputes, :supplier_id, :integer
  end
end
