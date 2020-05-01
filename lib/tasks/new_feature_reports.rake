desc "I'm create new feature reports"
namespace :new_feature_reports do
	task :create => :environment do
	  type_reports = ["Service Level Suppliers", "On Going Disputes", "Pending Deliveries", "Returned Histories"]
	  type_reports.each_with_index do |d, i|
	  	existed_feature = Feature.where(:name => "#{d}").first
	  	unless existed_feature.present?
	  		feature = Feature.new(:name=>"#{d}", :regulator => "Report", :key => "Reports/#{d.downcase.gsub(' ', "_")}")
	  		if feature.save
	  			puts "Feature #{d} was created"
	  		end
	  	end
	  end
  end
end