class AddColumnWarehouseIdForPaymentVouchers < ActiveRecord::Migration
  def up
    add_column :payment_vouchers, :warehouse_id, :integer
  end

  def down
    remove_column :payment_vouchers, :warehouse_id
  end
end
