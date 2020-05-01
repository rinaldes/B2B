class AddReturnFlagOnPoDetail < ActiveRecord::Migration
  def up
  	add_column :details_purchase_orders, :return_flag, :boolean, :default=>false
  	add_column :details_purchase_orders, :return_qty, :integer
  end

  def down
  	remove_column :details_purchase_orders, :return_qty
  	remove_column :details_purchase_orders, :return_flag
  end
end
