class AddStateOnPurchaseorders < ActiveRecord::Migration
  def up
    add_column :purchase_orders, :state, :integer
    remove_column :purchase_orders, :status
  end

  def down
  end
end
