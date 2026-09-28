module Activities
  class RequestCandidateStoryActivity < Temporalio::Activity::Definition
    def execute(candidate_name)
      "Candidate story requested from #{candidate_name}: awaiting response, none required based on evaluation"
    end
  end
end
