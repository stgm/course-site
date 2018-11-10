class Submit < ActiveRecord::Base

	belongs_to :user
	delegate :name, to: :user, prefix: true, allow_nil: true

	belongs_to :pset
	delegate :name, to: :pset, prefix: true, allow_nil: true

	has_one :grade, dependent: :destroy
	delegate :status, to: :grade, prefix: true, allow_nil: true

	serialize :submitted_files
	serialize :check_feedback
	serialize :style_feedback
	serialize :file_contents

	# TODO only hide stuff that's not been autograded if autograding is actually enabled
	scope :to_grade,  -> do
		includes(:user, :pset, :grade).
		where(grades: { status: [nil, Grade.statuses[:open], Grade.statuses[:finished]] }).
		where(users: { active: true }).
		where("psets.automatic = ? or submits.auto_graded = ?", false, true).
		order('psets.name')
	end

	scope :admin_to_grade,  -> do
		includes(:user, :pset, :grade).
		where(grades: { status: [nil, Grade.statuses[:open], Grade.statuses[:finished]] }).
		where(users: { active: true }).
		order('psets.name')
	end
	
	before_save do |s|
		if s.check_feedback_changed? || s.style_feedback_changed?
			# TODO this is hardcoded to having keys "correctness" and "style" in the autograder
			# which shouldn't be neccessary
			s.auto_graded = s.pset.config["automatic"].collect do |k,v|
				case k
				when "correctness"
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
	
	def automatic
		f = pset.config
		return {} if f.nil? || f['automatic'].nil?

		# take all automatic rules and use it to create hash of grades
		results = f['automatic'].transform_values do |rule|
			puts rule
			begin
				self.instance_eval(rule)
			rescue
				nil
			end
		end

		return results
	end
	
	def check_score
		if self.check_feedback.is_a?(Hash) && self.check_feedback["version"] && self.check_feedback["version"].start_with?("3")
			# check50 v3
			self.check_feedback["results"].count { |x| x["passed"].present? } / self.check_feedback["results"].size.to_f
		elsif self.check_feedback.is_a?(Array) && self.check_feedback[0].is_a?(Hash) && self.check_feedback[0]["nTests"].is_a?(Integer)
			self.check_feedback.collect { |f| f["nPassed"] }.sum
		elsif self.check_feedback.is_a?(Array) && self.check_feedback[0].is_a?(Array)
			fb = self.check_feedback.flatten(1)
			fb.count { |x| x["status"].present? } / fb.size.to_f
		else
			# older version of check50 used
			self.check_feedback.count { |x| x["status"].present? } / self.check_feedback.size.to_f
		end
	end
	
	def style_score
		case self.style_feedback
		when 0.0..0.2
			1
		when 0.2..0.5
			2
		when 0.5..0.8
			3
		when 0.8..0.9999
			4
		when 1.0
			5
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
			self.update(check_feedback: contents)
		rescue
			# go on, assuming its not there
		end
	end
	
	def retrieve_style_feedback
		path = File.join(Dropbox.root_folder, Settings.dropbox_folder_name, user.login_id, self.folder_name, 'style_results.json')
		begin
			json = Dropbox.download(path)
			contents = json.present? ? JSON.parse(json) : nil
			self.update(style_feedback: contents)
		rescue
			# go on, assuming its not there
		end
	end
	
	def check_feedback_formatted
		return "" if self.check_feedback.blank?

		result = ""

		if self.check_feedback.is_a?(Hash) && self.check_feedback["version"] && self.check_feedback["version"].start_with?("3")
			v3=true
			items = self.check_feedback["results"]
			return self.check_feedback["error"]["value"] if items.nil?
		elsif self.check_feedback.is_a?(Array) && self.check_feedback[0].is_a?(Hash) && self.check_feedback[0]["nTests"].is_a?(Integer)
			v3=true
			items = self.check_feedback.collect {|f| f["results"]}.flatten
		elsif self.check_feedback.is_a?(Array) && self.check_feedback[0].is_a?(Array)
			v3=false
			items = self.check_feedback.flatten(1)
		else
			v3=false
			items = self.check_feedback
		end

		items.each do |item|
			case v3 && item["passed"] || item["status"]
			when true
				result << ":)"
			when false
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
