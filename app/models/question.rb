class Question < ApplicationRecord

    belongs_to :user
    belongs_to :page
    
    has_many :answers

    has_rich_text :text

    delegate :name, to: :user, prefix: true, allow_nil: true

end
