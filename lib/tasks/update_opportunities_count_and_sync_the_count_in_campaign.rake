# Author Rohit
# Task to update opportunities_count in campaigns and sync the count for the use of counter cache

desc "update opportunities_count and sync the count too in campaigns for the use of counter cache"
task :set_opportunities_count_to_zero_if_its_nil_and_synchronize_opp_count_with_camp_opportunities => :environment do

  ActiveRecord::Base.connection.execute("UPDATE campaigns SET opportunities_count=0 WHERE (opportunities_count IS NULL OR opportunities_count < 0)")

  Campaign.all.each do |campaign|
    opportunities_count = campaign.opportunities.count
    ActiveRecord::Base.connection.execute("UPDATE campaigns SET opportunities_count=#{opportunities_count} WHERE (id = #{campaign.id})")
  end
end


