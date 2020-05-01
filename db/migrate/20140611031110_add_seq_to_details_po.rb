class AddSeqToDetailsPo < ActiveRecord::Migration
  def up
  	add_column :details_purchase_orders, :seq, :integer
  	add_column :details_purchase_orders, :line_tax, :integer, :limit=>3
  end
  def down
  	remove_column :details_purchase_orders, :seq
  	remove_column :details_purchase_orders, :line_tax
  end
end
