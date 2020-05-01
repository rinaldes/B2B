class AddedOtherColumnForProducts < ActiveRecord::Migration
  def up
    add_column :products, :apn_number, :string
    add_column :products, :group_product_id, :integer
    add_column :products, :unit_description, :string
    add_column :products, :import_tarif, :string
    add_column :products, :convertion_factor, :decimal, :scale => 2, :precision => 10
    add_column :products, :pack_description, :string
    add_column :products, :pack_cubic_size, :decimal, :scale => 2, :precision => 10
    add_column :products, :pack_weight, :decimal, :scale => 2, :precision => 5

    change_column :purchase_orders, :received_total, :decimal, :scale => 2, :precision => 12
    change_column :purchase_orders, :charges_total, :decimal, :scale => 2, :precision => 12
    change_column :purchase_orders, :ordered_tax_amt, :decimal, :scale => 2, :precision => 12
    change_column :purchase_orders, :received_tax_amt, :decimal, :scale => 2, :precision => 12
  end

  def down
  end
end
