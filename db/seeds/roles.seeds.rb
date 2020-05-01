role = Role.first
if role.blank?
  #superadmin role
  customer_roles = Role.create([
    {:name => "superadmin"},
    {:name => "default_user"}])
  #create roles for customer group
  customer_group = Role.create(:name => "customer")
  customer_roles = customer_group.roles.create([
    {:name => "Management"},
    {:name => "Commercial Customer"},
    {:name => "Logistic"},
    {:name => "Finance Customer"},
    {:name => "Store ALC"},
    {:name => "customer_admin_group"}
  ])
  admin_grp_role_customer = Role.find_by_name("customer_admin_group")
  admin_grp_role_customer.group_flag = true
  admin_grp_role_customer.save
  if customer_roles
    puts "Customer roles has been created"
  else
    puts "An error has ocurred when saving customer roles"
  end
  #create roles for supplier group
  supplier_group = Role.create(:name => "supplier")
  supplier_roles = supplier_group.roles.create([
    {:name => "Management"},
    {:name => "Commercial Supplier"},
    {:name => "Logistic"},
    {:name => "Finance Supplier"},
    {:name => "supplier_admin_group"}
  ])
  admin_grp_role_supplier = Role.find_by_name("supplier_admin_group")
  admin_grp_role_supplier.group_flag = true
  admin_grp_role_supplier.save
  if supplier_roles
    puts "Supplier roles has been created"
  else
    puts "An error has ocurred when saving supplier roles"
  end
end
