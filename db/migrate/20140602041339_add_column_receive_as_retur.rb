class AddColumnReceiveAsRetur < ActiveRecord::Migration
  def up
  	add_column :returned_process_details, :price_after_retur, :decimal,:precision=>6, :scale=>2, :default=>0
  	add_column :returned_process_details, :received_as_retur_qty, :decimal, :precision=>6, :scale=>2, :default=>0
    change_column :returned_process_details, :received_qty, :decimal, :precision=>6,:scale=>2, :default=>0
  end

  def down
    remove_column :returned_process_details, :price_after_retur
    remove_column :returned_process_details, :received_as_retur_qty
  end
end
