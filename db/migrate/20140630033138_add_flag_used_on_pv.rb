class AddFlagUsedOnPv < ActiveRecord::Migration
  def up
    add_column :payment_vouchers, :used, :boolean, :default=>false
  end

  def down
  	remove_column :payment_vouchers, :used
  end
end
