class UserPolicy < ApplicationPolicy
  def index?
    user.owner? || user.supervisor?
  end

  def show?
    index?
  end

  def disable_access?
    index?
  end

  def enable_access?
    index?
  end

  def reset_otp?
    index?
  end
end
