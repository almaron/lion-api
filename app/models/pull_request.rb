class PullRequest < ActiveRecord::Base
  belongs_to :user
  has_many :pull_request_reviews, dependent: :destroy
  has_many :pairings, dependent: :destroy
  has_many :score_records, dependent: :destroy

  validates :user, presence: true
  validates :number, presence: true, numericality: true
  validates :base_repo_full_name, presence: true
  validates :number_of_comments, presence: true, numericality: true
  validates :number_of_commits, presence: true, numericality: true
  validates :number_of_additions, presence: true, numericality: true
  validates :number_of_deletions, presence: true, numericality: true
  validates :number_of_changed_files, presence: true, numericality: true
  validates :merged_at, presence: true

  def points
    if number_of_deletions > 2 * number_of_additions && number_of_deletions > 1000
      100
    elsif number_of_additions > 500
      50
    elsif number_of_deletions > 2 * number_of_additions && number_of_deletions > 100
      30
    elsif number_of_additions > 100
      15
    elsif number_of_additions < 10
      5
    else
      10
    end
  end

  def comments
    @comments ||= User.global_client
      .pull_request(base_repo_full_name, number)
      .rels[:comments].get.data
  end
end
