require "test_helper"

class BackgroundCheckRunTest < ActiveSupport::TestCase
  setup do
    Sidekiq::Job.clear_all
    @run = BackgroundCheckRun.create!(candidate_name: "Jamie Rivera")
  end

  test "does not start searches until both aliases and jurisdictions are recorded" do
    @run.record_aliases!([ "Jane Doe" ])

    assert_not @run.reload.searches_started?
    assert_empty BackgroundCheck::SendSearchJob.jobs
  end

  test "starts one search per alias/jurisdiction combination once both sides are in" do
    @run.record_aliases!([ "Jane Doe", "Jane Smith" ])
    @run.record_jurisdictions!([ "Los Angeles County, CA", "Kings County, NY" ])

    @run.reload
    assert @run.searches_started?
    assert_equal 4, @run.searches_expected
    assert_equal 4, BackgroundCheck::SendSearchJob.jobs.size
  end

  test "only enqueues the evaluation job once every search result is in" do
    @run.update!(searches_started: true, searches_expected: 2, status: "searching")

    @run.record_search_result!("first result")
    assert_empty BackgroundCheck::EvaluateResultsJob.jobs
    assert_equal "searching", @run.reload.status

    @run.record_search_result!("second result")
    assert_equal 1, BackgroundCheck::EvaluateResultsJob.jobs.size
    assert_equal "evaluating", @run.reload.status
    assert_equal [ "first result", "second result" ], @run.search_results
  end
end
