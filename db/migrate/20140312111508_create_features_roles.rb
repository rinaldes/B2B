class CreateFeaturesRoles < ActiveRecord::Migration
  def change
    create_table :features_roles, :id => false  do |t|
      t.references :role
      t.references :feature	
    end
  end
end
