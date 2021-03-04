class Admin::DeduplicatePatientsController < AdminController
  def show
    authorize { current_admin.power_user? }

    @patients = Patient.take(5)
  end
end
