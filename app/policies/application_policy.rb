class ApplicationPolicy
  attr_reader :user, :record

  def initialize(user, record)
    @user = user
    @record = record
  end

  def index?
    user.owner?
  end

  def show?
    scope.where(:id => record.id).exists?
  end

  def create?
    user.owner?
  end

  def new?
    create?
  end

  def update?
    user.owner?
  end

  def edit?
    update?
  end

  def destroy?
    user.owner?
  end

  def scope
    Pundit.policy_scope!(user, record.class)
  end

  class Scope
    attr_reader :user, :scope

    def initialize(user, scope)
      @user = user
      @scope = scope
    end

    def resolve
      scope
    end
  end
end
