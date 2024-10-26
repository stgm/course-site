module Plugins
  module Exam
    class Pset < ApplicationRecord

      belongs_to :page, optional: true

      has_one :exam
      has_many :submits
      has_many :grades, through: :submits

      enum grade_type: [:integer, :float, :pass, :percentage, :points]

      serialize :files, Hash
      serialize :config, Hash

      def all_filenames
        files.map { |h,f| f }.flatten.uniq
      end

      def submit_config(schedule=nil)
        config
      end

      def grading_config(schedule)
        schedule.grading_config.grades[name]
      end

      def is_final_grade?
        self.final
      end

    end
  end
end
