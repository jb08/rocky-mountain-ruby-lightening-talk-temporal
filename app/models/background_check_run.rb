class BackgroundCheckRun < ApplicationRecord
  def record_aliases!(aliases)
    update!(aliases: aliases)
    maybe_start_searches!
  end

  def record_jurisdictions!(jurisdictions)
    update!(jurisdictions: jurisdictions)
    maybe_start_searches!
  end

  # Called from both FindFormerNamesJob and FindJurisdictionsJob once each
  # finishes. Whichever of the two finishes second is the one that actually
  # fans out the search loop -- the row lock is what makes that safe.
  #
  # The enqueue calls happen *after* with_lock returns (i.e. after its
  # transaction commits) -- enqueuing from inside the transaction risks the
  # job being picked up by another worker before the row update is visible,
  # which would make it read stale data.
  def maybe_start_searches!
    combinations = nil

    with_lock do
      next if searches_started? || aliases.blank? || jurisdictions.blank?

      combinations = aliases.product(jurisdictions)
      update!(searches_started: true, searches_expected: combinations.size, status: "searching")
    end

    combinations&.each do |alias_name, jurisdiction|
      BackgroundCheck::SendSearchJob.perform_async(id, alias_name, jurisdiction)
    end
  end

  def record_search_result!(result)
    all_searches_complete = false

    with_lock do
      update!(search_results: search_results + [ result ], searches_completed: searches_completed + 1)

      all_searches_complete = searches_completed == searches_expected
      update!(status: "evaluating") if all_searches_complete
    end

    BackgroundCheck::EvaluateResultsJob.perform_async(id) if all_searches_complete
  end
end
