class AddUserIdToPayment < ActiveRecord::Migration
  def up
  	add_column :payments, :user_id, :integer
  end

  def down
    remove_column :payments, :user_id
  end
end
