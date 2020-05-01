class AddColumnUpdatedLastDateAndUpdatedLastTimeForPurchaseOrderAndReturnProcess < ActiveRecord::Migration
  def up
    add_column :purchase_orders, :updated_date, :date
    add_column :purchase_orders, :updated_time, :datetime
    add_column :returned_processes, :updated_date, :date
    add_column :returned_processes, :updated_time, :datetime
  end

  def down
    remove_column :purchase_orders, :updated_date
    remove_column :purchase_orders, :updated_time
    remove_column :returned_processes, :updated_date
    remove_column :returned_processes, :updated_time
  end
end
