class CreatePaymentVoucherDetails < ActiveRecord::Migration
  def change
    create_table :payment_voucher_details do |t|
      t.integer :payment_voucher_id
      t.integer :purchase_order_id
      t.timestamps
    end
  end
end
