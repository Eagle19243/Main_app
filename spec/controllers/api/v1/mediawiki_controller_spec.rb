require 'rails_helper'

RSpec.describe Api::V1::MediawikiController, type: :controller do
  let(:username) { FactoryGirl.create(:user).username }
  let(:project) { FactoryGirl.create(:project) }
  let(:secret) { ENV['mediawiki_api_secret'] }
  let(:type) { 'edit' }
  let(:info) { "{'secret':'#{secret}',
                 'type': '#{type}',
                 'data':
                    {'page_name':'#{project.title}',
                     'editor_name': '#{username}',
                     'time': 123134324,
                     'approved': false  }
                }" 
              }
  let(:params) do
    {
      xhr: true,
      info: info
    }
  end

  describe 'POST /api/v1/mediawiki/page_edited' do
    subject { response.status }
    before { post :page_edited, params }

    context 'Sends a request with correct params' do
      it { is_expected.to eq(200) }
    end

    context 'Sends a request with wrong secret' do
      let(:secret) { 'WrongKey123' }
      it { is_expected.to eq(401) }
    end

    context 'Sends a request with unkonwn type' do
      let(:type) { 'unkonwnType' }
      it { is_expected.to eq(400) }
    end

    context 'Sends a request with non existing user' do
      let(:username) { 'noone' }
      it { is_expected.to eq(404) }
    end

    context 'Sends a request with non existing project' do
      let(:username) { 'nothing' }
      it { is_expected.to eq(404) }
    end

    context 'Sends invalid info' do
      let(:info) { "invalid" }
      it { is_expected.to eq(400) }
    end

  end
end
