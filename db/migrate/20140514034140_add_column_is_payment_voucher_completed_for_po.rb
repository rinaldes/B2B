class AddColumnIsPaymentVoucherCompletedForPo < ActiveRecord::Migration
  def up
    add_column :purchase_orders, :is_payment_voucher_completed, :boolean, :default => false
  end

  def down
    remove_column :purchase_orders, :is_payment_voucher_completed
  end
end
