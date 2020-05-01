class AddTaxAmountOnPOs < ActiveRecord::Migration
  def up
  	add_column :purchase_orders, :tax_amount, :decimal, :precision=>10, :scale=>2
  end

  def down
    remove_column :purchase_orders, :tax_amount
  end
end
