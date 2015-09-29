#require 'course'

namespace :course do

	desc "Reset whole site, including students and submissions."
	task :reset => :environment do
		# Course.reset
	end
	
	desc "Calc all grades"
	task :calc => :environment do
		Grade.all.each do |g|
			g.set_calculated_grade
		end
	end
	
end
