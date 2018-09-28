class Admin::DashboardController < AdminController
  def show
    skip_authorization

    @users_requesting_approval = User.requested_sync_approval

    @facilities = Facility.all
    @patients_per_facility_total = Facility.joins(:patients).group("facilities.id").count("patients.id")
    @patients_per_facility_30days = Facility.joins(:patients).where('patients.created_at > ?', 30.days.ago.beginning_of_day).group("facilities.id").count("patients.id")
    @control_rate_per_facility = control_rate_per_facility
  end

  private

  def control_rate_per_facility
    control_rate = {}
    hypertensive_patients.each do |facility_id, patient_ids|
      numerator = patients_under_control_for_facility(facility_id, patient_ids).size
      denominator = patient_ids.size
      control_rate[facility_id] = numerator.to_f / denominator unless denominator == 0
    end
    control_rate
  end

  def hypertensive_patients(since: Time.new(0), upto: Time.now)
    hypertensive_patients = {}
    BloodPressure.hypertensive
      .select(:facility_id, 'array_agg(distinct(patient_id)) as hypertensive_patient_ids')
      .where("created_at >= ?", since)
      .where("created_at <= ?", upto)
      .group(:facility_id)
      .each { |record| hypertensive_patients[record.facility_id] = record.hypertensive_patient_ids }
    hypertensive_patients
  end

  def patients_under_control_for_facility(facility_id, patient_ids)
    BloodPressure.select('distinct on (patient_id) *')
      .where(facility_id: facility_id)
      .where(patient: patient_ids)
      .order(:patient_id, created_at: :desc)
      .select { |blood_pressure| blood_pressure.under_control? }
      .map(&:patient_id)
  end
end