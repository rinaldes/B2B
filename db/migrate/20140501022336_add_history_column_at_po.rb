class AddHistoryColumnAtPo < ActiveRecord::Migration
  def up
    add_column :purchase_orders, :is_history, :boolean, :default=>false
  end

  def down
    remove_column :purchase_orders, :is_history
  end
end
