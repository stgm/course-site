class User < ApplicationRecord

    # Properties
    include Authenticatable, Loginable, Staffable, Groupable, Schedulizable, Profileable

    # Activities
    include Submitter, HandRaiser, Attendee, Notee

    # Utilities
    include ChangeLogger, FinalGradeAssigner

    validates :mail, email: true

    def items(with_private=false)
        items = []
        # show all submits for psets that are _not_ a module
        items += submits.includes(:pset).where("submitted_at is not null").to_a
        items += grades.includes(:pset, :submit, :grader).showable.to_a
        # items += hands.includes(:assist).to_a if with_private
        items += notes.includes(:author).to_a if with_private
        items = items.sort { |a,b| b.sortable_date <=> a.sortable_date }
    end

    def designation
        if Schedule.count > 1
            group_name || schedule_name
        end
    end

end
