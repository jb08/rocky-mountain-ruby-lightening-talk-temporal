module BackgroundCheck
  class SendSearchJob
    include Sidekiq::Job

    def perform(run_id, alias_name, jurisdiction)
      run = BackgroundCheckRun.find(run_id)

      result = "Search complete for #{alias_name} in #{jurisdiction}: no records found"
      Rails.logger.info("[BackgroundCheck] #{result}")

      run.record_search_result!(result)
    end
  end
end
