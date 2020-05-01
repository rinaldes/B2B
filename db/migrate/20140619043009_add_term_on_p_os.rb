class AddTermOnPOs < ActiveRecord::Migration
  def up
  	add_column :purchase_orders, :term, :string, :limit=>255
  	add_column :purchase_orders, :currency_code, :string, :limit=>255
  	add_column :purchase_orders, :initial_currency_rate, :integer, :limit=>5
  end

  def down
  	remove_column :purchase_orders, :term
    remove_column :purchase_orders, :currency_code
    remove_column :purchase_orders, :initial_currency_rate
  end
end
