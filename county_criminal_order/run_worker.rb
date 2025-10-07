# frozen_string_literal: true

require_relative 'order_activities'
require_relative 'order_workflow'
require 'logger'
require 'temporalio/client'
require 'temporalio/worker'

# Create a Temporal client
client = Temporalio::Client.connect(
  'localhost:7233',
  'default',
  logger: Logger.new($stdout, level: Logger::INFO)
)

worker = Temporalio::Worker.new(
  client:,
  task_queue: 'county-criminal-order',
  activities: [
    CountyCriminalOrder::Activities::SendNotification,
    CountyCriminalOrder::Activities::ComputeAliases,
    CountyCriminalOrder::Activities::FindCountiesToSearch,
    CountyCriminalOrder::Activities::SendOrder,
    CountyCriminalOrder::Activities::ParseResults,
    CountyCriminalOrder::Activities::BillCustomer,
    CountyCriminalOrder::Activities::Assess
  ],
  workflows: [CountyCriminalOrder::OrderWorkflow]
)

# Run the worker until SIGINT
puts 'Starting worker (ctrl+c to exit)'
worker.run(shutdown_signals: ['SIGINT'])
