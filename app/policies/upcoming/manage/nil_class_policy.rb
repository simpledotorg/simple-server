class Upcoming::Manage::NilClassPolicy < Upcoming::ApplicationPolicy
  class Scope < Scope
    def resolve
      raise Pundit::NotDefinedError, "Cannot scope NilClass"
    end
  end
end
