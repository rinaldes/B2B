class AddServiceLevelsColumnsForSuppliers < ActiveRecord::Migration
  def up
  	add_column :suppliers, :sl_line_total, :decimal, :precision=>2, :scale=>2
    add_column :suppliers, :sl_order_total, :decimal, :precision=>2, :scale=>2
    add_column :suppliers, :sl_time_total, :decimal, :precision=>2, :scale=>2
  end

  def down
  	remove_column :suppliers, :sl_time_total
  	remove_column :suppliers, :sl_order_total
  	remove_column :suppliers, :sl_line_total
  end
end
