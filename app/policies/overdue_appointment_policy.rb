class OverdueAppointmentPolicy < Struct.new(:user, :patient_detail)
  attr_reader :user, :record

  def initialize(user, record)
    @user = user
    @record = record
  end

  def index?
    user.healthcare_counsellor?
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

  class Scope
    attr_reader :user, :scope

    def initialize(user, scope)
      @user = user
      @scope = scope
    end

    def resolve
      user.healthcare_counsellor? ? OverdueAppointment.for_admin(user) : []
    end
  end
end