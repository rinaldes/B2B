class CreateEmailNotifications < ActiveRecord::Migration
  def change
    create_table :email_notifications do |t|
      t.string :subject
      t.text :description
      t.references :warehouse

      t.timestamps
    end
    add_index :email_notifications, :warehouse_id
  end
end
