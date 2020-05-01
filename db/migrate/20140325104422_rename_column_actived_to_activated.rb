class RenameColumnActivedToActivated < ActiveRecord::Migration
  def up
  	rename_column :users, :is_actived, :is_activated
  end

  def down
  end
end
