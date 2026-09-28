class TemporalBackgroundChecksController < ApplicationController
  STATUS_NAMES = {
    Temporalio::Client::WorkflowExecutionStatus::RUNNING => "running",
    Temporalio::Client::WorkflowExecutionStatus::COMPLETED => "completed",
    Temporalio::Client::WorkflowExecutionStatus::FAILED => "failed",
    Temporalio::Client::WorkflowExecutionStatus::CANCELED => "canceled",
    Temporalio::Client::WorkflowExecutionStatus::TERMINATED => "terminated",
    Temporalio::Client::WorkflowExecutionStatus::CONTINUED_AS_NEW => "continued_as_new",
    Temporalio::Client::WorkflowExecutionStatus::TIMED_OUT => "timed_out"
  }.freeze

  def create
    candidate_name = params[:candidate_name].presence || "Jamie Rivera"
    workflow_id = "background-check-#{SecureRandom.uuid}"

    handle = temporal_client.start_workflow(
      Workflows::BackgroundCheckWorkflow,
      candidate_name,
      id: workflow_id,
      task_queue: "background-check"
    )

    render json: { workflow_id: handle.id, run_id: handle.result_run_id }, status: :created
  end

  def show
    handle = temporal_client.workflow_handle(params[:id])
    description = handle.describe
    status = STATUS_NAMES.fetch(description.status, description.status)

    payload = { workflow_id: params[:id], status: }
    payload[:result] = handle.result if status == "completed"

    render json: payload
  end

  private

  def temporal_client
    @temporal_client ||= Temporalio::Client.connect(
      ENV.fetch("TEMPORAL_ADDRESS", "localhost:7233"),
      ENV.fetch("TEMPORAL_NAMESPACE", "default")
    )
  end
end
