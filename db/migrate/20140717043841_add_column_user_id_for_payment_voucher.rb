class AddColumnUserIdForPaymentVoucher < ActiveRecord::Migration
  def up
    add_column :payment_vouchers, :user_id, :integer
  end

  def down
    remove_column :payment_vouchers, :user_id
  end
end
