module Activities
  class FindJurisdictionsActivity < Temporalio::Activity::Definition
    def execute(candidate_name)
      "Jurisdictions to search for #{candidate_name}: Los Angeles County CA, Kings County NY"
    end
  end
end
