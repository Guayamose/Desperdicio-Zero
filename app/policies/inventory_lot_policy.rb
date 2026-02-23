class InventoryLotPolicy < ApplicationPolicy
  def index?
    user.present?
  end

  def expirations?
    index?
  end

  def show?
    system_admin? || tenant_member?(record.tenant)
  end

  def create?
    user.present? && (system_admin? || tenant_member?(record.tenant) || tenant_member?(Current.tenant))
  end

  def update?
    system_admin? || tenant_member?(record.tenant)
  end

  def destroy?
    update?
  end

  class Scope < Scope
    def resolve
      return scope.all if system_admin?

      scope.where(tenant_id: tenant_ids)
    end
  end
end
