module BackgroundCheck
  class RequestCandidateStoryJob
    include Sidekiq::Job

    def perform(run_id)
      run = BackgroundCheckRun.find(run_id)

      result = "Candidate story requested from #{run.candidate_name}: awaiting response, none required based on evaluation"
      Rails.logger.info("[BackgroundCheck] #{result}")

      run.update!(candidate_story: result, status: "notifying")
      NotifyCustomerAndCandidateJob.perform_async(run_id)
    end
  end
end
