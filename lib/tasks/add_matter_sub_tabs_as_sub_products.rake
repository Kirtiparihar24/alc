namespace :add_sub_products do
  matter_subtabs = ['Terms of Engagement','People & Legal Team','Activities','Issues','Facts','Risks','Researches','Documents','Billing & Retainer', 'Time and Expense']
  

  desc "Add matter Subtabs as subproducts and add subtab data to subproduct assignment for all the users"
  task :add_matter_sub_tabs => :environment do
    matter = Subproduct.find_by_name("Matters")
    Subproduct.transaction do
      matter_subtabs.each do |matter_subtab|
        subproduct = Subproduct.find_or_create_by_name(:name => matter_subtab,:parent_id => matter.id)
        if subproduct.created_at >= Date.today
          subproduct_assignments = SubproductAssignment.find_all_by_subproduct_id(matter.id)
          SubproductAssignment.transaction do
            subproduct_assignments.each do |sub|
              SubproductAssignment.create(:user_id=>sub.user_id,:subproduct_id => subproduct.id,:product_licence_id =>sub.product_licence_id,:company_id => sub.company_id, :employee_user_id => sub.employee_user_id)
            end
          end
        end
      end
    end
  end

  desc "Delete matter subproducts,delete subtab data from subproduct assignment, and delete subdata from product subproduct for all the users"
  task :revert_added_matter_sub_tabs => :environment do
    matter_subtabs.each do |matter_subtab|
      subproduct = Subproduct.find_by_name(matter_subtab)
      subproduct_assignments = SubproductAssignment.find_all_by_subproduct_id(subproduct.id)
      subproduct_assignments.each do |sub|
        sub.destroy!
      end
      product_assignments = ProductSubproduct.find_all_by_subproduct_id(subproduct.id)
      product_assignments.each do |sub|
        sub.destroy!
      end
      subproduct.destroy!
    end
  end
  
end