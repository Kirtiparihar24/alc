class SyncZimbraAppointment
  @queue = :sync_zimbra_appointment

  def self.perform(user_id)
    user = User.find(user_id)
    SyncZimbraCalendar.new(user).sync_appointments
    send_notification_for_appointment_synchronization(user)
  end
end
