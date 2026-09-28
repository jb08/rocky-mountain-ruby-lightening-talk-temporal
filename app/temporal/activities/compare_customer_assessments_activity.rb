module Activities
  class CompareCustomerAssessmentsActivity < Temporalio::Activity::Definition
    def execute(evaluation)
      "Comparison: evaluation matches customer's stated assessment criteria (#{evaluation})"
    end
  end
end
