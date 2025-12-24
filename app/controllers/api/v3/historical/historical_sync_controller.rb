module Api
  module V3
    module Historical
      class HistoricalSyncController < APIController
        include Api::V3::SyncToUser

        def __sync_from_user__(params)
          results = params.map { |record| process_single_record(record) }

          render json: {
            processed: results.filter_map { |r| r[:record]&.id },
            errors: results.filter_map { |r| r[:errors_hash] }
          }, status: :ok
        end

        def __sync_to_user__(response_key)
          records = records_to_sync

          transformed_records = records.map { |record| transform_to_response(record) }

          json = Oj.dump({
            response_key => transformed_records,
            "process_token" => encode_process_token(response_process_token)
          }, mode: :compat)

          render json: json, status: :ok
        end

        private

        def process_single_record(record_params)
          result = nil

          ActiveRecord::Base.transaction do
            result = merge_if_valid(record_params)
          end

          result
        rescue ActiveRecord::RecordNotUnique => e
          error(record_params[:id], "duplicate_record", e.message)
        rescue ActiveRecord::InvalidForeignKey => e
          error(record_params[:id], "invalid_reference", e.message)
        rescue ActiveRecord::NotNullViolation => e
          error(record_params[:id], "missing_required_field", e.message)
        rescue ActiveRecord::StatementInvalid => e
          error(record_params[:id], "database_error", e.message)
        rescue => e
          error(record_params[:id], "unknown_error", e.message)
        end

        def merge_if_valid(_params)
          raise NotImplementedError
        end

        def model
          controller_name.classify.constantize
        end

        def process_token
          if params[:process_token].present?
            JSON.parse(Base64.decode64(params[:process_token])).with_indifferent_access
          else
            {}
          end
        end

        def max_limit
          1000
        end

        def limit
          return ENV["DEFAULT_NUMBER_OF_RECORDS"].to_i unless params[:limit].present?

          params_limit = params[:limit].to_i
          params_limit < max_limit ? params_limit : max_limit
        end

        def error(id, type, message)
          {errors_hash: {id: id, error_type: type, message: message}}
        end

        def disable_audit_logs?
          true
        end

        # Assigns attributes safely, converting invalid enum values to nil
        # instead of raising ArgumentError
        def safe_assign_attributes(record, attributes)
          attributes = attributes.to_h if attributes.respond_to?(:to_h)
          enum_cols = record.class.defined_enums

          safe_attrs = attributes.each_with_object({}) do |(key, value), result|
            result[key] = if enum_cols.key?(key.to_s) && !enum_cols[key.to_s].key?(value)
              nil
            else
              value
            end
          end

          record.assign_attributes(safe_attrs)
        end
      end
    end
  end
end
