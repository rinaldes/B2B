class CreateServiceLevelHistories < ActiveRecord::Migration
  def change
    create_table :service_level_histories do |t|
      t.integer :purchase_order_id
      t.integer :supplier_id
      t.string :type, :limit=>50
      t.timestamps
    end
  end
end
