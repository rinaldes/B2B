class AddUserLevelToPurchaseOrder < ActiveRecord::Migration
  def up
  	add_column :purchase_orders, :user_level, :integer, :default => 1
  end

  def down
  	remove_column :purchase_orders, :user_level
  end
end
