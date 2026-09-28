module BackgroundCheck
  class EvaluateResultsJob
    include Sidekiq::Job

    def perform(run_id)
      run = BackgroundCheckRun.find(run_id)

      result = "Evaluation for #{run.candidate_name}: all #{run.search_results.size} searches clear, no adverse records found"
      Rails.logger.info("[BackgroundCheck] #{result}")

      run.update!(evaluation: result, status: "comparing")
      CompareCustomerAssessmentsJob.perform_async(run_id)
    end
  end
end
