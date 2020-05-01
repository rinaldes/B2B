class AddTypeToGeneralSetting < ActiveRecord::Migration
  def change
    add_column :general_settings, :input_type, :text
    add_column :general_settings, :value2, :text
  end
end
