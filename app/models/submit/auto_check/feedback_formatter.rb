module Submit::AutoCheck::FeedbackFormatter
	
	extend ActiveSupport::Concern

	def has_auto_feedback?
		return false if not self.check_results
		(self.check_results.keys & ["check50v2", "check50", "checkpy", "check50v3"]).any?
	end
	
	def formatted_auto_feedback
		check_results = self.check_results

		items = nil
		v3=nil

		# each tool has different output formats that we detect here
		
		check_results.keys.each do |tool|
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
					v3=true
					# items = check_results[tool].collect {|f| f["results"]}.compact.flatten
					return check_results[tool].collect do |item|
						format_checkpy_feedback(item)
					end.join
				elsif check_results[tool].is_a?(Hash)
					v3=true
					items = [check_results[tool]].collect {|f| f["results"]}.flatten
				end
			end
		end
	
		return "" if items.nil?

		# now generate basic feedback
		result = ""
		
		items.each do |item|
			case v3 && item["passed"] || item["status"]
			when true
				result << ":)"
			when false
				result << ":("
			when nil
				result << ":|"
			end
			result << " " + (item["description"] || "") + "\n"
			if item["cause"].present?
				result << "    " + item["cause"]["rationale"] + "\n"
			end
		end
	
		return result
	end

	def has_run_log?
		return false if not self.check_results
		(self.check_results.keys & ["check50"]).any? && self.check_results['check50']['results'].present? &&
		self.check_results['check50']['results'].select{|x| x['data'].present? && x['data']['output'].present? }
	end

	def formatted_run_log
		self.check_results['check50']['results'].select{|x| x['data'].present? && x['data']['output'].present? }.
		map{|x| x['data'] && x['data']['output'] }.join("\n\n-------------------\n\n")
	end


	def format_checkpy_feedback(part)
		"- #{part['name']}\n" +
		(part['results'] || {}).collect { |item| format_line(item["passed"], item['description'], item['message']) }.join
	end
	
	def format_line(success, description, explanation)
		result = ''
		case success
		when true
			result << "  :)"
		when false
			result << "  :("
		when nil
			result << "  :|"
		end
		result << " #{description}\n"
		if explanation.present?
			result << "      #{explanation}\n"
		end
		result
	end
	
end
