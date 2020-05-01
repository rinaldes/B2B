class AddInvStateForPo < ActiveRecord::Migration
  def up
  	add_column :purchase_orders, :inv_state, :integer
  end

  def down
  	remove_column :purchase_orders, :inv_state
  end
end
