class Analytics::FacilitiesController < AnalyticsController
  before_action :set_facility
  before_action :set_facility_group
  before_action :set_organization

  COHORT_MONTHS_PREVIOUS = 6

  def show
    @facility_analytics = @facility.patient_set_analytics(@from_time, @to_time)
    @user_analytics = user_analytics

    @registered = registered
    @visited = visited(@registered)
    @controlled = controlled(@visited)
    @uncontrolled = uncontrolled(@visited)

    @num_registered = @registered.size
    @num_visited = @visited.size
    @num_controlled = @controlled.size
    @num_uncontrolled = @uncontrolled.size
    @num_defaulted = @registered.size - @visited.size

    @controlled_percent = (@num_controlled.to_f / @num_registered * 100).round
    @uncontrolled_percent = (@num_uncontrolled.to_f / @num_registered * 100).round
    @default_percent = ((@num_defaulted - @num_visited).to_f / @num_registered * 100).round
  end

  def graphics
    @current_month = Date.today.at_beginning_of_month.to_date
    @facility_analytics = @facility.patient_set_analytics(@from_time, @to_time)
  end

  private

  def set_facility
    facility_id = params[:id] || params[:facility_id]
    @facility = Facility.friendly.find(facility_id)
    authorize(@facility)
  end

  def set_facility_group
    @facility_group = @facility.facility_group
  end

  def set_organization
    @organization = @facility.organization
  end

  def users_for_facility
    User.joins(:blood_pressures).where('blood_pressures.facility_id = ?', @facility.id).order(:full_name).distinct
  end

  def user_analytics
    users_for_facility.map { |user| [user, Analytics::UserAnalytics.new(user, @facility)] }.to_h
  end

  def registered
    cohort_start = @from_time - COHORT_MONTHS_PREVIOUS.months
    cohort_end = @to_time - COHORT_MONTHS_PREVIOUS.months

    Patient.select(%Q(
      patients.*,
      oldest_bps.device_created_at as bp_device_created_at,
      oldest_bps.facility_id as bp_facility_id,
      oldest_bps.systolic as bp_systolic,
      oldest_bps.diastolic as bp_diastolic
    )).joins(%Q(
      INNER JOIN (
        SELECT DISTINCT ON (patient_id) *
        FROM blood_pressures
        ORDER BY patient_id, device_created_at ASC
      ) as oldest_bps
      ON oldest_bps.patient_id = patients.id
    )).where(
      "oldest_bps.device_created_at" => cohort_start..cohort_end,
      "oldest_bps.facility_id" => @facility
    )
  end

  def visited(patients)
    patients.select(%Q(
      patients.*,
      newest_bps.device_created_at as bp_device_created_at,
      newest_bps.systolic as bp_systolic,
      newest_bps.diastolic as bp_diastolic
    )).joins(%Q(
      INNER JOIN (
        SELECT DISTINCT ON (patient_id) *
        FROM blood_pressures
        WHERE device_created_at >= '#{@from_time}'
        AND device_created_at <= '#{@to_time}'
        ORDER BY patient_id, device_created_at DESC
      ) as newest_bps
      ON newest_bps.patient_id = patients.id
    ))
  end

  def controlled(patients)
    patients.select { |p| p.bp_systolic < 140 && p.bp_diastolic < 90 }
  end

  def uncontrolled(patients)
    patients.select { |p| p.bp_systolic >= 140 || p.bp_diastolic >= 90 }
  end
end

