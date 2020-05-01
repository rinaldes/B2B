class RemoveColumnIsApprovedDetailForPaymentVoucherDetail < ActiveRecord::Migration
  def up
    remove_column :payment_voucher_details, :is_approved_detail
  end

  def down
  end
end
