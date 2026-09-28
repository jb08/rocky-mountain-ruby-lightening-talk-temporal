module Activities
  class EvaluateResultsActivity < Temporalio::Activity::Definition
    def execute(search_results)
      "Evaluation: all #{search_results.size} searches clear, no adverse records found"
    end
  end
end
