class Answer < ApplicationRecord
    belongs_to :user
    belongs_to :question
    has_rich_text :text

    delegate :name, to: :user, prefix: true, allow_nil: true
end
