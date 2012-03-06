namespace :set_closed_on_to_upadte_at do
  task :update_closed_on => :environment do
    lookup_id = CompanyLookup.find :all, :select => "id", :conditions =>['lvalue = ? OR lvalue = ?','Closed/Won','Closed/Lost']
    Opportunity.update_all("closed_on = status_updated_on",['stage in (?) and closed_on Is NULL',lookup_id])
  end
end