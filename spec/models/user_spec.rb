require 'spec_helper'

describe User do
  describe "#access_token" do
    it "returns the first active access token" do
      user = build(:user)
      active_access_token = create(:access_token, :active, user: user)

      expect(user.access_token).to eq active_access_token
    end

    it "does not return inactive access tokens" do
      user = build(:user)
      create(:access_token, :inactive, user: user)

      expect(user.access_token).to eq nil
    end
  end
end
