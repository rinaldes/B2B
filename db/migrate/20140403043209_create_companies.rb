class CreateCompanies < ActiveRecord::Migration
  def change
    create_table :companies do |t|
      t.string :name, :limit=>45
      t.string :email, :limit=>45
      t.timestamps
    end
  end
end
