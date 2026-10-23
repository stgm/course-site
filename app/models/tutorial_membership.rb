class TutorialMembership < ApplicationRecord

    belongs_to :tutorial
    belongs_to :user

    validates :user_id, uniqueness: { scope: :tutorial_id }

end
