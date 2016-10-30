class PointsMarshaler
  MATCHING_REGEX = /paired[\s]*with[\s]*(?<names>[@\w+[-]?[\s+|,&]]+)/i
  SPLITTING_REGEX = /,|\.|\s+/

  def initialize(data:)
    @data = data
  end

  attr_accessor :data

  def marshal
    pull_request = PullRequest.create(data)

    if pull_request.valid?
      create_pairings(pull_request)
      create_reviews(pull_request)
      pull_request
    end
  rescue ActiveRecord::RecordNotUnique => e
    Honeybadger.notify(e, context: data)
    nil
  end

  private

  def create_reviews(pr)
    review_points = (pr.points / 2).round
    pr.comments.each do |c|
      user = User.where(nickname: c.user.login).first
      review = PullRequestReview.create(user: user, body: c.body, pull_request: pr)

      if review.valid?
        Score.give(time: pr.merged_at, user: user, points: review_points)
        ScoreRecord.create user: user, pull_request: pr, points: review_points, time: pr.merged_at
      end
    end
  end

  def create_pairings(pr)
    pair_points = (pr.points / pairers.count).round
    pairers.each do |u|
      pairing = Pairing.create(user: u, pull_request: pr)

      if pairing.valid?
        Score.give(time: pr.merged_at, user: u, points: pair_points)
        ScoreRecord.create user: u, pull_request: pr, points: pair_points, time: pr.merged_at
      end
    end
  end

  def pairers
    query = [data[:user].nickname]
    if match_pairers.present?
      query += sanitize_pairs
    end
    User.where(nickname: query)
  end

  def sanitize_pairs
    match_pairers[:names].split(SPLITTING_REGEX).select do |p|
      p.include?('@')
    end.map{ |p| p.delete('@') }
  end

  def match_pairers
    @match_pairers ||= data[:body]&.match(MATCHING_REGEX)
  end
end
