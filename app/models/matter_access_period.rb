class MatterAccessPeriod < ActiveRecord::Base
  belongs_to :matter
  belongs_to :matter_people
  belongs_to :company
  default_scope :order => "matter_access_periods.start_date"


  ### Author Shripad for Matter Access Periods on 23/12/2011
  #This method will merged the overlapped dates eg
  #Examples will have the start and end date at the same index for star_date and end_date array
  #eg. 1. (Complete Overlapping)
    # start_date = ['12/24/2011','12/27/2011','12/29/2011']
    #end_date = ['12/26/2011','12/28/2011','12/30/2011']
    #o/p - ['12/24/2011'] --Start dates
    #o/p - ['12/30/2011'] -- End dates
  #eg. 2. (No Overlapping)
    #start_date = ['12/24/2011','12/28/2011','01/01/2012']
    #end_date = ['12/26/2011','12/29/2011','01/30/2012']
    #o/p -- ['12/24/2011','12/28/2011','01/01/2012'] --Start Date
    #o/p -- ['12/26/2011','12/29/2011','01/30/2012'] --End Date
  #eg. 3. (Partial Overlapping)
    #start_date = ['12/24/2011','01/01/2012','12/27/2011']
    #end_date = ['12/26/2011','01/30/2012','12/29/2011']
    #o/p --  ['12/24/2011','01/01/2012' ]--Start Date
    #o/p -- [ '12/29/2011', '01/30/2012']--End Date
  #eg 4. (For Infinite access)
    #start_date = ['12/24/2011','12/27/2011','01/01/2012']
    #end_date = ['12/26/2011',nil,'01/30/2012']
    #o/p -- ['12/24/2011'] --Start Date
    #o/p -- [nil] --End Date
  def self.date_merge(start_date, end_date)

    indexes = []
    0.upto(start_date.length-1) do |k|
      (k+1).upto(end_date.length-1) do |l|
        if (end_date[k].nil? || end_date[l].nil?)
          indexes << k
          indexes << l
        else
          if((start_date[k])<= (end_date[l])+1 && (start_date[l]) <= (end_date[k])+1)
            indexes << k
            indexes << l
          end
        end
      end
    end
    unless indexes.empty?
      if start_date.length == indexes.uniq.length
        latest_dates = []
        latest_dates << start_date.sort.first
        if end_date.include?(nil)
          latest_dates <<  nil
        else
          latest_dates <<  end_date.sort.last
        end
        start_date.clear
        end_date.clear
        start_date << latest_dates[0]
        end_date << latest_dates[1]
      else
        latest_start_dates, latest_end_dates = [], []
        indexes.uniq.each do |ind|
          latest_start_dates << start_date[ind]
          latest_end_dates <<  end_date[ind]
        end
        new_start = start_date - latest_start_dates
        new_end = end_date - latest_end_dates
        lowest_date = latest_start_dates.sort.first
        highest_date = latest_end_dates.sort.last
        start_date.clear
        end_date.clear
        start_date << lowest_date
        start_date <<  new_start
        end_date << highest_date
        end_date << new_end
      end
    end
    return start_date.flatten, end_date.flatten
  end


  #This method will validate the entered dates, added for the feature no 7192
  #Following validations are checked
  #1. if the start_date or end_date is blank
  #2. if the start_date is less than the matter inception date
  #3. if start date is greater than the end date

  def self.dates_in_range(matter, matter_people_client, matter_dates, edit_start_date=nil, edit_end_date=nil, id_val_access = nil)

    access_start_date, access_end_date, id_val = [], [], []
    matter_people_client.matter_access_periods.all.each do |access|
      access_start_date << access.start_date
      access_end_date << access.end_date
      id_val << access.id
    end

    if edit_start_date.present? && edit_end_date.present?

      access_start_date_actual, access_end_date_actual = [], []
      matter_people_client.matter_access_periods.find(:all,:conditions => "matter_access_periods.id not in (#{id_val_access})").each do |access|
        access_start_date_actual << access.start_date
        access_end_date_actual << access.end_date
      end
      start_date = Date.parse(edit_start_date).to_a
      end_date = Date.parse(edit_end_date).to_a
      start_date =  (start_date << access_start_date_actual).flatten
      end_date = (end_date << access_end_date_actual).flatten


      start_date_entered, end_date_entered = MatterAccessPeriod.date_merge(start_date, end_date)
      return start_date_entered, end_date_entered, id_val
    end

    start_date, end_date = [], []
    matter_dates.each_value do |matter_date|
      dates = matter_date.values_at("start_date","end_date")
      start_date << Date.parse(dates[0])
      end_date << (dates[1].blank? ? nil : Date.parse(dates[1]))
    end
    start_date_entered, end_date_entered = false, false
    if start_date.include?('')
      return start_date_entered, end_date_entered
    end
    0.upto(start_date.length-1) do |i|
      if end_date[i].present?
        if ((start_date[i])< matter.matter_date || (start_date[i])> (end_date[i]))
          return start_date_entered, end_date_entered
        end
      else
        if ((start_date[i])< matter.matter_date)
          return start_date_entered, end_date_entered
        end
      end
    end

    start_date =  (start_date << access_start_date).flatten
    end_date = (end_date << access_end_date).flatten
    start_date_entered, end_date_entered = MatterAccessPeriod.date_merge(start_date, end_date)

    return start_date_entered, end_date_entered
    
  end 
  

end