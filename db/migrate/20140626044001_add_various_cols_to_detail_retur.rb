class AddVariousColsToDetailRetur < ActiveRecord::Migration
  def up
  	add_column :returned_process_details, :item_price, :decimal,:precision=>10, :scale=>2
  	add_column :returned_process_details, :item_description, :string
  	add_column :returned_process_details, :seq, :integer
  end
  def down
  	remove_column :returned_process_details, :item_description
  	remove_column :returned_process_details, :item_price
  	remove_column :returned_process_details, :seq
  end
end
