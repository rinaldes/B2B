after :type_of_users, :roles, :suppliers, :warehouses do
  user = User.first
  unless user
    superadmin = User.new
      superadmin.email = "admin@test.com"
      superadmin.username = "admin"
      superadmin.login = "admin"
      superadmin.first_name = "Superadmin"
      superadmin.last_name = "Pratesis"
      superadmin.is_activated = true
      superadmin.password = "deployWGS104"
      superadmin.type_of_user_id = TypeOfUser.where("parent_id = (SELECT id FROM type_of_users WHERE description = 'Customer')").first.try(:id)
      superadmin.password_confirmation = "deployWGS104"
      superadmin.user_type = "b2b"
      superadmin.add_role(:superadmin)
      if superadmin.save
        puts "Create user Superadmin: SUCCESSFULLY"
        puts "========================="
        puts "User Superadmin has been created."
        puts "- Email: admin@test.com"
        puts "- Username : admin"
        puts "- Password : deployWGS104"
      else
        puts "Create user Superadmin: FAILED"
        puts "========================="
      end
  else
    puts "do nothing"
  end
end