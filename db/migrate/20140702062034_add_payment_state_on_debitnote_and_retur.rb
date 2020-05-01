class AddPaymentStateOnDebitnoteAndRetur < ActiveRecord::Migration
  def up
  	add_column :debit_notes, :payment_state, :integer
  	add_column :returned_processes, :payment_state, :integer
    add_column :payment_vouchers, :payment_state, :integer
    remove_column :payment_vouchers, :used
  end

  def down
  	remove_column :debit_notes, :payment_state
  	remove_column :returned_processes, :payment_state
  	remove_column :payment_vouchers, :payment_state
    add_column :payment_vouchers, :used, :boolean, :default=>false
  end
end
