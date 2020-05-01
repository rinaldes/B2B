module Setting::ServiceSchedulerApisHelper
	def display_time_type(time)
		val = {'H' => 'Hours', 'M' => 'Minutes'}
		type = val[time]
		return type
	end
end
