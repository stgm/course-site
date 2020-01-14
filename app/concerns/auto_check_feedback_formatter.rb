module AutoCheckFeedbackFormatter
	
	extend ActiveSupport::Concern

	def has_auto_feedback?
		return false if not self.check_results
		(self.check_results.keys & ["check50v2", "check50", "checkpy", "check50v3"]).any?
	end
	
	def formatted_auto_feedback
		check_results = self.check_results

		result = ""
		items = nil
		v3=nil

		# each tool has different output formats that we detect here
		
		check_results.keys.each do |tool|
			# puts tool
			# puts check_results[tool].is_a?(Array)
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
					# puts "ARR"
					v3=true
					items = check_results[tool].collect {|f| f["results"]}.compact.flatten
				elsif check_results[tool].is_a?(Hash)
					v3=true
					items = [check_results[tool]].collect {|f| f["results"]}.flatten
				end
			end
		
			# puts items
		end
	
		return "" if items.nil?

		# now generate basic feedback
		
		items.each do |item|
			# puts item
			case v3 && item["passed"] || item["status"]
			when true
				result << ":)"
			when false
				# puts "FALSE"
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
