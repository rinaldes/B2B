class AddUserLevelToDebitNote < ActiveRecord::Migration
  def up
  	add_column :debit_notes, :user_level, :integer, :default => 1
    add_column :returned_processes, :user_level, :integer, :default => 1
  end

  def down
  	remove_column :debit_notes, :user_level
    remove_column :returned_processes, :user_level
  end
end
