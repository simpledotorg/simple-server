class Admin::DashboardController < AdminController
  def show
    skip_authorization

    @users_requesting_approval = User.requested_sync_approval

    @facilities = Facility.all.order(:name)
    @patients_per_facility_total = patient_count_per_facility
    @patients_per_facility_30days = patient_count_per_facility(since: 30.days.ago.beginning_of_day)
    @control_rate_per_facility = control_rate_per_facility
  end

  private

  def patient_count_per_facility(since: nil)
    patients_by_facility = Facility.joins(:patients).group("facilities.id").distinct('patient.id')

    if since.present?
      patients_by_facility.where('patients.created_at > ?', since)
    end

    patients_by_facility.count("patients.id")
  end

  def control_rate_per_facility
    control_rate = {}

    hypertensive_patients_per_facility.each do |facility_id, patient_ids|
      numerator = controlled_patients_per_facility(facility_id, patient_ids).size
      denominator = patient_ids.size
      control_rate[facility_id] = numerator.to_f / denominator unless denominator == 0
    end

    control_rate
  end

  def hypertensive_patients_per_facility(since: Time.new(0), upto: Time.now)
    hypertensive_patients = {}

    BloodPressure.hypertensive
      .select(:facility_id, 'array_agg(distinct(patient_id)) as hypertensive_patient_ids')
      .where("created_at >= ?", since)
      .where("created_at <= ?", upto)
      .group(:facility_id)
      .each { |record| hypertensive_patients[record.facility_id] = record.hypertensive_patient_ids }

    hypertensive_patients
  end

  def controlled_patients_per_facility(facility_id, patient_ids)
    BloodPressure.select('distinct on (patient_id) *')
      .where(facility_id: facility_id)
      .where(patient: patient_ids)
      .order(:patient_id, created_at: :desc)
      .select { |blood_pressure| blood_pressure.under_control? }
      .map(&:patient_id)
  end
end
