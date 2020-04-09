class PatientSummary < ActiveRecord::Base
  self.primary_key = :id

  def readonly?
    true
  end

  def self.overdue
    where(next_appointment_status: 'scheduled')
      .where('next_appointment_scheduled_date < ?', Date.current)
      .where('next_appointment_scheduled_date >= ?', 365.days.ago)
      .where('next_appointment_remind_on IS NULL OR next_appointment_remind_on <= ?', Date.current)
  end
end
