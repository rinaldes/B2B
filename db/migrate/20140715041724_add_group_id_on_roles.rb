class AddGroupIdOnRoles < ActiveRecord::Migration
  def up
    add_column :roles, :group_id, :integer
  end

  def down
  	remove_column :roles, :group_id, :integer
  end
end
