module Telemetry
  def self.tracing_interceptor
    return @tracing_interceptor if defined?(@tracing_interceptor)

    @tracing_interceptor = if ENV["HONEYCOMB_API_KEY"].present?
      Temporalio::Contrib::OpenTelemetry::TracingInterceptor.new(
        OpenTelemetry.tracer_provider.tracer(ENV.fetch("OTEL_SERVICE_NAME", "rocky-mountain-ruby-demo"))
      )
    end
  end

  def self.interceptors
    [ tracing_interceptor ].compact
  end
end
