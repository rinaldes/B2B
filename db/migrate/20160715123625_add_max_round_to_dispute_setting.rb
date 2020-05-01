class AddMaxRoundToDisputeSetting < ActiveRecord::Migration
  def change
    add_column :dispute_settings, :max_round, :integer
  end
end
