class ChangeValidUntilToDate < ActiveRecord::Migration
  def up
    change_column :notifications, :valid_until, :date
  end

  def down
  end
end
