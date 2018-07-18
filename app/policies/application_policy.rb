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
    user.owner?
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

  class Scope
    attr_reader :user, :scope

    def initialize(user, scope)
      @user = user
      @scope = scope
    end

    def resolve
      scope.all
    end
  end
end
