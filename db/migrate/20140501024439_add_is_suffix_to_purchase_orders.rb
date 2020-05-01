class AddIsSuffixToPurchaseOrders < ActiveRecord::Migration
  def change
    add_column :purchase_orders, :is_suffix, :boolean, default: false
  end
end
