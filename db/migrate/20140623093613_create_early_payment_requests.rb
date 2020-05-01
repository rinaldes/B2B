class CreateEarlyPaymentRequests < ActiveRecord::Migration
  def change
    create_table :early_payment_requests do |t|
      t.integer :purchase_order_id
      t.integer :state
      t.timestamps
    end
  end
end
