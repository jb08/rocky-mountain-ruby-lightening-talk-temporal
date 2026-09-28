if ENV["HONEYCOMB_API_KEY"].present?
  ENV["OTEL_SERVICE_NAME"] ||= "rocky-mountain-ruby-demo"
  ENV["OTEL_EXPORTER_OTLP_ENDPOINT"] ||= "https://api.honeycomb.io"

  headers = { "x-honeycomb-team" => ENV.fetch("HONEYCOMB_API_KEY") }
  headers["x-honeycomb-dataset"] = ENV["HONEYCOMB_DATASET"] if ENV["HONEYCOMB_DATASET"].present?
  ENV["OTEL_EXPORTER_OTLP_HEADERS"] ||= headers.map { |k, v| "#{k}=#{v}" }.join(",")

  require "opentelemetry/sdk"
  require "opentelemetry/exporter/otlp"
  require "temporalio/contrib/open_telemetry"

  OpenTelemetry::SDK.configure
end
