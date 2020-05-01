class AddOrderedTotalToPos < ActiveRecord::Migration
  def up
  	add_column :purchase_orders, :order_total, :decimal, :precision => 12 , :scale => 2
  end
  def down
  	remove_column :purchase_orders, :order_total
  end
end
