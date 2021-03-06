module Drafting
  module ClassMethods
    def from_draft(draft_or_id)
      draft = draft_or_id.is_a?(Draft) ? draft_or_id : Draft.find(draft_or_id)
      raise ArgumentError unless draft.target_type == name

      target = draft.parent || draft.target_type.constantize.new
      target.load_from_draft(draft.data)

      target.draft_id = draft.id
      target
    end

    def drafts
      Draft.where(target_type: name)
    end
  end
end
