class AddColumnPrintInvoiceDateInPo < ActiveRecord::Migration
  def up
    add_column :purchase_orders, :print_invoice_date, :datetime
  end

  def down
    remove_column :purchase_orders, :print_invoice_date
  end
end
