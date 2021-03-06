module Drafting
  module InstanceMethods
    def save_draft
      draft = Draft.find_by_id(self.draft_id) || Draft.new

      draft.data = dump_to_draft
      draft.target_type = self.class.name
      draft.parent = self
      result = draft.save
      self.draft_id = draft.id if result
      result
    end

    def update_draft(attributes)
      with_transaction_returning_status do
        assign_attributes(attributes)
        save_draft
      end
    end

    # Override this two methods if you want to change the way to dump/load data
    def dump_to_draft
      Marshal.dump(instance_values)
    end

    def load_from_draft(string)
      values = Marshal.load(string)

      values.each do |name, value|
        instance_variable_set("@#{name}", value)
      end
    end

    def draft_id
      @draft_id || attributes['draft_id']
    end

    def draft
      @draft ||= Draft.find_by(id: draft_id)
    end

  private

    def clear_draft
      if draft = Draft.find_by_id(self.draft_id)
        self.draft_id = nil if draft.destroy
      end
    end
  end
end
