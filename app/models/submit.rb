class Submit < ApplicationRecord

	belongs_to :user
	delegate :name, to: :user, prefix: true, allow_nil: true
	delegate :suspect_name, to: :user, prefix: true, allow_nil: true

	belongs_to :pset
	delegate :name, to: :pset, prefix: true, allow_nil: true

	has_one :grade, dependent: :destroy
	delegate :status, to: :grade, prefix: true, allow_nil: true
	delegate :first_graded, to: :grade, allow_nil: true
	delegate :last_graded, to: :grade, allow_nil: true

	serialize :submitted_files
	serialize :check_feedback
	serialize :style_feedback
	serialize :file_contents
	serialize :check_results

	# TODO only hide stuff that's not been autograded if autograding is actually enabled
	scope :to_grade,  -> do
		includes(:user, :pset, :grade).
		where(grades: { status: [nil, Grade.statuses[:unfinished]] }).
		where(users: { active: true }).
		where("psets.automatic = ? or submits.check_results is not null", false).
		order('submits.created_at asc')
	end

	scope :admin_to_grade,  -> do
		includes(:user, :pset, :grade).
		where(grades: { status: [nil, Grade.statuses[:unfinished], Grade.statuses[:finished]] }).
		where(users: { active: true }).
		where("psets.automatic = ? or submits.check_results is not null", false).
		order('submits.created_at asc')
	end
	
	before_save do |s|
		if s.check_feedback_changed? || s.style_feedback_changed?
			# TODO this is hardcoded to having keys "correctness" and "style" in the autograder
			# which shouldn't be neccessary
			s.auto_graded = s.pset.config["automatic"].collect do |k,v|
				case k
				when "correctness", "points"
					s.check_feedback.present?
				when "style"
					s.style_feedback.present?
				else
					true
				end
			end.all?
		end
		true
	end

	def graded?
		return (self.grade && (!self.grade.grade.blank? || !self.grade.calculated_grade.blank?))
	end
	
	def last_submitted
		submitted_at && submitted_at.to_formatted_s(:short) || "never"
	end
	
	def automatic
		f = pset.config
		return {} if f.nil? || f['automatic'].nil?

		# take all automatic rules and use it to create hash of grades
		results = f['automatic'].transform_values do |rule|
			logger.debug rule
			begin
				self.instance_eval(rule)
			rescue
				puts "FAIL"
				nil
			end
		end

		return results
	end
	
	def check_score
		check_results = JSON(self.check_results)
		return nil if !self.check_results.present?
		
		check_results.keys.each do |tool|
			puts tool
			puts check_results[tool].inspect
			case tool
			when "check50v2"
				return check_results[tool].count { |x| x["status"].present? } / check_results[tool].size.to_f
			when "check50", "check50v3"
				return nil if check_results[tool]["error"].present?
				return check_results[tool]["results"].count { |x| x["passed"].present? } / check_results[tool]["results"].size.to_f
			when "checkpy"
				if check_results[tool].is_a?(Array)
					puts "arr"
					return check_results[tool].collect { |f| f["nPassed"] }.sum
				elsif check_results[tool].is_a?(Hash)
					puts "hash"
					return [check_results[tool]].collect { |f| f["nPassed"] }.sum
				end
			end
		end

		# didn't document what kind of tool generates the below
		# elsif self.check_feedback.is_a?(Array) && self.check_feedback[0].is_a?(Array)
		# 	fb = self.check_feedback.flatten(1)
		# 	fb.count { |x| x["status"].present? } / fb.size.to_f
	end
	
	def style_score
		check_results = JSON(self.check_results)
		check_results.keys.each do |tool|
			case tool
			when "style50"
				case check_results[tool]
				when 0.0..0.2
					return 1
				when 0.2..0.5
					return 2
				when 0.5..0.8
					return 3
				when 0.8..0.9999
					return 4
				when 1.0
					return 5
				end
			end
		end
	end
	
	def register_check_results(json)
		# put results into db
		self.check_token = nil
		self.check_results = json
		
		# create a create if needed
		grade = self.grade || self.build_grade
		
		# check via the grade if this submit is OK
		grade.reset_automatic_grades(self.automatic)
		grade.set_calculated_grade
		grade.status = Grade.statuses[:published]
		grade.save
		
		self.save

		# if not OK, send an e-mail
		if grade.calculated_grade == 0
			GradeMailer.bad_submit(self).deliver
		end
	end
	
	def check_feedback_problems?
		return false if self.check_feedback.blank?
		
		self.check_feedback.index { |x| x["status"].blank? }.present?
	end
	
	def retrieve_check_feedback
		path = File.join(Dropbox.root_folder, Settings.dropbox_folder_name, user.login_id, self.folder_name, 'check_results.json')
		begin
			json = Dropbox.download(path)
			contents = json.present? ? JSON.parse(json) : nil
			if contents.is_a?(Array)
				self.update(check_results: { "checkpy" => contents }.to_json )
			else
				self.update(check_results: contents.to_json)
			end
		rescue
			# go on, assuming its not there
		end
	end

	# def retrieve_style_feedback
	# 	path = File.join(Dropbox.root_folder, Settings.dropbox_folder_name, user.login_id, self.folder_name, 'style_results.json')
	# 	begin
	# 		json = Dropbox.download(path)
	# 		contents = json.present? ? JSON.parse(json) : nil
	# 		self.update(style_feedback: contents)
	# 	rescue
	# 		# go on, assuming its not there
	# 	end
	# end
	
	def has_feedback?
		return false if not self.check_results
		check_results = JSON(self.check_results)
		(check_results.keys & ["check50v2", "check50", "checkpy", "check50v3"]).any?
	end
	
	def check_feedback_formatted
		puts "HAHA"
		check_results = JSON(self.check_results)

		result = ""
		items = nil
		v3=nil

		check_results.keys.each do |tool|
			puts tool
			puts check_results[tool].is_a?(Array)
			case tool
			when "check50v2"
				v3=false
				items = check_results[tool]
			when "check50"
				v3=true
				items = check_results[tool]["results"]
				return check_results[tool]["error"]["value"] if items.nil?
			when "check50v3"
				v3=true
				items = check_results[tool]["results"]
				return check_results[tool]["error"]["value"] if items.nil?
			when "checkpy"
				if check_results[tool].is_a?(Array)
					puts "ARR"
					v3=true
					items = check_results[tool].collect {|f| f["results"]}.compact.flatten
				elsif check_results[tool].is_a?(Hash)
					v3=true
					items = [check_results[tool]].collect {|f| f["results"]}.flatten
				end
			end
			
			puts items
		end
		
		return "" if items.nil?

		# result = ""

		# if self.check_feedback.is_a?(Hash) && self.check_feedback["version"] && self.check_feedback["version"].start_with?("3")
		# 	v3=true
		# 	items = self.check_feedback["results"]
		# 	return self.check_feedback["error"]["value"] if items.nil?
		# elsif self.check_feedback.is_a?(Array) && self.check_feedback[0].is_a?(Hash) && self.check_feedback[0]["nTests"].is_a?(Integer)
		# 	# checkpy multiple tests (module)
		# elsif self.check_feedback.is_a?(Hash) && self.check_feedback["nTests"].is_a?(Integer)
		# 	# checkpy single test
		# elsif self.check_feedback.is_a?(Array) && self.check_feedback[0].is_a?(Array)
		# 	v3=false
		# 	items = self.check_feedback.flatten(1)
		# else
		# end

		puts items.inspect
		puts v3
		items.each do |item|
			puts item
			case v3 && item["passed"] || item["status"]
			when true
				result << ":)"
			when false
				puts "FALSE"
				result << ":("
			when nil
				result << ":|"
			end
			result << " " + item["description"] + "\n"
			if item["cause"].present?
				result << "    " + item["cause"]["rationale"] + "\n"
			end
		end
		
		return result
	end

end
