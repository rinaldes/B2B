class AddWareHouseIdToPurchaseOrder < ActiveRecord::Migration
  def change
    add_column :purchase_orders, :warehouse_id, :integer
  end
end
