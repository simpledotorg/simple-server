class FacilityGroupPolicy < ApplicationPolicy
  def index?
    user.owner?
  end

  def show?
    index?
  end
end