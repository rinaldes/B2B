class AddLastPurchaseToSupp < ActiveRecord::Migration
  def change
    add_column :suppliers, :last_purchase, :date
    add_column :suppliers, :last_payment, :date
    add_column :suppliers, :account_opened, :date
  end
end
