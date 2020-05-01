class AddedColumnAddressForUsers < ActiveRecord::Migration
  def up
  	add_column :users, :address, :text
  end

  def down
  	remove_column :users, :address
  end
end
