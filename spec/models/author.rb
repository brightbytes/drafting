class Author < ActiveRecord::Base
  has_many :posts
  has_drafts
end
