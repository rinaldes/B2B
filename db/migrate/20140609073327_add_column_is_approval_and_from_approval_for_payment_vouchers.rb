class AddColumnIsApprovalAndFromApprovalForPaymentVouchers < ActiveRecord::Migration
  def change
    add_column :payment_vouchers, :is_approved, :boolean
    add_column :payment_vouchers, :from_approved, :string
    add_column :payment_voucher_details, :is_approved_detail, :boolean
  end
end
