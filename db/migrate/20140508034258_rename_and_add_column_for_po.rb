class RenameAndAddColumnForPo < ActiveRecord::Migration
  def up
    rename_column :purchase_orders, :grand_total, :ordered_total
    add_column :purchase_orders, :received_total, :decimal, :scale => 2,:precision=>2
    add_column :purchase_orders, :line_qty, :integer
    rename_column :purchase_orders, :planned_arrival, :arrival_date
    add_column :purchase_orders, :charges_total, :decimal, :scale=>2,:precision=>2
    add_column :purchase_orders, :ordered_tax_amt, :decimal, :scale=>2,:precision=>2
    add_column :purchase_orders, :received_tax_amt, :decimal, :scale=>2,:precision=>2
    add_column :purchase_orders, :invoice_date, :date
    add_column :purchase_orders, :invoice_due_date, :date
    add_column :purchase_orders, :pay_by_date, :date
  end
  def down
  	rename_column :purchase_orders, :ordered_total, :grand_total
  	remove_column :purchase_orders, :received_total
  	remove_column :purchase_orders, :po_line_qty
  	rename_column :purchase_orders , :arrival_date, :planned_arrival
  	remove_column :purchase_orders, :charges_total
  	remove_column :purchase_orders, :ordered_tax_amt
  	remove_column :purchase_orders, :received_tax_amt
  	remove_column :purchase_orders, :invoice_date
  	remove_column :purchase_orders, :invoice_due_date
  	remove_column :purchase_orders, :pay_by_date
  end
end
