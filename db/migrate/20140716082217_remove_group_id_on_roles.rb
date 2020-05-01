class RemoveGroupIdOnRoles < ActiveRecord::Migration
  def up
    remove_column :roles, :group_id
    add_column :roles, :group_flag, :boolean, :default => false
  end

  def down
  	add_column :roles, :group_id, :integer
  	remove_column :roles, :group_flag
  end
end
