class AddDueDateToPaymentVouchers < ActiveRecord::Migration
  def change
    add_column :payment_vouchers, :invoice_due_date, :date
  end
end
