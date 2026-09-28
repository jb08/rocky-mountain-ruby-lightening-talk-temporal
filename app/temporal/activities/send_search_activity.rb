module Activities
  class SendSearchActivity < Temporalio::Activity::Definition
    def execute(alias_name, jurisdiction)
      "Search complete for #{alias_name} in #{jurisdiction}: no records found"
    end
  end
end
