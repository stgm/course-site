# A schedule is one particular session of a course with a distinct set of students.
class Schedule < ApplicationRecord

    include GroupOperations

    # A schedule defines a set of modules (ScheduleSpans) that students work through
    has_many :schedule_spans, dependent: :destroy
    belongs_to :current, class_name: "ScheduleSpan", foreign_key: "current_schedule_span_id", optional: true

    # A schedule can have grading groups defined
    has_many :groups, dependent: :destroy

    # These are the students in the schedule
    has_many :users
    has_many :students, -> { student }, class_name: "User"
    has_many :submits, through: :users
    has_many :grades, through: :users
    has_many :hands, through: :users

    # These are the staff that may have been assigned to grade this group
    has_and_belongs_to_many :graders, class_name: "User"

    # The information page linked to this schedule
    belongs_to :page, optional: true

    extend FriendlyId
    friendly_id :name, use: :slugged

    def self.default
        Schedule.where(self_register: true).first
    end

    def self.many_registerable?
        Schedule.where(self_register: true).many?
    end

    def self.find_open
        Schedule.where(id: Settings.public_schedule).first
    end

    def default_span(only_public)
        if only_public
            self.schedule_spans.all_public.order(:rank).first
        else
            self.schedule_spans.order(:rank).first
        end
    end

    def can_admin_set_module?
        !self_service && schedule_spans.any?
    end

    def load(contents, schedule_page=nil)
        # this method accepts the yaml contents of a schedule file

        # save the NAME of the current schedule item, to restore later
        backup_position = current.name if current

        # create all items
        touched_spans = []
        rank = 0
        contents.each do |name, items|
            # split description string
            components = name.match(/([^\[]*) \[([^\]]*)\]/)
            if components
                _, name_string, date_string = *components
                # parse into date object
                date = Date.strptime(date_string, '%d/%m/%y')
                name = name_string
            else
                date = nil
            end

            span = schedule_spans.where(name: name).first_or_initialize
            span.content = items
            span.rank = rank
            span.publish_at = date
            span.save
            touched_spans << span.id
            rank += 1
        end

        # remove spans that were apparently deleted
        schedule_spans.where.not(id:touched_spans).delete_all

        # restore 'current' item
        update_attribute(:current, backup_position && self.schedule_spans.find_by_name(backup_position))

        update(page: schedule_page) if schedule_page
    end

end
