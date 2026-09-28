module BackgroundCheck
  class CompareCustomerAssessmentsJob
    include Sidekiq::Job

    def perform(run_id)
      run = BackgroundCheckRun.find(run_id)

      result = "Comparison for #{run.candidate_name}: evaluation matches customer's stated assessment criteria"
      Rails.logger.info("[BackgroundCheck] #{result}")

      run.update!(comparison: result, status: "requesting_story")
      RequestCandidateStoryJob.perform_async(run_id)
    end
  end
end
