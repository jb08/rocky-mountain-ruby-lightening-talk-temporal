module Activities
  class NotifyCustomerAndCandidateActivity < Temporalio::Activity::Definition
    def execute(candidate_name)
      "Notified customer and #{candidate_name}: report is complete and available"
    end
  end
end
