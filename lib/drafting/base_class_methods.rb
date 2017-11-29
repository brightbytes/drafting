module Drafting
  module BaseClassMethods
    ALLOWED_DRAFT_OPTION_KEYS = [ :parent ]

    def has_drafts(options={})
      raise ArgumentError unless options.is_a?(Hash)
      raise ArgumentError unless options.keys.all? { |k| ALLOWED_DRAFT_OPTION_KEYS.include?(k) }

      unless method_defined? :drafts
        class_eval do
          def drafts
            Draft.where(parent: self)
          end

          def self.child_drafts
            Draft.where(parent_type: self.base_class.name)
          end
        end
      end

      include Drafting::InstanceMethods
      extend Drafting::ClassMethods

      attr_accessor :draft_id
      after_create :clear_draft
    end
  end
end
