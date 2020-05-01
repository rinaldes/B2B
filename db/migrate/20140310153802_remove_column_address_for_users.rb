class RemoveColumnAddressForUsers < ActiveRecord::Migration
  def up
  	remove_column :users, :address
  end

  def down
  	add_column :users, :address, :text
  end
end
