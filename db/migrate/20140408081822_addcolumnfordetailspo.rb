class Addcolumnfordetailspo < ActiveRecord::Migration
  def up
  	add_column :details_purchase_orders, :delivery_date, :datetime
  	add_column :details_purchase_orders, :order_qty, :decimal
  	add_column :details_purchase_orders, :commited_qty, :decimal
  	add_column :details_purchase_orders, :received_qty, :decimal
  	add_column :details_purchase_orders, :dispute_qty, :decimal
  	add_column :details_purchase_orders, :reconciled_qty, :decimal
  	add_column :details_purchase_orders, :unit_price, :decimal
  	add_column :details_purchase_orders,:dispute_price, :decimal
  	add_column :details_purchase_orders, :reconciled_price, :decimal
  	add_column :details_purchase_orders, :total_amount_before_tax, :decimal
  	add_column :details_purchase_orders, :total_amount_after_tax, :decimal
  	add_column :details_purchase_orders, :service_level, :decimal
  end

  def down
  end
end
