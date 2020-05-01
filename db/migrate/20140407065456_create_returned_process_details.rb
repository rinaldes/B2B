class CreateReturnedProcessDetails < ActiveRecord::Migration
  def change
    create_table :returned_process_details do |t|
      t.decimal :committed_qty
      t.decimal :return_qty
      t.integer :product_id
      t.integer :returned_process_id
      t.text :remark
      t.timestamps
    end
  end
end
