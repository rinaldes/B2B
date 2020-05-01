class AddedColumnIsDisputedForDetailsPurchaseOrders < ActiveRecord::Migration
  def up
  	add_column :details_purchase_orders, :is_disputed, :boolean, :default => false
  end

  def down
  	remove_column :details_purchase_orders, :is_disputed
  end
end
