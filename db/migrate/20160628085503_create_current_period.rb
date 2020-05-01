class CreateCurrentPeriod < ActiveRecord::Migration
  def change
    create_table :current_periods do |t|
      t.integer :gl_period
      t.integer :gl_year
      t.integer :dl_period
      t.integer :dl_year
      t.integer :cl_period
      t.integer :cl_year
      t.boolean :active

      t.timestamps
    end
  end
end
