module AutoCheckScoreInterpreter
	
	extend ActiveSupport::Concern
	
	def automatic_scores
		# puts "HIER #{self.inspect}"
		f = pset.config
		return {} if f.nil? || f['automatic'].nil?

		# take all automatic rules and use it to create hash of grades
		results = f['automatic'].transform_values do |rule|
			# logger.debug rule
			begin
				self.instance_eval(rule)
			rescue
				# puts "FAIL"
				nil
			end
		end

		return results
	end
	
	def correctness_score
		check_results = self.check_results
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
