module Workflows
  class BackgroundCheckWorkflow < Temporalio::Workflow::Definition
    ALIASES = [ "Jane A. Smith", "Jane Doe" ].freeze
    JURISDICTIONS = [ "Los Angeles County, CA", "Kings County, NY" ].freeze

    def execute(candidate_name)
      names_future = Temporalio::Workflow::Future.new do
        Temporalio::Workflow.execute_activity(
          Activities::FindFormerNamesActivity, candidate_name, start_to_close_timeout: 30
        )
      end
      jurisdictions_future = Temporalio::Workflow::Future.new do
        Temporalio::Workflow.execute_activity(
          Activities::FindJurisdictionsActivity, candidate_name, start_to_close_timeout: 30
        )
      end
      Temporalio::Workflow::Future.all_of(names_future, jurisdictions_future).wait

      search_futures = ALIASES.product(JURISDICTIONS).map do |alias_name, jurisdiction|
        Temporalio::Workflow::Future.new do
          Temporalio::Workflow.execute_activity(
            Activities::SendSearchActivity, alias_name, jurisdiction, start_to_close_timeout: 30
          )
        end
      end
      Temporalio::Workflow::Future.all_of(*search_futures).wait
      search_results = search_futures.map(&:result)

      evaluation = Temporalio::Workflow.execute_activity(
        Activities::EvaluateResultsActivity, search_results, start_to_close_timeout: 30
      )
      comparison = Temporalio::Workflow.execute_activity(
        Activities::CompareCustomerAssessmentsActivity, evaluation, start_to_close_timeout: 30
      )
      candidate_story = Temporalio::Workflow.execute_activity(
        Activities::RequestCandidateStoryActivity, candidate_name, start_to_close_timeout: 30
      )
      notification = Temporalio::Workflow.execute_activity(
        Activities::NotifyCustomerAndCandidateActivity, candidate_name, start_to_close_timeout: 30
      )
      # Routed to a separate task queue polled by the Rust worker
      # (rust-worker/), not the Ruby one -- see README for why both workers
      # need to be running for this step to complete.
      dispute_handling = Temporalio::Workflow.execute_activity(
        Activities::HandlePossibleFcraDisputeActivity, candidate_name,
        task_queue: "background-check-rust", start_to_close_timeout: 30
      )

      {
        former_names: names_future.result,
        jurisdictions: jurisdictions_future.result,
        search_results:,
        evaluation:,
        comparison:,
        candidate_story:,
        notification:,
        dispute_handling:
      }
    end
  end
end
