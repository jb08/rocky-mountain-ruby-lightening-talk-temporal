#!/usr/bin/env ruby
# Enqueues a batch of Sidekiq jobs across all of the background check job
# types, purely so the Sidekiq Web UI (http://localhost:3000/sidekiq) has
# something to look at during the demo. Doesn't require the Sidekiq worker
# to be running -- it just pushes jobs onto Redis.
require_relative "../config/environment"

TOTAL_JOBS = 30

CANDIDATE_NAMES = [
  "Jamie Rivera", "Alex Morgan", "Priya Patel", "Harry Kane", "Sam Okafor",
  "Taylor Chen", "Morgan Lee", "Jordan Blake", "Casey Nguyen", "Riley Brooks"
].freeze

ALIASES = [ "Jane A. Smith", "Jane Doe", "J. Smith", "Janie Doe" ].freeze
JURISDICTIONS = [
  "Los Angeles County, CA", "Kings County, NY", "Cook County, IL", "Harris County, TX"
].freeze

JOB_CLASSES = [
  BackgroundCheck::BackgroundCheckOrchestratorJob,
  BackgroundCheck::FindFormerNamesJob,
  BackgroundCheck::FindJurisdictionsJob,
  BackgroundCheck::SendSearchJob,
  BackgroundCheck::EvaluateResultsJob,
  BackgroundCheck::CompareCustomerAssessmentsJob,
  BackgroundCheck::RequestCandidateStoryJob,
  BackgroundCheck::NotifyCustomerAndCandidateJob,
  BackgroundCheck::HandlePossibleFcraDisputeJob
].freeze

runs = Array.new(10) { BackgroundCheckRun.create!(candidate_name: CANDIDATE_NAMES.sample) }

# Guarantee at least one of every job type, then fill the rest randomly.
job_classes_to_enqueue = JOB_CLASSES.dup
(TOTAL_JOBS - JOB_CLASSES.size).times { job_classes_to_enqueue << JOB_CLASSES.sample }
job_classes_to_enqueue.shuffle!

enqueued_counts = Hash.new(0)

job_classes_to_enqueue.each do |job_class|
  run = runs.sample

  if job_class == BackgroundCheck::SendSearchJob
    job_class.perform_async(run.id, ALIASES.sample, JURISDICTIONS.sample)
  else
    job_class.perform_async(run.id)
  end

  enqueued_counts[job_class.name] += 1
end

puts "Enqueued #{TOTAL_JOBS} jobs across #{runs.size} background check runs:"
enqueued_counts.sort_by { |_, count| -count }.each do |name, count|
  puts "  #{count.to_s.rjust(2)}x  #{name}"
end

puts "\nOpen http://localhost:3000/sidekiq to see them."
puts "(Leave the Sidekiq worker process OFF if you want them to stay queued instead of processing instantly.)"
