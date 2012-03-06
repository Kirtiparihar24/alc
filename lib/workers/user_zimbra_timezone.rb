class UserZimbraTimezone
  @queue = :user_zimbra_timezone

  def self.perform(key, host, email, zimbra_time_zone)
    begin
      ZimbraTimeZone::update_time_zone(key, host, email, zimbra_time_zone)
    rescue => e      
    end
  end
end
