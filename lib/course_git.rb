module CourseGit

	@@repo_url = 'https://github.com/uva/programming-1.git'
	
	# @logger

	def self.pull
		if git = self.local_repo
			git.pull
		else
			git = Git.clone(@@repo_url, 'public/course', depth:1, log:Rails.logger)
		end
	end
	
	def self.local_repo
		git = Git.open('public/course', log:Rails.logger)
		return git
	rescue
		return nil
	end

end
