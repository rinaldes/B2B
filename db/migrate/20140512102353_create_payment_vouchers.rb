class CreatePaymentVouchers < ActiveRecord::Migration
  def change
    create_table :payment_vouchers do |t|
      t.string :voucher
      t.integer :supplier_id
      t.decimal :grand_total
      t.timestamps
    end
  end
end
