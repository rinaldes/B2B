class AddBgImageColumnToGeneralSettings < ActiveRecord::Migration
  def change
    add_column :general_settings, :background_image, :string
  end
end
