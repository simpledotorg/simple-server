FactoryBot.define do
  factory :overdue_appointment do
    patient
    blood_pressure { create(:blood_pressure, patient: patient) }
    appointment do
      create(:appointment,
             patient: patient,
             status: :scheduled,
             scheduled_date: Date.today - 5.days)
    end
  end
end
