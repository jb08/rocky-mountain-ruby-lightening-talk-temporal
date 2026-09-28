module Activities
  class FindFormerNamesActivity < Temporalio::Activity::Definition
    def execute(candidate_name)
      "Found former names for #{candidate_name}: Jane A. Smith, Jane Doe"
    end
  end
end
