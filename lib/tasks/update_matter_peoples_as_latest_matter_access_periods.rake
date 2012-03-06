namespace :update_matter_peoples do

  desc "Update matter_peoples as per the latest matter access periods from matter_access_periods for the current date"
  task :matter_access_periods_to_matter_peoples_single_date => :environment do
    matter_access_periods = MatterAccessPeriod.find(:all, :conditions => ["start_date =? ", Date.today])
    matter_access_periods.each do |matter_access_period|
      matter_people = matter_access_period.matter_people
      if matter_people.present? && matter_people.end_date.present?
        matter_people.update_attributes(:start_date => matter_access_period.start_date,:end_date => matter_access_period.end_date)
      end
    end
  end

  desc "Update matter_peoples as per the latest matter access periods from matter_access_periods for past 2 weeks"
  task :matter_access_periods_to_matter_peoples_bulk_dates => :environment do
    matter_access_periods = MatterAccessPeriod.find(:all, :conditions => ["start_date >=? and  start_date <=? ", Date.today-14, Date.today])
    matter_access_periods.each do |matter_access_period|
      matter_people = matter_access_period.matter_people
      if matter_people.present? && matter_people.end_date.present?
        matter_people.update_attributes(:start_date => matter_access_period.start_date,:end_date => matter_access_period.end_date)
      end
    end
  end
  
end
