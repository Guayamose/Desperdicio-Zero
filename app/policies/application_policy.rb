class ApplicationPolicy
  attr_reader :user, :record

  def initialize(user, record)
    @user = user
    @record = record
  end

  def index?
    false
  end

  def show?
    false
  end

  def create?
    false
  end

  def new?
    create?
  end

  def update?
    false
  end

  def edit?
    update?
  end

  def destroy?
    false
  end

  protected

  def system_admin?
    user&.system_admin?
  end

  def tenant_member?(tenant)
    return false unless user && tenant

    user.in_tenant?(tenant)
  end

  class Scope
    attr_reader :user, :scope

    def initialize(user, scope)
      @user = user
      @scope = scope
    end

    def resolve
      raise NoMethodError, "You must define #resolve in #{self.class}"
    end

    private

    def system_admin?
      user&.system_admin?
    end

    def tenant_ids
      user&.active_memberships&.pluck(:tenant_id) || []
    end
  end
end
