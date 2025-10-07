# frozen_string_literal: true

require 'temporalio/client'
require_relative 'order_workflow'

# Create a client
client = Temporalio::Client.connect('localhost:7233', 'default')

# Run workflow
puts 'Executing workflows'

3.times do
  client.execute_workflow(
    CountyCriminalOrder::OrderWorkflow,
    { name: 'Jason Brown', ssn_last_four: 'XXXX', current_county: 'Denver', screenings: ['criminal', 'motor_vehicle_check', 'drug_test', 'medical_accreditation' ] },
    id: SecureRandom.hex(8),
    task_queue: 'county-criminal-order'
  )
end