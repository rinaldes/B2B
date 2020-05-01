class AddColumnIsCreatePaymentRequest < ActiveRecord::Migration
  def up
    add_column :purchase_orders, :is_create_payment_request, :boolean
  end

  def down
    remove_column :purchase_orders, :is_create_payment_request
  end
end
