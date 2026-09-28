#!/usr/bin/env ruby
$stdout.sync = true
require_relative "../config/environment"

client = Temporalio::Client.connect(
  ENV.fetch("TEMPORAL_ADDRESS", "localhost:7233"),
  ENV.fetch("TEMPORAL_NAMESPACE", "default")
)

worker = Temporalio::Worker.new(
  client: client,
  task_queue: "background-check",
  workflows: [ Workflows::BackgroundCheckWorkflow ],
  activities: [
    Activities::FindFormerNamesActivity,
    Activities::FindJurisdictionsActivity,
    Activities::SendSearchActivity,
    Activities::EvaluateResultsActivity,
    Activities::CompareCustomerAssessmentsActivity,
    Activities::RequestCandidateStoryActivity,
    Activities::NotifyCustomerAndCandidateActivity,
    Activities::HandlePossibleFcraDisputeActivity
  ]
)

puts "Starting Temporal worker on task queue 'background-check'..."
worker.run(shutdown_signals: [ "SIGINT", "SIGTERM" ])
