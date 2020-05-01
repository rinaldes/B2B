class AddColumnBrandForProduct < ActiveRecord::Migration
  def up
    add_column :products, :brand, :string
    add_column :products, :brand_description, :string
  end

  def down
    remove_column :products, :brand
    remove_column :products, :brand_description
  end
end
