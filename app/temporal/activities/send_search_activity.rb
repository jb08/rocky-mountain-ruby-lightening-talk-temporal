module Activities
  class SendSearchActivity < Temporalio::Activity::Definition
    def execute(alias_name, jurisdiction)
      # raise "my data furnisher API server error here"

      "Search complete for #{alias_name} in #{jurisdiction}: no records found"
    end
  end
end
