namespace :company_setting do
  task :set_default_duration_setting => :environment do
    companies = Company.find(:all,:select=>[:id])
    companies.each do |company|
      DurationSetting.find_or_create_by_created_by_user_id_and_company_id_and_setting_value(1,company.id,'1/100th')
    end
  end
end
