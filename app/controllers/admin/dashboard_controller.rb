class Admin::DashboardController < AdminController
  def show
    skip_authorization

    Groupdate.time_zone = "New Delhi"

    @users_requesting_approval = User.requested_sync_approval

    @facilities = Facility.all.order(:name)

    @days_previous = 20
    @months_previous = 8

    @visits_by_facility          = visits_by_facility
    @visits_by_facility_user     = visits_by_facility_user
    @visits_by_facility_user_day = visits_by_facility_user_day
    @visits_by_facility_month    = visits_by_facility_month

    @new_patients_by_facility       = new_patients_by_facility
    @new_patients_by_facility_month = new_patients_by_facility_month

    @control_rate_by_facility = control_rate_by_facility

    # Reset when done
    Groupdate.time_zone = "UTC"
  end

  private

  def visits_by_facility
    BloodPressure.group(:facility_id).count("distinct patient_id")
  end

  def visits_by_facility_user
    BloodPressure.group(:facility_id, :user_id).count("distinct patient_id")
  end

  def visits_by_facility_user_day
    BloodPressure.group(:facility_id, :user_id).group_by_day(:device_created_at, last: @days_previous + 1).count("distinct patient_id")
  end

  def visits_by_facility_month
    BloodPressure.group(:facility_id).group_by_month(:device_created_at, last: @months_previous + 1).count("distinct patient_id")
  end

  def new_patients_by_facility
    Facility.joins(:patients).group("facilities.id").distinct('patients.id').count("patients.id")
  end

  def new_patients_by_facility_month
    Facility.joins(:patients).group("facilities.id").distinct('patients.id').group_by_month("patients.device_created_at", last: @months_previous + 1).count("patients.id")
  end

  def control_rate_by_facility
    control_rate = {}

    hypertensive_patients_by_facility.each do |facility_id, patient_ids|
      numerator = controlled_patients_for_facility(facility_id, patient_ids).size
      denominator = patient_ids.size
      control_rate[facility_id] = numerator.to_f / denominator unless denominator == 0
    end

    control_rate
  end

  def hypertensive_patients_by_facility(since: Time.new(0), upto: Time.now.in_time_zone("New Delhi"))
    hypertensive_patients = {}

    BloodPressure.hypertensive
      .select(:facility_id, 'array_agg(distinct(patient_id)) as hypertensive_patient_ids')
      .where("created_at >= ?", since)
      .where("created_at <= ?", upto)
      .group(:facility_id)
      .each { |record| hypertensive_patients[record.facility_id] = record.hypertensive_patient_ids }

    hypertensive_patients
  end

  def controlled_patients_for_facility(facility_id, patient_ids)
    BloodPressure.select('distinct on (patient_id) *')
      .where(facility_id: facility_id)
      .where(patient: patient_ids)
      .order(:patient_id, created_at: :desc)
      .select { |blood_pressure| blood_pressure.under_control? }
      .map(&:patient_id)
  end
end
