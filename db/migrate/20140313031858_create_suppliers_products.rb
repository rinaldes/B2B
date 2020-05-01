class CreateSuppliersProducts < ActiveRecord::Migration
  def change
    create_table :suppliers_products do |t|
      t.references :supplier
      t.references :product
      t.timestamps
    end
  end
end
