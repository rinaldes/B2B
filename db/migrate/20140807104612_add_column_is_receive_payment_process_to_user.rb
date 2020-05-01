class AddColumnIsReceivePaymentProcessToUser < ActiveRecord::Migration
  def change
    add_column :users, :is_received_payment_process, :boolean, default: false
  end
end
