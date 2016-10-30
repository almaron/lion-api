class CreateScoreRecords < ActiveRecord::Migration[5.0]
  def change
    create_table :score_records do |t|
      t.integer :user_id, null: false
      t.integer :pull_request_id, null: false
      t.integer :points, default: 0
      t.date_time :time
    end
  end
end
