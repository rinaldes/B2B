class AddColumnCustomerIdAndUserIdOnPurchaseorders < ActiveRecord::Migration
  def up
  	add_column :purchase_orders, :customer_id, :integer
  	add_column :purchase_orders, :user_id, :integer
  end

  def down
  end
end
