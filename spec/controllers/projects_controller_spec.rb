require 'rails_helper'

describe ProjectsController, type: :request do
  describe "#create" do
    context "when logged in" do
      before do
        @picture = Rack::Test::UploadedFile.new(Rails.root.join('spec', 'fixtures', 'photo.png'), 'image/png')
        @user = FactoryGirl.create(:user, email: Faker::Internet.email, name: Faker::Name.name, confirmed_at: Time.now)
        login_as(@user, :scope => :user, :run_callbacks => false)
      end

      context 'success' do
        before do
          post '/projects', { project: { title: 'Test Proj', short_description: 'short descr', country: 'Toronto, ON, Canada', picture: @picture } }
        end

        it 'returns 302' do
          expect(response.status).to eq 302
        end

        it 'doing redirect' do
          follow_redirect!
          expect(response).to redirect_to("/projects/#{Project.last.id}/taskstab")
        end
      end

      context 'fail' do
        before do
          allow_any_instance_of(User).to receive(:assign_address).and_return(true)
        end

        context 'validates min length - 2 chars' do
          before do
            post '/projects', { project: { title: 'Test Proj 2', short_description: 'ab', country: 'Toronto, ON, Canada', picture: @picture } }
          end

          it 'returns 200' do
            expect(response.status).to eq 200
          end

          it 'assigns project errors' do
            expect(response).to render_template(:new)
            expect(controller.instance_variable_get('@project').errors.full_messages.to_sentence).to eq 'Short description Has invalid length. Min length is 3, max length is 250'
          end
        end

        context 'validates min length - 0 chars' do
          before do
            post '/projects', { project: { title: 'Test Proj 2', short_description: '', country: 'Toronto, ON, Canada', picture: @picture } }
          end

          it 'returns 200' do
            expect(response.status).to eq 200
          end

          it 'assigns project errors' do
            expect(response).to render_template(:new)
            expect(controller.instance_variable_get('@project').errors.full_messages.to_sentence).to eq 'Short description can\'t be blank and Short description Has invalid length. Min length is 3, max length is 250'
          end
        end

        context 'validates max length' do
          before do
            post '/projects', { project: { title: 'Test Proj 2', short_description: Faker::Lorem.sentence(251), country: 'Toronto, ON, Canada', picture: @picture } }
          end

          it 'returns 200' do
            expect(response.status).to eq 200
          end

          it 'assigns project errors' do
            expect(response).to render_template(:new)
            expect(controller.instance_variable_get('@project').errors.full_messages.to_sentence).to eq 'Short description Has invalid length. Min length is 3, max length is 250'
          end
        end

        context 'validates max length - too many chars' do
          before do
            post '/projects', { project: { title: 'Test Proj 2', short_description: Faker::Lorem.sentence(450), country: 'Toronto, ON, Canada', picture: @picture } }
          end

          it 'returns 200' do
            expect(response.status).to eq 200
          end

          it 'assigns project errors' do
            expect(response).to render_template(:new)
            expect(controller.instance_variable_get('@project').errors.full_messages.to_sentence).to eq 'Short description Has invalid length. Min length is 3, max length is 250'
          end
        end
      end
    end
  end
end
