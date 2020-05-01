class AddNewFieldToUser < ActiveRecord::Migration
  def change
  	add_column :users, :is_received_early_payment_request, :boolean, default: false
  	add_column :users, :is_received_debit_note, :boolean, default: false
  	add_column :users, :is_received_payment_voucher, :boolean, default: false
  end
end
