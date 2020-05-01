class RemoveIsSuffiixFromPurchaseOrders < ActiveRecord::Migration
  def change
  	if column_exists? :purchase_orders, :is_suffiix
  		remove_column :purchase_orders, :is_suffiix
  	end
  end
end
