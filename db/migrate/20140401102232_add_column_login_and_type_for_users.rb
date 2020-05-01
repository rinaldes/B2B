class AddColumnLoginAndTypeForUsers < ActiveRecord::Migration
  def up
    unless column_exists? :users, :login
      add_column :users, :login, :string
    end
    unless column_exists? :users, :user_type
      add_column :users, :user_type, :string
    end
  end

  def down
    remove_column :users, :login
    remove_column :users, :user_type
  end
end
