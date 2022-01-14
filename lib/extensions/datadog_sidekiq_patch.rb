module Datadog
  module Contrib
    module Sidekiq
      module ServerInternalTracer
        # Trace when Sidekiq looks for another job to work
        module JobFetch
          private

          FETCH_SAMPLE_RATE = 0.01

          def fetch
            configuration = Datadog.configuration[:sidekiq]

            configuration[:tracer].trace(Ext::SPAN_JOB_FETCH) do |span|
              span.service = configuration[:service_name]
              span.span_type = Datadog::Ext::AppTypes::WORKER

              # Set analytics sample rate
              if Contrib::Analytics.enabled?(configuration[:analytics_enabled])
                FETCH_SAMPLE_RATE
              end

              super
            end
          end
        end
      end
    end
  end
end