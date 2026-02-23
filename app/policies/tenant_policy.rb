class TenantPolicy < ApplicationPolicy
  def index?
    system_admin?
  end

  def show?
    system_admin? || tenant_member?(record)
  end

  def create?
    system_admin?
  end

  def update?
    system_admin?
  end

  def destroy?
    system_admin?
  end

  class Scope < Scope
    def resolve
      return scope.all if system_admin?

      scope.where(id: tenant_ids)
    end
  end
end
