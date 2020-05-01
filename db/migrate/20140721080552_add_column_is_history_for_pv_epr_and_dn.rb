class AddColumnIsHistoryForPvEprAndDn < ActiveRecord::Migration
  def up
    add_column :debit_notes, :is_history, :boolean, :default => false
    add_column :payment_vouchers, :is_history, :boolean, :default => false
    add_column :early_payment_requests, :is_history, :boolean, :default => false
  end

  def down
    remove_column :debit_notes, :is_history
    remove_column :payment_vouchers, :is_history
    remove_column :early_payment_requests, :is_history
  end
end
