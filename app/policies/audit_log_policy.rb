class AuditLogPolicy < ApplicationPolicy
  def index?
    user.present? && (system_admin? || tenant_member?(record&.tenant || Current.tenant))
  end

  def show?
    index?
  end

  class Scope < Scope
    def resolve
      return scope.all if system_admin?

      scope.where(tenant_id: tenant_ids)
    end
  end
end
