class AddSignedInUser < ActiveRecord::Migration
  def up
  	add_column :users, :signed, :integer, :limit => 1
  end

  def down
  	remove_column :users, :signed, :integer, :limit => 1
  end
end
