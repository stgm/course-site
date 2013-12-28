namespace :course do

	desc "Reset whole site, including students and submissions."
	task :reset => :environment do
		Course.reset
	end
	
	desc "Cleanup one user"
	task :cleanup, [ :user_id ] => :environment do |t, args|
		user = User.where(uvanetid: args[:user_id]).first
		puts "Deleting: #{user.name} ..."
		user.submits.each do |s|
			s.grade.delete if s.grade
		end
		user.submits.delete_all
		user.delete
	end

end
