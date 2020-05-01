class ChangePoDateDataTypeToDate < ActiveRecord::Migration
  def up
    change_column :purchase_orders, :po_date, :date
  end

  def down
  	change_column :purchase_orders, :po_date, :time
  end
end
