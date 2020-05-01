class AddedDetailUserFieldForUsers < ActiveRecord::Migration
  def up
  	add_column :users, :first_name, :string
  	add_column :users, :last_name, :string
  	add_column :users, :has_signed_in, :boolean, :default => false
  	add_column :users, :is_actived, :boolean, :default => true
  end

  def down
  	remove_column :users, :first_name
  	remove_column :users, :last_name
  	remove_column :users, :has_signed_in
  	remove_column :users, :is_actived
  end
end
