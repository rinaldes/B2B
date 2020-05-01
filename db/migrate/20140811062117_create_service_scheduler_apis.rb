class CreateServiceSchedulerApis < ActiveRecord::Migration
  def change
    create_table :service_scheduler_apis do |t|
    	t.integer :set_time
    	t.string :type_time
      t.timestamps
    end
  end
end
