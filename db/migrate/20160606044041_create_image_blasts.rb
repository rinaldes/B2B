class CreateImageBlasts < ActiveRecord::Migration
  def change
    create_table :image_blasts do |t|
      t.string :front_img
      t.string :title
      t.text :description
      t.date :valid_until

      t.timestamps
    end
  end
end
