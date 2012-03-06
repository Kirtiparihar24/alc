namespace :contant_phone do
  task :set_lookup => :environment do
    companies = Company.find :all
    companies.each do |company|
      phone_lvalue = ["Work", "Mobile", "Home", "Other"]
      phone_lvalue.each do |phnl|
        ContactPhoneType.create(:company_id => company.id, :type => "ContactPhoneType", :lvalue => phnl)
      end
    end
  end
end