class Admin::DashboardController < AdminController
  def show
    skip_authorization

    @users_requesting_approval = User.where(sync_approval_status: :requested)

    @facilities = Facility.all
    @patients_per_facility_total = Facility.joins(:patients).group("facilities.id").count("patients.id")
    @patients_per_facility_30days = Facility.joins(:patients).where('patients.created_at > ?', 30.days.ago.beginning_of_day).group("facilities.id").count("patients.id")
  end
end
