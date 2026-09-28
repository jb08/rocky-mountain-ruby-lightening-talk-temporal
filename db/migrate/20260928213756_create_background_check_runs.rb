class CreateBackgroundCheckRuns < ActiveRecord::Migration[8.0]
  def change
    create_table :background_check_runs do |t|
      t.string :candidate_name, null: false
      t.string :status, null: false, default: "pending"
      t.jsonb :aliases, null: false, default: []
      t.jsonb :jurisdictions, null: false, default: []
      t.jsonb :search_results, null: false, default: []
      t.integer :searches_expected, null: false, default: 0
      t.integer :searches_completed, null: false, default: 0
      t.boolean :searches_started, null: false, default: false
      t.text :evaluation
      t.text :comparison
      t.text :candidate_story
      t.text :notification
      t.text :dispute_handling

      t.timestamps
    end
  end
end
