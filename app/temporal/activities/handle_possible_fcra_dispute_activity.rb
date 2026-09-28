module Activities
  class HandlePossibleFcraDisputeActivity < Temporalio::Activity::Definition
    def execute(candidate_name)
      "FCRA dispute check for #{candidate_name}: no dispute filed, process complete"
    end
  end
end
