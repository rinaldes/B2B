if Rails.env.staging? or Rails.env.production? || Rails.env.vmware?
  CarrierWave.configure do |config|
    config.permissions = 0666
    config.directory_permissions = 0777
    config.storage = :file
    config.store_dir = "#{Rails.root}/public/uploads/logo/"
  end
else
  CarrierWave.configure do |config|
    config.storage = :file
    config.store_dir = "#{Rails.root}/public/company/logo/"
  end
end