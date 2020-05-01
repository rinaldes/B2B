# spec/factories/contacts.rb 
require 'faker'

FactoryGirl.define do 
  factory :user do |f| 
  	f.first_name "John" 
  	f.last_name "Doe" 
  end 
end 