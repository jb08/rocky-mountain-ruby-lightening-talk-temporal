module Activities
  # Still registered on the Ruby worker for reference, but the workflow
  # currently routes this step's task queue to rust-worker/ instead -- see
  # its implementation there for the version that actually runs.
  class HandlePossibleFcraDisputeActivity < Temporalio::Activity::Definition
    def execute(candidate_name)
      "FCRA dispute check for #{candidate_name}: no dispute filed, process complete"
    end
  end
end
