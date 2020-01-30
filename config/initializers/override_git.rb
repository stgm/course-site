class Git::Lib
	
	def update_submodules
		command 'submodule update --remote'
	end
	
end
