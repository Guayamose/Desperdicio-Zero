class MenuGenerationPolicy < ApplicationPolicy
  def create?
    user.present? && (system_admin? || tenant_member?(record.tenant) || tenant_member?(Current.tenant))
  end

  def show?
    system_admin? || tenant_member?(record.tenant)
  end

  class Scope < Scope
    def resolve
      return scope.all if system_admin?

      scope.where(tenant_id: tenant_ids)
    end
  end
end
