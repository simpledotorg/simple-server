class Upcoming::NilClassPolicy < Upcoming::ApplicationPolicy
  def allowed?
    super
  end

  class Scope < Scope
    def resolve
      raise Pundit::NotDefinedError, "Cannot scope NilClass"
    end
  end
end
