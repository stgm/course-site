module AutoCheck::ScoreCalculator
	
	extend ActiveSupport::Concern
	
	def automatic_scores
		f = pset.config
		return {} if f.nil? || f['automatic'].nil?

		# take all automatic rules and use it to create hash of grades
		results = f['automatic'].transform_values do |rule|
			begin
				self.instance_eval(rule)
			rescue
				nil
			end
		end

		return results
	end
	
	# method will be called from grading.yml expressions
	def correctness_score
		check_results = self.check_results
		return nil if !self.check_results.present?
		
		check_results.keys.each do |tool|
			case tool
			when "check50v2"
				return check_results[tool].count { |x| x["status"].present? } / check_results[tool].size.to_f
			when "check50", "check50v3"
				return nil if check_results[tool]["error"].present?
				return check_results[tool]["results"].count { |x| x["passed"].present? } / check_results[tool]["results"].size.to_f
			when "checkpy"
				if check_results[tool].is_a?(Array)
					return check_results[tool].collect { |f| f["nPassed"] }.sum
				elsif check_results[tool].is_a?(Hash)
					return [check_results[tool]].collect { |f| f["nPassed"] }.sum
				end
			end
		end
	end
	
	# method will be called from grading.yml expressions
	def style_score
		check_results = self.check_results
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
	
end
