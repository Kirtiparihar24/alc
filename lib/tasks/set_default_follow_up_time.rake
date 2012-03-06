namespace :set_time do
  task :follow_up_time => :environment do
    companies = Company.all
    companies.each do|company|
      opportunities = company.opportunities
      opportunities.each do |opportunity|
        unless opportunity.follow_up.nil?
          begin
          Opportunity.update_all(["follow_up = ?", opportunity.follow_up.advance(:hours => 13)], ["id = ?", opportunity.id]) if opportunity.follow_up.strftime("%H:%M:%S").eql?("00:00:00")
          rescue => e
            p e
          end
        end
      end
    end
  end
end