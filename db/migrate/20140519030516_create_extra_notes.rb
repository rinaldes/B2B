class CreateExtraNotes < ActiveRecord::Migration
  def change
    create_table :extra_notes do |t|
      t.belongs_to :supplier
      t.string :type, limit:2
      t.decimal :seq_no, precision: 6, scale: 2
      t.string :text, limit: 40
      t.timestamps
    end
  end
end
