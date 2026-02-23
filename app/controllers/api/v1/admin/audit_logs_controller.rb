module Api
  module V1
    module Admin
      class AuditLogsController < Api::V1::Admin::BaseController
        def index
          authorize AuditLog
          logs = paginate(policy_scope(AuditLog).recent)

          render json: {
            data: logs.map { |log| camelize_hash(log.as_json) },
            meta: pagination_meta(policy_scope(AuditLog)),
            requestId: request.request_id
          }, status: :ok
        end
      end
    end
  end
end
