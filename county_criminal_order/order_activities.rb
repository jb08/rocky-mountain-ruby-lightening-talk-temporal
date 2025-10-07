# frozen_string_literal: true

require 'temporalio/activity'

module CountyCriminalOrder
  module Activities
    class SendNotification < Temporalio::Activity::Definition
      def execute
        puts 'Sending notification to candidate'
        { status: 'sent', timestamp: Time.now }
      end
    end

    class ComputeAliases < Temporalio::Activity::Definition
      def execute
        puts 'Computing aliases'
        aliases = ['Foo Bar', 'F. Bar', 'Bar Baz']
        { aliases: aliases }
      end
    end

    class FindCountiesToSearch < Temporalio::Activity::Definition
      def execute
        puts 'Finding counties to search'
        counties = ['Denver County', 'Cook County', 'Sheridan County']
        { counties: counties }
      end
    end

    class SendOrder < Temporalio::Activity::Definition
      def execute(_)
        puts 'Sending order to county furnisher for alias'
        { order_id: "ORD-#{Time.now.to_i}", status: 'submitted' }
      end
    end

    class ParseResults < Temporalio::Activity::Definition
      def execute
        puts 'Parsing order results'
        records = [{ charges: ['trespassing'], disposition: 'dismissed' }]
        { records: records }
      end
    end

    class BillCustomer < Temporalio::Activity::Definition
      def execute
        puts 'Billing customer'
        { invoice_id: "INV-#{Time.now.to_i}", amount: 25.00, status: 'billed' }
      end
    end

    class Assess < Temporalio::Activity::Definition
      def execute(records)
        puts 'Assessing filtering for results'
        filtered_out_records = []
        { medical_accreditation: true, mvr_license: { status: 'valid', exp: '2027' }, drug_test: true,
          filtered_out_records: }
      end
    end
  end
end
