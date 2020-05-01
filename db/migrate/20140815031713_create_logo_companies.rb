class CreateLogoCompanies < ActiveRecord::Migration
  def change
    create_table :logo_companies do |t|
      t.string :logo

      t.timestamps
    end
  end
end
