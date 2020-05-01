class AddColumnSupplierLastBuyPriceForSupplierProducts < ActiveRecord::Migration
  def up
    add_column :suppliers_products, :last_buy_price, :decimal
    add_column :suppliers_products, :last_buy_date, :date
  end

  def down
    remove_column :suppliers_products, :last_buy_price
    remove_column :suppliers_products, :last_buy_date
  end
end
