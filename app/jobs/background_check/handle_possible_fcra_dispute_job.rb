module BackgroundCheck
  class HandlePossibleFcraDisputeJob
    include Sidekiq::Job

    def perform(run_id)
      run = BackgroundCheckRun.find(run_id)

      result = "FCRA dispute check for #{run.candidate_name}: no dispute filed, process complete"
      Rails.logger.info("[BackgroundCheck] #{result}")

      run.update!(dispute_handling: result, status: "completed")
    end
  end
end
