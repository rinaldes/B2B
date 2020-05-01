class AddColumnBackorderFlagForDetailPo < ActiveRecord::Migration
  def up
    add_column :details_purchase_orders, :backorder_flag, :string
  end

  def down
    remove_column :details_purchase_orders, :backorder_flag
  end
end
