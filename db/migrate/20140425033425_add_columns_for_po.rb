class AddColumnsForPo < ActiveRecord::Migration
  def up
  	add_column :purchase_orders, :received_date, :date
  end

  def down
    remove_column :purchase_orders, :received_date
  end
end
