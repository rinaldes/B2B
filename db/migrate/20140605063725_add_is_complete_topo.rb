class AddIsCompleteTopo < ActiveRecord::Migration
  def up
  	add_column :purchase_orders, :is_completed, :boolean, :default=> false
    add_column :purchase_orders, :supplier_desc, :string, :limit=>100
    add_column :purchase_orders, :warehouse_desc, :string, :limit=>100
    add_column :details_purchase_orders, :product_desc, :string, :limit=>100
    add_column :details_purchase_orders, :purchase_order_desc,:string, :limit=>100
    add_column :returned_processes, :purchase_order_desc, :string, :limit=>100
    add_column :returned_processes, :is_completed, :boolean, :default=>false
    add_column :companies, :npwp, :string, :limit=>100
    add_column :returned_process_details, :retur_desc, :string, :limit=>100
  end

  def down
  	remove_column :purchase_orders, :is_completed
    remove_column :purchase_orders, :supplier_desc
    remove_column :purchase_orders, :warehouse_desc
    remove_column :details_purchase_orders, :product_desc
    remove_column :details_purchase_orders, :purchase_orders_desc
    remove_column :returned_processes, :purchase_orders_desc
    remove_column :returned_processes, :is_completed
    remove_column :companies, :npwp
    remove_column :returned_process_details, :retur_desc
  end
end
