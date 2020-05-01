class AddDueDateToReturnedProcess < ActiveRecord::Migration
  def change
    add_column :returned_processes, :due_date, :date
  end
end
