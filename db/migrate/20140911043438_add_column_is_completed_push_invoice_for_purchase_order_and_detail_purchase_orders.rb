class AddColumnIsCompletedPushInvoiceForPurchaseOrderAndDetailPurchaseOrders < ActiveRecord::Migration
  def up
    add_column :purchase_orders, :is_completed_invoice_to_api, :boolean, :default => false
    add_column :details_purchase_orders, :is_completed_invoice_to_api, :boolean, :default => false
  end

  def down
    remove_column :purchase_orders, :is_completed_invoice_to_api
    remove_column :details_purchase_orders, :is_completed_invoice_to_api
  end
end
