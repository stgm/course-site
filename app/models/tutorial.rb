class Tutorial < ApplicationRecord

    belongs_to :exam
    belongs_to :owner, class_name: "User", foreign_key: :user_id
    has_many :memberships, class_name: "TutorialMembership", dependent: :destroy
    has_many :users, through: :memberships

    validates :pin, presence: true, uniqueness: true
    validate :exam_is_practice

    before_validation :generate_pin, on: :create

    delegate :name, to: :exam

    private

    # Picks a random 4-digit PIN that no other tutorial uses.
    def generate_pin
        return if pin.present?
        self.pin = loop do
            candidate = format("%04d", SecureRandom.random_number(10_000))
            break candidate unless Tutorial.exists?(pin: candidate)
        end
    end

    def exam_is_practice
        errors.add(:exam, "must be a practice exam") unless exam&.practice?
    end

end
