class ChangeLimitDecimalForPo < ActiveRecord::Migration
  def up
    change_column :purchase_orders, :received_total, :decimal, :precision => 20, :scale => 2
    change_column :purchase_orders, :charges_total, :decimal, :precision => 20, :scale => 2
    change_column :purchase_orders, :ordered_tax_amt, :decimal, :precision => 20, :scale => 2
    change_column :purchase_orders, :received_tax_amt, :decimal, :precision => 20, :scale => 2
    change_column :purchase_orders, :order_total, :decimal, :precision => 20, :scale => 2
  end

  def down
  end
end
