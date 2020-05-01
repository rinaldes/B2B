class AddItemPriceOnDetailsPo < ActiveRecord::Migration
  def up
  	add_column :details_purchase_orders, :item_price, :decimal, :precision=>10, :scale=>2
  end

  def down
  	remove_column :details_purchase_orders, :item_price
  end
end
