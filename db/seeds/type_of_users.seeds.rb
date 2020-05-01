after :companies do
  company = Company.first
  tou = TypeOfUser.all
  if tou.blank?
    supp = TypeOfUser.new(:description => "Supplier")
    customer = TypeOfUser.new(:description => "Customer")
    if supp.save
      child_supp = TypeOfUser.new(:description => "Supplier")
      child_supp.parent_id = supp.id
      child_supp.company_id = company.id
      child_supp.save
    end

    if customer.save
      child_customer = TypeOfUser.new(:description => "No Company, Please Check and Update this company.")
      child_customer.parent_id = customer.id
      child_customer.company_id = company.id
      child_customer.save
    end
  else
    if tou.count == 2
      tou.each do |t|
        if t.description == "Supplier"
          tou_new = TypeOfUser.new(:description => "Supplier")
          tou_new.parent_id = t.id
          tou_new.company_id = company.id
          tou_new.save
        else
          tou_new = TypeOfUser.new(:description => "No Company, Please Check and Update this company.")
          tou_new.parent_id = t.id
          tou_new.company_id = company.id
          tou_new.save
        end
      end
    end
  end
end