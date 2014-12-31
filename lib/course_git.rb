module CourseGit

	def self.pull
		if git = self.local_repo
			git.pull
		else
			if Settings.git_repo.present?
				git = Git.clone(Settings.git_repo, 'public/course', depth:1, log:Rails.logger)
			end
		end
	end
	
	def self.local_repo
		git = Git.open('public/course', log:Rails.logger)
		return git
	rescue
		return nil
	end

end
