# == Schema Information
#
# Table name: users
#
#  id         :uuid             not null, primary key
#  name       :string(255)
#  nickname   :string(255)
#  email      :string(255)
#  avatar_url :string(255)
#  api_token  :string(255)
#  github_id  :string(255)
#  created_at :datetime
#  updated_at :datetime
#  points     :integer          default(0)
#

require 'spec_helper'

describe User do
  describe '#self.find_or_create_from_auth_hash', :vcr do
    it 'creates a new user from github credentials' do
      user = User.find_or_create_from_auth_hash(matteo_auth_hash)

      user.name.should eq('Matteo Depalo')
      user.email.should eq('matteodepalo@gmail.com')
      user.api_token.should eq('78f58e63e8035da8e50970736e71f592c8b3513f')
      user.avatar_url.should eq('https://gravatar.com/avatar/abb04b4653729868f052994150255f97?d=https%3A%2F%2Fidenticons')
      user.github_id.should eq('151725')
      user.nickname.should eq('matteodepalo')
    end

    it 'updates infos about a github user already in the database' do
      user = User.find_or_create_from_auth_hash(matteo_auth_hash)
      user.name.should eq('Matteo Depalo')
      id = user.id

      user = User.find_or_create_from_auth_hash(matteo_auth_hash.deep_merge!('info' => { 'name' => 'Ciccio Depalo' }))
      user.name.should eq('Ciccio Depalo')
      user.id.should eq(id)
    end
  end
end
