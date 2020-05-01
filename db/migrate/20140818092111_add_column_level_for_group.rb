class AddColumnLevelForGroup < ActiveRecord::Migration
  def up
    add_column :groups, :level, :integer
  end

  def down
    remove_column :groups, :level
  end
end
