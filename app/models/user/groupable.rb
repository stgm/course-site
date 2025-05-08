module User::Groupable

    extend ActiveSupport::Concern

    included do
        belongs_to :group, optional: true
        delegate :name, to: :group, prefix: true, allow_nil: true

        scope :groupless,  -> { where(group_id: nil) }

        before_save :reset_group, if: :schedule_id_changed?
    end

end
