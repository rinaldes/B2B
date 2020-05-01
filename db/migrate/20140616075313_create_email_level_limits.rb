class CreateEmailLevelLimits < ActiveRecord::Migration
  def change
    create_table :email_level_limits do |t|
      t.string :subject
      t.text :description
      t.string :email_type
      t.references :warehouse

      t.timestamps
    end
    add_index :email_level_limits, :warehouse_id
  end
end
