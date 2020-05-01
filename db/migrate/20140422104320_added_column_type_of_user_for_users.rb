class AddedColumnTypeOfUserForUsers < ActiveRecord::Migration
  def up
    add_column :users, :type_of_user_id, :integer
  end

  def down
    remove_column :users, :type_of_user_id
  end
end
