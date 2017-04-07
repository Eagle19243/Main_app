require 'rails_helper'

RSpec.describe ProjectRequestsService do
  let(:task) { create(:task, :with_associations) }
  let(:project) { task.project }
  let(:subject) { described_class.new(project) }

  # create not-pending do requests and apply requests
  before do
    create(:do_request, task: task, project: project, state: 'accepted')
    create(:do_request, task: task, project: project, state: 'rejected')
    create(:lead_editor_request, project: project, accepted_at: Time.now)
    create(:lead_editor_request, project: project, rejected_at: Time.now)
    create(:coordinator_request, project: project, accepted_at: Time.now)
    create(:coordinator_request, project: project, rejected_at: Time.now)
  end

  it 'returns 0 when there is no requests in the project' do
    expect(subject.requests_count).to eq(0)
  end

  context "when pending do requests exist in the project" do
    before do
      @do_requests = create_list(:do_request, 2, task: task, project: project)
    end

    describe "#requests_count" do
      it 'calculates requests_count' do
        expect(subject.requests_count).to eq(2)
      end
    end

    describe "#pending_do_requests" do
      it do
        expect(subject.pending_do_requests.to_a.sort).to eq(@do_requests.sort)
      end
    end

    describe "#pending_apply_requests" do
      it do
        expect(subject.pending_apply_requests).to eq([])
      end
    end
  end

  context "when pending application requests exist in the project" do
    before do
      @apply_requests = []
      @apply_requests << create_list(:lead_editor_request, 2, project: project)
      @apply_requests << create_list(:coordinator_request, 3, project: project)
      @apply_requests.flatten!
    end

    describe "#requests_count" do
      it 'calculates requests_count' do
        expect(subject.requests_count).to eq(5)
      end
    end

    describe "#pending_do_requests" do
      it do
        expect(subject.pending_do_requests).to eq([])
      end
    end

    describe "#pending_apply_requests" do
      it do
        expect(subject.pending_apply_requests.to_a.sort).to eq(@apply_requests.sort)
      end
    end
  end

  context "when both pending do requests and application requests exist in the project" do
    before do
      @do_requests = create_list(:do_request, 2, task: task, project: project)
      @apply_requests = []
      @apply_requests << create_list(:lead_editor_request, 2, project: project)
      @apply_requests << create_list(:coordinator_request, 3, project: project)
      @apply_requests.flatten!
    end

    describe "#requests_count" do
      it 'calculates requests_count' do
        expect(subject.requests_count).to eq(7)
      end
    end

    describe "#pending_do_requests" do
      it do
        expect(subject.pending_do_requests.to_a.sort).to eq(@do_requests.sort)
      end
    end

    describe "#pending_apply_requests" do
      it do
        expect(subject.pending_apply_requests.to_a.sort).to eq(@apply_requests.sort)
      end
    end
  end
end
