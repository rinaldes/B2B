class RenameColumnCommittedQty < ActiveRecord::Migration
  def up
    rename_column :returned_process_details, :committed_qty, :received_qty
  end

  def down
    rename_column :returned_process_details, :received_qty, :committed_qty
  end
end
