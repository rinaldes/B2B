class ServiceSchedulerApi < ActiveRecord::Base
   attr_accessible :set_time, :type_time

   validates :set_time, presence: true
   validates :type_time, presence: true
end
