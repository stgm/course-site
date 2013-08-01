namespace :course do

	desc "Reset whole site, including students and submissions."
	task :reset => :environment do
		Course.reset
	end

end
