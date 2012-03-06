namespace :fill_matter_access_period do

  desc "Fill matter_access_periods from matter_peoples, for old data access"
  task :add_matter_access_periods => :environment do
    matter_peoples = MatterPeople.all
    MatterAccessPeriod.transaction do
      matter_peoples.each do |matter_people|
        MatterAccessPeriod.create(:employee_user_id => matter_people.employee_user_id,:matter_id => matter_people.matter_id,:company_id => matter_people.company_id, :matter_people_id => matter_people.id,:start_date => matter_people.start_date, :end_date => matter_people.end_date,:is_active => matter_people.is_active)
      end
    end
  end
  
  desc "Revert filled matter_access_periods"
  task :revert_matter_access_periods => :environment do
    matter_peoples = MatterPeople.all
    MatterAccessPeriod.transaction do
      matter_peoples.each do |matter_people|
        accesses = MatterAccessPeriod.find(:all,:conditions => {:employee_user_id => matter_people.employee_user_id,:matter_id => matter_people.matter_id,:company_id => matter_people.company_id, :matter_people_id => matter_people.id,:start_date => matter_people.start_date, :end_date => matter_people.end_date,:is_active => matter_people.is_active})
        accesses.each do |access|
          access.destroy
        end
      end
    end
  end
end
