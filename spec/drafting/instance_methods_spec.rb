require 'spec_helper'

describe Drafting::InstanceMethods do
  let(:user) { FactoryBot.create(:user) }
  let(:other_user) { FactoryBot.create(:user) }
  let(:topic) { FactoryBot.create(:topic) }
  let(:message) { topic.messages.build user: user, content: 'foo' }
  let(:page) { Page.new title: 'First post' }

  describe 'dump_to_draft' do
    it 'should construct string' do
      expect(message.dump_to_draft).to be_a(String)
    end
  end

  describe 'load_to_draft' do
    let(:string) { message.dump_to_draft }

    it 'should restore object from string' do
      new_message = Message.new
      new_message.load_from_draft(string)

      expect(new_message.content).to eq('foo')
      expect(new_message.user).to eq(user)
      expect(new_message.topic).to eq(topic)
    end
  end

  describe 'save_draft' do
    it 'should store Draft object without user' do
      expect {
        result = page.save_draft

        expect(result).to eq(true)
      }.to change(Draft, :count).by(1).and \
           change(Message, :count).by(0)
    end

    it 'should store extra attributes to Draft' do
      message.priority = 5
      message.save_draft

      draft = Draft.find(message.draft_id)
      expect(draft.restore.priority).to eq(5)
    end

    it 'should store assocations to Draft' do
      message = topic.messages.build user: user, content: 'foo'
      message.tags.build name: 'important'
      message.tags.build name: 'ruby'
      message.save_draft

      draft = Draft.find(message.draft_id)
      expect(draft.restore.tags.map(&:name)).to eq(%w(important ruby))
    end

    it 'should update existing Draft object' do
      message.save_draft

      message.content = 'bar'
      expect {
        message.save_draft
      }.to change(Draft, :count).by(0).and \
           change(Message, :count).by(0)

      draft = Draft.find(message.draft_id)
      expect(draft.restore.attributes).to eq(message.attributes)
    end
  end

  describe 'update_draft' do
    it 'should update existing Draft object' do
      message.save_draft

      expect {
        message.update_draft(content: 'bar')
      }.to change(Draft, :count).by(0).and \
           change(Message, :count).by(0)

      draft = Draft.find(message.draft_id)
      expect(draft.restore.attributes).to eq(message.attributes)
    end
  end

  describe 'clear_draft' do
    before(:each) { message.save_draft }

    it 'should remove Draft object on later save' do
      new_message = Message.from_draft(message.draft_id)

      expect {
        new_message.save!
      }.to change(Draft, :count).by(-1).and \
           change(Message, :count).by(1)

      expect(new_message.draft_id).to eq(nil)
    end
  end
end
