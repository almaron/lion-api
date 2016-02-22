class PointsMarshaler
  MATCHING_REGEX = /paired[\s]*with[\s]*(?<names>[@\w+[\s+|,]]+)/i
  SPLITTING_REGEX = /,|\.|\s+/

  def initialize(data:)
    @data = data
  end

  attr_accessor :data

  def marshal
    if pull_request = PullRequest.create(data)
      create_pairings(pull_request)
      create_reviews(pull_request)
    end

    pull_request
  end

  private

  def create_reviews(pr)
    review_points = (pr.points / 2).round
    pr.comments.each do |c|
      user = User.where(nickname: c.user.login).first
      if PullRequestReview.create(user: user, body: c.body, pull_request: pr)
        Score.give(time: pr.merged_at, user: user, points: review_points)
      end
    end
  end

  def create_pairings(pr)
    pair_points = (pr.points / pairers.size).round
    pairers.each do |u|
      if Pairing.create(user: u, pull_request: pr)
        Score.give(time: pr.merged_at, user: u, points: pair_points)
      end
    end
  end

  def pairers
    @pairers ||= if match_pairers.present?
      User.where(nickname: sanitize_pairs.push(data[:user].nickname))
    else
      [data[:user]]
    end
  end

  def sanitize_pairs
    match_pairers[:names].split(SPLITTING_REGEX).select do |p|
      p.include?('@')
    end.map{ |p| p.delete('@') }
  end

  def match_pairers
    @match_pairers ||= data[:body].match(MATCHING_REGEX)
  end
end
