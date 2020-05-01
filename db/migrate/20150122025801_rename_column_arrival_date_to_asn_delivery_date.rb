class RenameColumnArrivalDateToAsnDeliveryDate < ActiveRecord::Migration
  def up
  	rename_column :purchase_orders, :arrival_date, :asn_delivery_date
  end

  def down
  	rename_column :purchase_orders, :asn_delivery_date, :arrival_date
  end
end
