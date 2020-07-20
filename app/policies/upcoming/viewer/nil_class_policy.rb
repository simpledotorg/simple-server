class Upcoming::Viewer::NilClassPolicy < Upcoming::ApplicationPolicy
  class Scope < Scope
    def resolve
      raise Pundit::NotDefinedError, "Cannot scope NilClass"
    end
  end
end
