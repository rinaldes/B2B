if Rails.env.development? || Rails.env.staging? || Rails.env.production? || Rails.env.vmware?
  company = Company.first
  if company.blank?
    company = Company.new(:name => "PT. Customer Indonesia",
                             :brand => "Customer", :npwp=>"008090807090870876", :brand_tmp => "Customer")
    if company.save
      puts "successfully create company"
    else
      puts "Failed create company"
    end
  end
end