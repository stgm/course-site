#
#  Get remote git data, either by pulling existing, or cloning anew.
#
module CourseGit

	def self.pull
		# allow configuration of remote branch, with default
		remote_branch = Settings.git_branch || 'master'

		if git = self.existing_local_repo
			begin
				git.pull 'origin', git.current_branch
			rescue Git::GitExecuteError
				return false
			end
		else
			if Settings.git_repo.present?
				git = Git.clone(Settings.git_repo, 'public/course', branch:remote_branch, depth:1, log:Rails.logger)
			end
		end
		
		return true
	end
	
	def self.existing_local_repo
		return Git.open('public/course', log:Rails.logger)
	rescue
		return nil
	end

end
