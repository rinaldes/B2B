class ChangePaymentNoToNoOnPayments < ActiveRecord::Migration
  def up
    rename_column :payments, :payment_no, :no
  end

  def down
    rename_column :payments, :no, :payment_no
  end
end
