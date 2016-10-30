class User < ActiveRecord::Base
  has_many :pull_requests
  has_many :scores
  has_many :score_records, dependent: :destroy
  has_many :pull_request_reviews
  has_many :weekly_winnings
  has_many :access_tokens, dependent: :destroy
  has_many :pairings

  validates :name, presence: true
  validates :nickname, presence: true
  validates :email, presence: true
  validates :avatar_url, presence: true
  validates :github_id, presence: true
  validates :api_token, presence: true

  class_attribute :current_client_index

  def access_token
    access_tokens.active.first
  end

  def self.find_or_create_from_oauth(oauth, token)
    user = where(github_id: oauth.id.to_s).first
    info = {
      name: oauth.name,
      github_id: oauth.id.to_s,
      nickname: oauth.login,
      email: oauth.email,
      avatar_url: oauth.avatar_url,
      api_token: token
    }

    if user
      user.update!(info)
    else
      user = create_from_github(info, token)
    end

    user
  end

  def github_client
    @github_client ||= self.class.github_client(api_token)
  end

  def self.github_client(token)
    client = Octokit::Client.new(access_token: token)
    client.user.login
    client
  end

  def self.create_from_github(info, token)
    if github_client(token).organizations.map(&:login).include?(ENV['ORGANIZATION_NAME'])
      create!(info)
    else
      nil
    end
  end

  def self.global_client
    self.current_client_index ||= 0
    client = clients[current_client_index]

    if client.rate_limit[:remaining] < 100
      self.current_client_index += 1
      client = clients[current_client_index]
    else
      client
    end
  end

  def self.clients
    @clients ||= User.where(nickname: self.active.map(&:nickname)).map(&:github_client)
  end

  def self.active
    AccessToken.active.map(&:user)
  end
end
