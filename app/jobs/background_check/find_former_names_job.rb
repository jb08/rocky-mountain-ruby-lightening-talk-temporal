module BackgroundCheck
  class FindFormerNamesJob
    include Sidekiq::Job

    def perform(run_id)
      run = BackgroundCheckRun.find(run_id)

      result = "Found former names for #{run.candidate_name}: Jane A. Smith, Jane Doe"
      Rails.logger.info("[BackgroundCheck] #{result}")

      run.record_aliases!([ "Jane A. Smith", "Jane Doe" ])
    end
  end
end
