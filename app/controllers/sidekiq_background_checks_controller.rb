class SidekiqBackgroundChecksController < ApplicationController
  def create
    run = BackgroundCheckRun.create!(candidate_name: params[:candidate_name].presence || "Jamie Rivera")
    BackgroundCheck::BackgroundCheckOrchestratorJob.perform_async(run.id)

    render json: run, status: :created
  end

  def show
    render json: BackgroundCheckRun.find(params[:id])
  end
end
