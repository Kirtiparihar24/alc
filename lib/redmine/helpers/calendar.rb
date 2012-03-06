module Redmine
  module Helpers
    
    # Simple class to compute the start and end dates of a calendar
    class Calendar
     
      attr_reader :startdt, :enddt
      
      def initialize(date, period = :month)
        @date = date
        @time_entries = []
        @time_entries_by_Day = {}
        
        case period
        when :month
          @startdt = Date.civil(date.year, date.month, 1)
          @enddt = (@startdt >> 1)-1
          # starts from the first day of the week
          @startdt = @startdt - (@startdt.cwday - first_wday)%7
          # ends on the last day of the week
          @enddt = @enddt + (last_wday - @enddt.cwday)%7
        when :week
          @startdt = date - (date.cwday - first_wday)%7
          @enddt = date + (last_wday - date.cwday)%7
        else
          raise 'Invalid period'
        end
      end
      
      def time_entries=(time_entries)
        @time_entries = time_entries
        @time_entries_by_day = @time_entries.group_by { |time_entry| time_entry.time_entry_date }
      end

      def time_entries_on(day)
        (@time_entries_by_day[day] || []).uniq
      end
    
      def time_entries_in_week(first_day, last_day)
         (@time_entries.collect{ |time_entry| time_entry if (time_entry.time_entry_date >= first_day and time_entry.time_entry_date <= last_day)  }).compact
      end

      def time_entries_in_month
        days_in_month = Date.civil(@date.year, @date.month, -1).day
        last_day = @date + (days_in_month-1)
        (@time_entries.collect{ |time_entry| time_entry if (time_entry.time_entry_date >= @date and time_entry.time_entry_date <= last_day)  }).compact
      end

      # Calendar current month
      def month
        @date.month
      end
      
      # Return the first day of week
      # 1 = Monday ... 7 = Sunday
      def first_wday
        @first_dow ||= (7 - 1)%6 + 1
      end
      
      def last_wday
        @last_dow ||= (first_wday + 5)%7 + 1
      end

      def first_hour
        @first_hod ||= (24 - 1)%24 + 1
      end

    end    
  end
end
