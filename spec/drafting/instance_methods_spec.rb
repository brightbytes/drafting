require 'spec_helper'

describe Drafting::InstanceMethods do
  let(:user) { FactoryGirl.create(:user) }
  let(:topic) { FactoryGirl.create(:topic) }
  let(:message) { topic.messages.build :user => user, :content => 'foo' }
  let(:page) { Page.new :title => 'First post' }

  describe 'save_draft' do
    it 'should store Draft object for user' do
      expect {
        result = message.save_draft(user)

        expect(result).to eq(true)
        expect(message.draft_id).to be_a(Integer)
      }.to change(Draft, :count).by(1)

      draft = Draft.find(message.draft_id)
      expect(draft.target_type).to eq('Message')
      expect(draft.parent_id).to eq(topic.id)
      expect(draft.parent_type).to eq('Topic')
      expect(draft.user_id).to eq(user.id)
      expect(draft.data).to eq('content' => 'foo', 'topic_id' => topic.id, 'user_id' => user.id)

      expect(topic.drafts).to eq([draft])
    end

    it 'should store Draft object without user' do
      expect {
        result = page.save_draft

        expect(result).to eq(true)
      }.to change(Draft, :count).by(1)

      draft = Draft.find(page.draft_id)
      expect(draft.user_id).to eq(nil)
    end

    it 'should store extra attributes to Draft' do
      message.priority = 5
      message.save_draft(user)

      draft = Draft.find(message.draft_id)
      expect(draft.data['priority']).to eq(5)
    end

    it 'should update existing Draft object' do
      message.save_draft(user)

      message.content = 'bar'
      expect {
        message.save_draft(user)
      }.to_not change(Draft, :count)

      draft = Draft.find(message.draft_id)
      expect(draft.data).to eq('content' => 'bar', 'topic_id' => topic.id, 'user_id' => user.id)
    end

    it 'should fail after real save' do
      message.save_draft(user)

      message.save!

      expect(message.save_draft(user)).to eq(false)
    end
  end

  describe 'update_draft' do
    it 'should update existing Draft object' do
      message.save_draft(user)

      expect {
        message.update_draft(user, :content => 'bar')
      }.to_not change(Draft, :count)

      draft = Draft.find(message.draft_id)
      expect(draft.data).to eq('content' => 'bar', 'topic_id' => topic.id, 'user_id' => user.id)
    end
  end

  describe 'clear_draft' do
    before(:each) { message.save_draft(user) }

    it 'should remove Draft object on immediate save' do
      expect {
        message.save!
      }.to change(Draft, :count).by(-1)

      expect(message.draft_id).to eq(nil)
    end

    it 'should remove Draft object on later save' do
      new_message = Message.from_draft(message.draft_id)

      expect {
        new_message.save!
      }.to change(Draft, :count).by(-1)

      expect(new_message.draft_id).to eq(nil)
    end
  end
end