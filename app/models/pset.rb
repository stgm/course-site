class Pset < ApplicationRecord

    belongs_to :page, optional: true

    has_many :submits
    has_many :grades, through: :submits

    # TODO remove?
    enum grade_type: [:integer, :float, :pass, :percentage, :points]

    serialize :files, Hash
    serialize :config, Hash

    def all_filenames
        files.map { |h,f| f }.flatten.uniq
    end

    def submit_config(schedule=nil)
        config
    end

    def is_final_grade?
        self.final
    end

end
