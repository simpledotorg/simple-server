class ProtocolDrugPolicy < ApplicationPolicy
  class Scope
    attr_reader :user, :scope

    def initialize(user, scope)
      @user = user
      @scope = scope
    end

    def resolve
      scope.where(protocol_id: @user.protocols.map(&:id))
    end
  end
end
