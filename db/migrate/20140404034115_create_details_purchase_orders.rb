class CreateDetailsPurchaseOrders < ActiveRecord::Migration
  def change
  	 create_table :details_purchase_orders do |t|
      t.references :product
      t.references :purchase_order
      t.timestamps
    end
  end
end
