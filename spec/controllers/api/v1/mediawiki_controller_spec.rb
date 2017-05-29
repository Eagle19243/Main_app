require 'rails_helper'

RSpec.describe Api::V1::MediawikiController, type: :controller do
  let(:user) { FactoryGirl.create(:user) }
  let(:project) { FactoryGirl.create(:project) }

  describe 'POST /api/v1/mediawiki/page_edited' do
    it 'Sends a request with correct params' do
      post :page_edited, xhr: true, secret: ENV['mediawiki_api_secret'], type: "edit", data: "{\"page_name\": \"#{project.title}\", \"editor_name\": \"#{user.username}\", \"time\": 123134324, \"approved\": false}"
      json = ActiveSupport::JSON.decode(response.body)
      expect(json["status"]).to eq("200 OK")
    end

    it 'Sends a request with wrong secret' do
      post :page_edited, xhr: true, secret: "WrongKey123", type: "edit", data: "{\"page_name\": \"#{project.title}\", \"editor_name\": \"#{user.username}\", \"time\": 123134324, \"approved\": false}"
      expect(response.status).to eq(401)
    end

    it 'Sends a request with unkonwn type' do
      post :page_edited, xhr: true, secret: ENV['mediawiki_api_secret'], type: "unkonwnType", data: "{\"page_name\": \"#{project.title}\", \"editor_name\": \"#{user.username}\", \"time\": 123134324, \"approved\": false}"
      expect(response.status).to eq(400)
    end

    it 'Sends a request with non existing user' do
      post :page_edited, xhr: true, secret: ENV['mediawiki_api_secret'], type: "edit", data: "{\"page_name\": \"#{project.title}\", \"editor_name\": \"noone\", \"time\": 123134324, \"approved\": false}"
      expect(response.status).to eq(404)
    end
  end

end
