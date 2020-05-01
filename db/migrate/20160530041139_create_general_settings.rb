class CreateGeneralSettings < ActiveRecord::Migration
  def change
    create_table :general_settings do |t|
      t.string :desc
      t.string :value

      t.timestamps
    end
  end
end
