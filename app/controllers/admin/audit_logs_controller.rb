module Admin
  class AuditLogsController < Admin::BaseController
    def index
      authorize AuditLog
      @audit_logs = policy_scope(AuditLog).recent.limit(200)
    end
  end
end
