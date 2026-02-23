module Api
  module V1
    class BaseController < ApplicationController
      protect_from_forgery with: :null_session
      skip_forgery_protection

      rescue_from ActiveRecord::RecordNotFound, with: :handle_not_found
      rescue_from ActionController::ParameterMissing, with: :handle_bad_request

      private

      def render_resource(resource, status: :ok)
        render json: {
          data: camelize_hash(resource.as_json),
          requestId: request.request_id
        }, status: status
      end

      def render_collection(collection)
        scoped = collection.respond_to?(:all) ? collection : Array(collection)
        paged = collection.respond_to?(:offset) ? paginate(collection) : Array(collection)

        render json: {
          data: paged.map { |item| camelize_hash(item.as_json) },
          meta: pagination_meta(scoped),
          requestId: request.request_id
        }, status: :ok
      end

      def render_error(code:, message:, status:, details: nil)
        payload = {
          code: code,
          message: message,
          details: details,
          requestId: request.request_id
        }.compact

        render json: payload, status: status
      end

      def authenticate_api_user!
        return if user_signed_in?

        render_error(code: "unauthorized", message: "Authentication required", status: :unauthorized)
      end

      def page
        (params[:page] || 1).to_i.clamp(1, 10_000)
      end

      def per_page
        (params[:per_page] || params[:perPage] || 20).to_i.clamp(1, 100)
      end

      def paginate(scope)
        scope.offset((page - 1) * per_page).limit(per_page)
      end

      def pagination_meta(scope)
        total = scope.count
        {
          page: page,
          perPage: per_page,
          total: total,
          totalPages: (total.to_f / per_page).ceil
        }
      end

      def camelize_hash(obj)
        case obj
        when Array
          obj.map { |v| camelize_hash(v) }
        when Hash
          obj.deep_transform_keys { |k| k.to_s.camelize(:lower) }.transform_values { |v| camelize_hash(v) }
        else
          obj
        end
      end

      def handle_not_found(exception)
        render_error(code: "not_found", message: exception.message, status: :not_found)
      end

      def handle_bad_request(exception)
        render_error(code: "bad_request", message: exception.message, status: :bad_request)
      end
    end
  end
end
