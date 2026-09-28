module BackgroundCheck
  class NotifyCustomerAndCandidateJob
    include Sidekiq::Job

    def perform(run_id)
      run = BackgroundCheckRun.find(run_id)

      result = "Notified customer and #{run.candidate_name}: report is complete and available"
      Rails.logger.info("[BackgroundCheck] #{result}")

      run.update!(notification: result, status: "handling_dispute")
      HandlePossibleFcraDisputeJob.perform_async(run_id)
    end
  end
end
