class AddGapToPurchaseOrder < ActiveRecord::Migration
  def change
    add_column :purchase_orders, :tax_gap, :decimal
    add_column :purchase_orders, :dpp_gap, :decimal
  end
end
