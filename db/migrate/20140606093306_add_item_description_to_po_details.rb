class AddItemDescriptionToPoDetails < ActiveRecord::Migration
  def up
  	add_column :details_purchase_orders, :item_description, :string, :limit=>45
  end
  def down
  	remove_column :details_purchase_orders, :item_description
  end
end
