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
	
	desc "Fix SQLite bools"
	task :fixbools => :environment do
		Pset.where("form = 't'").update_all(form: 1)
		Pset.where("form = 'f'").update_all(form: 0)
		Pset.where("url = 't'").update_all(url: 1)
		Pset.where("url = 'f'").update_all(url: 0)
		Pset.where("automatic = 't'").update_all(automatic: 1)
		Pset.where("automatic = 'f'").update_all(automatic: 0)
		Pset.where("test = 't'").update_all(test: 1)
		Pset.where("test = 'f'").update_all(test: 0)
		AttendanceRecord.where("local = 't'").update_all(local: 1)
		AttendanceRecord.where("local = 'f'").update_all(local: 0)
		Alert.where("published = 't'").update_all(published: 1)
		Alert.where("published = 'f'").update_all(published: 0)
		Hand.where("done = 't'").update_all(done: 1)
		Hand.where("done = 'f'").update_all(done: 0)
		Hand.where("success = 't'").update_all(success: 1)
		Hand.where("success = 'f'").update_all(success: 0)
		Hand.where("helpline = 't'").update_all(helpline: 1)
		Hand.where("helpline = 'f'").update_all(helpline: 0)
		Page.where("public = 't'").update_all(public: 1)
		Page.where("public = 'f'").update_all(public: 0)
		Ping.where("help = 't'").update_all(help: 1)
		Ping.where("help = 'f'").update_all(help: 0)
		Ping.where("active = 't'").update_all(active: 1)
		Ping.where("active = 'f'").update_all(active: 0)
		PsetFile.where("required = 't'").update_all(required: 1)
		PsetFile.where("required = 'f'").update_all(required: 0)
		Schedule.where("self_register = 't'").update_all(self_register: 1)
		Schedule.where("self_register = 'f'").update_all(self_register: 0)
		Schedule.where("self_service = 't'").update_all(self_service: 1)
		Schedule.where("self_service = 'f'").update_all(self_service: 0)
		Section.where("display = 't'").update_all(display: 1)
		Section.where("display = 'f'").update_all(display: 0)
		Submit.where("auto_graded = 't'").update_all(auto_graded: 1)
		Submit.where("auto_graded = 'f'").update_all(auto_graded: 0)
		User.where("done = 't'").update_all(done: 1)
		User.where("done = 'f'").update_all(done: 0)
		User.where("active = 't'").update_all(active: 1)
		User.where("active = 'f'").update_all(active: 0)
		User.where("alarm = 't'").update_all(alarm: 1)
		User.where("alarm = 'f'").update_all(alarm: 0)
		puts "Done!"
	end
	
end
