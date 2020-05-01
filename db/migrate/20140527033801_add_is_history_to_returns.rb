class AddIsHistoryToReturns < ActiveRecord::Migration
  def up
  	add_column :returned_processes, :is_history, :integer, :default=>0, :limit=>1
    add_column  :returned_processes, :remark, :text
  end
  def down
    remove_column :returned_processes, :is_history
    remove_column :returned_processes, :remark	
  end
end
