class OrganizationPolicy < ApplicationPolicy
  def index?
    user.owner?
  end

  def show?
    index?
  end
end