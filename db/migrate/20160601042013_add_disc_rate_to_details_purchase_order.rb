class AddDiscRateToDetailsPurchaseOrder < ActiveRecord::Migration
  def change
    add_column :details_purchase_orders, :disc_rate, :decimal
  end
end
