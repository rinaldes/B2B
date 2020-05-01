class RemoveCustomerIdFromPurchaseOrder < ActiveRecord::Migration
  def up
      	remove_column :purchase_orders, :customer_id
  end

  def down
  end
end
