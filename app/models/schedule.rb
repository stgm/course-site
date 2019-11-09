class Schedule < ApplicationRecord
	
	#
	# A schedule is one particular time or way to do the course - there may be multiple
	#

	# A schedule defines a set of modules (ScheduleSpans) that students work through
	has_many :schedule_spans, dependent: :destroy
	belongs_to :current, class_name: "ScheduleSpan", foreign_key: "current_schedule_span_id", optional: true

	# A schedule can have grading groups defined
	has_many :groups, dependent: :destroy
	
	# These are the students in the schedule
	has_many :users
	has_many :submits, through: :users
	has_many :grades, through: :users
	has_many :hands, through: :users
	
	# These are the staff that may have been assigned to grade this group
	has_and_belongs_to_many :graders, class_name: "User"

	def load(contents)
		# this method accepts the yaml contents of a schedule file

		# save the NAME of the current schedule item, to restore later
		backup_position = current.name if current
		
		# delete al items
		schedule_spans.delete_all
		
		# create all items
		contents.each do |name, items|
			span = schedule_spans.where(name: name).first_or_initialize
			span.content = items.to_yaml
			span.save
		end
		
		# restore 'current' item
		update_attribute(:current, backup_position && self.schedule_spans.find_by_name(backup_position))
	end
	
	def generate_groups(number)
		# delete old groups for this schedule
		self.groups.delete_all
		
		# create the requested number of groups
		for n in 0..number-1
			self.groups.create(name: "#{self.name} #{(n+65).chr}")
		end
		
		# randomize students
		students = self.users.student.shuffle
		
		# get the new groups
		groups = self.groups.to_a
		
		# divide students into groups and assign their group each
		students.in_groups(number).each do |student_group|
			User.where("id in (?)", student_group).update_all(group_id: groups.pop.id)
		end
	end
	
	def import_groups(source)
		# delete all groups that are not in use by assistants
		self.groups.where.not(id: Group.joins(:users).where("users.id": User.staff)).delete_all
	
		source.each_line do |line|
			next if line.strip == ""
			line = line.split("\t")

			user_id = line[0..1]
			group_name = line[9] && line[9].strip
			user_name = line[3] + " " + line[2].split(",").reverse.join(" ")
			user_mail = line[4] && line[4].strip
			next if !group_name || group_name == "Group"

			if !group_name.blank? and group_name != "No group"
				group = Group.where(:name => group_name, schedule_id: self.id).first_or_create
			else
				group = nil
			end

			if user_id[0] == user_id[1]
				import_user(user_id[0], group, user_name, user_mail)
			else
				import_user(user_id[0], group, user_name, user_mail)
				import_user(user_id[1], group, user_name, user_mail)
			end
		end
	end

	def import_user(user_id, group, user_name, user_mail)
		if login = Login.where(login: user_id).first
			if user = login.user
				if user.schedule_id == self.id
					user.update_columns(name: user_name, mail: user_mail) if user.name.blank? or user.name =~ /,/
					user.group = group
					user.save
				end
			end
		end
	end	

end
