module ReportsHelper

  #Defining module level methods here
  class << self
    #This method is used to store lookup col values in to hash.
    def get_lookups(col)
      hash = {}
      unless col.nil?
        col.each do |obj|
          hash[obj.id] = obj.alvalue.try(:titleize)
        end
      end
      hash
    end

    #Getting required lookups from Lookup table ; This method is used in RptContacts and RptAccounts
    def get_contacts_lookups(company)
      sources,stages,status_l = {},{},{}
      company_sources = company.company_sources
      sources = ReportsHelper.get_lookups(company_sources)
      sources[""] , sources[nil] = "",""
      lookup_stages = company.contact_stages
      stages = ReportsHelper.get_lookups(lookup_stages)
      stages[""] , stages[nil] = "",""
      lookup_status = company.lead_status_types
      lookup_status = (lookup_status + company.prospect_status_types).flatten
      status_l = ReportsHelper.get_lookups(lookup_status)
      status_l[""] , status_l[nil] = "",""
      [sources,stages,status_l]
    end

    #This method is to get the time
    def set_start_time(params,conditions_hash)
      case params[:report][:duration]
      when "1"
        #1 week
        display_data = "in Last 1 Week"
        time = 7.days.ago
      when "2"
        #1month
        display_data = "in Last 1 Month"
        time = Time.zone.now.last_month
      when "3" #3months
        display_data = "in Last 3 Months"
        time = 3.months.ago
        
      when "4" #6months
        display_data = "in Last 6 Months"
        time = 6.months.ago
      when "range"
        display_data = "between #{params[:date_start]} - #{params[:date_end]}"
        conditions_hash[:start] = params[:date_start].to_time
        conditions_hash[:end] = params[:date_end].to_time + (23.9*60*60)
      end

      unless params[:report][:duration] == "range"
        conditions_hash[:start] = time.getutc
        conditions_hash[:end] = Time.zone.now.getutc
      end
      [display_data]
    end
  end
  
end
