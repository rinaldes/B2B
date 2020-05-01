class AddPaymentNoToPayments < ActiveRecord::Migration
  def up
    add_column :payments, :payment_no, :string
    add_column :payments, :payment_date, :date
  end
  def down
  	remove_column :payments, :payment_no
  	remove_column :payment_date
  end
end
