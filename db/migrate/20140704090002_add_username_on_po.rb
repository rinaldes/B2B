class AddUsernameOnPo < ActiveRecord::Migration
  def up
    add_column :purchase_orders, :user_name ,:string
  end

  def down
  	remove_column :purchase_orders, :user_name
  end
end
