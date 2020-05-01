class CreatePaymentDetails < ActiveRecord::Migration
  def change
    create_table :payment_details do |t|
      t.integer :payment_id
      t.integer :debit_note_id
      t.integer :payment_voucher_id
      t.timestamps
    end
  end
end
