module Git
	class Base
		def pull
			self.lib.pull
		end
	end

	class Lib
		def pull
			command('pull')
		end
	end
end
