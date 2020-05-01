class AddColumnRemarkForDetailsPo < ActiveRecord::Migration
  def up
  	add_column :details_purchase_orders, :remark, :text
  end

  def down
  	remove_column :details_purchase_orders, :remark
  end
end
