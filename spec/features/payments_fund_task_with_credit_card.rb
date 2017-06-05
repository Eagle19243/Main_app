require 'rails_helper'

feature 'Project Page Plan Tab', js: true do
  let(:stripe_helper) { StripeMock.create_test_helper }
  let!(:user)         { create(:user, :confirmed_user, :with_wallet) }
  let!(:project)      { create(:project, user: user) }
  let!(:task)         { create(:task, :with_wallet, project: project) }

  before  { StripeMock.start }
  after   { StripeMock.stop }

  before do
    card_token = StripeMock.generate_card_token(last4: '4242', exp_year: 2.years.from_now.year)
    customer = Stripe::Customer.create(source: card_token)
    user.update(stripe_customer_id: customer.id)

    login_as(user, scope: :user, run_callbacks: false)
    visit taskstab_project_path(project, tab: 'tasks')
  end

  context 'when click on FUND' do
    let!(:fund_modal) do
      find('.tabs-wrapper__tasks .pr-card .fund-do-btns', match: :first).click_button 'FUND'
      find('#taskFundModal', visible: true)
    end

    scenario 'fund modal appears' do
      expect(fund_modal).to be_visible
    end

    context 'when donate with credit card' do
      let(:valid_card_number) { '4242424242424242' }

      before do
        # Ignore stubbing bitcoin request
        allow_any_instance_of(Task).to receive(:update_current_fund!).and_return(true)

        fund_modal.find('#donate-with-credit-card').click

        fund_modal.fill_in('amount', with: 100)
        fund_modal.fill_in('card_number', with: valid_card_number)
        fund_modal.fill_in('card_expiry', with: 2.years.from_now.strftime('%m/%Y'))
        fund_modal.fill_in('card_code', with: 211)
        fund_modal.find('#accept-term').trigger('click')
      end

      context 'when new card' do
        before do
          stripe_token = stripe_helper.generate_card_token(card_number: valid_card_number, card_expiry: 2.years.from_now.strftime('%m/%Y'), card_code: 211)
          script = "Stripe.card = { createToken: function(_ ,callback) { callback(_, {id: \"#{stripe_token}\"}); } }"
          page.evaluate_script(script)
        end

        context 'valid card' do
          scenario 'donate success' do
            successModal = find('#errorFundModal.success-fund-transfer', visible: true)

            fund_modal.first('button._donate').trigger('click')
            wait_for_ajax

            expect(successModal).to be_visible
            expect(successModal).to have_content('Success!')
            expect(StripePayment.last.amount).to eq(100)
          end
        end

        context 'invalid card' do
          scenario 'donate fail' do
            StripeMock.prepare_card_error(:invalid_number)
            errorModal = find('#errorFundModal', visible: true)

            fund_modal.first('button._donate').trigger('click')
            wait_for_ajax

            expect(errorModal).to be_visible
            expect(errorModal).to have_content('Error The card number is not a valid credit card number')
          end
        end

        context 'save card' do
          scenario 'card save success' do
            fund_modal.find('.payment-form__save-card').trigger('click')
            successModal = find('#errorFundModal.success-fund-transfer', visible: true)

            fund_modal.first('button._donate').trigger('click')
            wait_for_ajax
            user.reload

            saved_card = Payments::StripeSources.new.call(user: user)[0]

            expect(successModal).to be_visible
            expect(successModal).to have_content('Success!')
            expect(saved_card).not_to be_nil
            expect(saved_card[:last4]).to eq('4242')
          end
        end
      end

      context 'when saved card' do
        scenario 'takes fund from selected card' do
          fund_modal.choose('card-4242')
          fund_modal.fill_in('amount', with: 1000)
          successModal = find('#errorFundModal.success-fund-transfer', visible: true)

          fund_modal.first('button._donate').trigger('click')

          expect(successModal).to be_visible
          expect(successModal).to have_content('Success!')
          expect(StripePayment.last.amount).to eq(1000)
        end
      end
    end
  end
end
