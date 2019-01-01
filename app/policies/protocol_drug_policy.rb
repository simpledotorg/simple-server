class ProtocolDrugPolicy < ApplicationPolicy
  class Scope
    attr_reader :user, :scope

    def initialize(user, scope)
      @user = user
      @scope = scope
    end

    def resolve
      @user.organizations.flat_map(&:protocols)
    end
  end
end
