class ScoreRecord < ApplicationRecord
  belongs_to :user
  belongs_to :pull_request
  
  validates :user_id, presence: true
  validates :pull_request_id, presence: true
  validates :points, presence: true, numericality: { greater_than_or_equal_to: 0 }
  
end
