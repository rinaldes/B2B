class ExpandPrecisionOnSuppliersSlsColumns < ActiveRecord::Migration
  def up
  	change_column :suppliers, :sl_line_total, :decimal, :precision=>4, :scale=>2
    change_column :suppliers, :sl_order_total, :decimal, :precision=>4, :scale=>2
    change_column :suppliers, :sl_time_total, :decimal, :precision=>4, :scale=>2
  end

  def down
  	change_column :suppliers, :sl_line_total, :decimal, :precision=>2, :scale=>2
    change_column :suppliers, :sl_order_total, :decimal, :precision=>2, :scale=>2
    change_column :suppliers, :sl_time_total, :decimal, :precision=>2, :scale=>2
  end
end
