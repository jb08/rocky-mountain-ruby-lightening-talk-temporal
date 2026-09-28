module BackgroundCheck
  class FindJurisdictionsJob
    include Sidekiq::Job

    def perform(run_id)
      run = BackgroundCheckRun.find(run_id)

      result = "Jurisdictions to search for #{run.candidate_name}: Los Angeles County CA, Kings County NY"
      Rails.logger.info("[BackgroundCheck] #{result}")

      run.record_jurisdictions!([ "Los Angeles County, CA", "Kings County, NY" ])
    end
  end
end
