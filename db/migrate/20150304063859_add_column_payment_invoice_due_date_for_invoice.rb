class AddColumnPaymentInvoiceDueDateForInvoice < ActiveRecord::Migration
  def up
  	add_column :purchase_orders, :payment_invoice_due_date, :date
  end

  def down
  	remove_column :purchase_orders, :payment_invoice_due_date
  end
end
