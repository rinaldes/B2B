class RemovColPoOnPurchaseorders < ActiveRecord::Migration
  def up
  	remove_column :purchase_orders, :po_id
  	remove_column :purchase_orders, :po_type
  end
  def down
  end
end
