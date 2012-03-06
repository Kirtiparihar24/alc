namespace :add_matter_no_values do
  desc "Add matter no values for blank matter no"
  task :fill_matter_nos => :environment do
    year = Date.today.year
    i = 1
    Matter.find_each(:conditions => ["matter_no is NULL OR matter_no = ?",'']) do |matter|
      name = matter.matter_name_initials(matter.name)
      matter_no = year.to_s + "/" + name + "/" + i.to_s
      Matter.update_all({:matter_no=>matter_no}, {:id => matter.id})
      i += 1
    end
  end
end