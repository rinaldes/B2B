class AddTotalLineQtyToPo < ActiveRecord::Migration
  def up
  	rename_column :purchase_orders, :ordered_total, :total_qty
  	rename_column :purchase_orders, :line_qty, :total_line_qty
  end
  def down
  	rename_column :purchase_orders, :total_qty, :ordered_total
  	rename_column :purchase_orders, :total_line_qty, :line_qty
  end
end
