class Note < ApplicationRecord

	belongs_to :student, class_name: "User"
	belongs_to :author, class_name: "User"
	delegate :name, to: :author, prefix: true, allow_nil: true

	after_create do |note|
		note.student.increment! :notes_count if !note.log
	end

	def sortable_date
		updated_at
	end

end
