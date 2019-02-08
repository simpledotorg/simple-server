class OverdueAppointmentPolicy < Struct.new(:user, :patient_detail)
  attr_reader :user, :record

  def initialize(user, record)
    @user = user
    @record = record
  end

  def index?
    user.counsellor?
  end

  def edit?
    index?
  end

  def update?
    edit?
  end

  def cancel?
    edit?
  end
end