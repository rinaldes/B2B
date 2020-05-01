class AddColumnBackorderFlagForPo < ActiveRecord::Migration
  def up
    add_column :purchase_orders, :backorder_flag, :string
  end

  def down
    remove_column :purchase_orders, :backorder_flag
  end
end
