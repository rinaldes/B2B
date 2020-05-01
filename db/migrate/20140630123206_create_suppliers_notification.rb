class CreateSuppliersNotification < ActiveRecord::Migration
  def change
    create_table :suppliers_notifications do |t|
      t.integer :state, default: 0
      t.references :supplier
      t.references :notification

      t.timestamps
    end
    add_index :suppliers_notifications, :supplier_id
    add_index :suppliers_notifications, :notification_id
  end
end
