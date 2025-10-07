# frozen_string_literal: true

require 'temporalio/workflow'
require_relative 'order_activities'

module CountyCriminalOrder
  class OrderWorkflow < Temporalio::Workflow::Definition
    def execute(_)
      @duration_options = { start_to_close_timeout: 5 * 60 }

      aliases = Temporalio::Workflow.execute_activity(Activities::ComputeAliases, **@duration_options)
      counties = Temporalio::Workflow.execute_activity(Activities::FindCountiesToSearch, **@duration_options)

      counties.each do |county|
        Temporalio::Workflow.execute_activity(Activities::SendOrder, { aliases:, county: }, **@duration_options)
      end

      records = Temporalio::Workflow.execute_activity(Activities::ParseResults, **@duration_options)

      Temporalio::Workflow.execute_activity(Activities::BillCustomer, **@duration_options)

      filtered_out_records = Temporalio::Workflow.execute_activity(Activities::Assess, records, **@duration_options)

      Temporalio::Workflow.execute_activity(Activities::SendNotification, **@duration_options)

      filtered_out_records
    end
  end
end
