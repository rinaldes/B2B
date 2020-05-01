class AddPrintCountOnPo < ActiveRecord::Migration
  def up
  	add_column :purchase_orders, :inv_print_count, :integer, :default=>0
  end

  def down
  	remove_column :purchase_orders, :inv_print_count
  end
end
