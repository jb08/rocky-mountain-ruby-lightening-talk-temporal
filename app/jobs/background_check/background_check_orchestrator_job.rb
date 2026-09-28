module BackgroundCheck
  class BackgroundCheckOrchestratorJob
    include Sidekiq::Job

    def perform(run_id)
      run = BackgroundCheckRun.find(run_id)
      run.update!(status: "finding_names_and_jurisdictions")

      FindFormerNamesJob.perform_async(run_id)
      FindJurisdictionsJob.perform_async(run_id)
    end
  end
end
