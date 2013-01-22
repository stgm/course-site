class Course

	COURSE_DIR = "public/course"
	@@settings = nil

	##
	# Re-read the course contents from the git repository.
	#
	def self.reload
		# get update from from git remote (pull)
		update_repo(COURSE_DIR)

		# remove all previous content
		# TODO this is not too efficient but quite hard to prevent
		Section.delete_all
		Page.delete_all
		Subpage.delete_all
		PsetFile.delete_all
		
		# these tables have to be preserved nicely, contain user content
		# - Pset
		# - User
		# - Answer
		# - Submit

		# not implemented yet, so no cleaning needed
		# Progress.delete_all
		# Category.delete_all
		# Item.delete_all
		# Comment.delete_all
		# CommentThread.delete_all
		
		# add course info pages and all sections, recursively
		process_info(COURSE_DIR)
		process_sections(COURSE_DIR)
	end
	
	##
	# This class doubles as a settings class, you can call Course.* to read.
	# The settings are read from course.yml in the course repository.
	#
	def self.method_missing(method_id)
		if @@settings == nil
			load_config
		end
		if @@settings.has_key?(method_id.to_s)
			return @@settings[method_id.to_s]
		end
	end
	
	private
	
	##
	# Load configuration from course.yml in the root of the course repo.
	#
	def self.load_config()
		@@settings = self.read_config(File.join(COURSE_DIR, 'course.yml'))
	end
	
	##
	# Performs a git pull on the course repo.
	# Git.pull has been overridden in order to function well!
	#
	def self.update_repo(dir)
		g = Git.open dir, :log => Rails.logger
		g.pull
	end

	##
	# Reads the `info` directory in the course repo.
	# It creates a page for it and fills it with the subpages.
	# This special page does not support forms and submitting.
	#
	def self.process_info(dir)
		
		# info should be a subdir of the root course dir and contain markdown files
		info_dir = File.join(dir, 'info')
		if File.exist?(info_dir)
			Rails.logger.debug info_dir
			info_page = Page.create(:title => self.course['title'], :position => 0, :path => 'info')
			process_subpages(info_dir, info_page)
		end

	end
	
	##
	# Reads the top-level sections from the course repo.
	# Creates a section in the database and recursively reads pages in the section.
	#
	def self.process_sections(dir)
		
		# sections should be direct descendants of the root course dir
		Dir.glob(subdirs(dir)) do |section|
			
			section_path = File.basename(section)
			next if section_path == "info" # skip info directory

			# if this directory name is parsable
			section_info = split_info(section_path)
			if section_info
				db_sec = Section.create(:title => section_info[2], :position => section_info[1], :path => section_path)
				process_pages(section, db_sec)
			end
		end

	end
	
	##
	# Reads the second-level pages from the course repo.
	# Creates a page in the database and recursively reads subpages in the page.
	#
	def self.process_pages(dir, parent_section)
		
		# each page is a descendant of a section and contains one or more markdown subpages
		Dir.glob(subdirs(dir)) do |page|
			
			page_path = File.basename(page)    # only the directory name
			page_info = split_info(page_path)  # array of position and page name

			# if this directory name is parsable
			if page_info
				# create the page
				db_page = parent_section.pages.create(:title => page_info[2], :position => page_info[1], :path => page_path)

				# load submit.yml config file which contains items to submit
				submit_config = read_config(files(page, "submit.yml"))

				# add pset to database
				if submit_config
					# checks if pset already exists under name
					db_pset = Pset.where(:name => submit_config['name']).first_or_initialize
					db_pset.description = page_info[2]
					db_pset.form = !!submit_config['form']
					# restore link to owning page!!
					db_pset.page = db_page
					db_pset.save

					# always recreate so it's possible to remove files from submit
					['required', 'optional'].each do |modus|
						if submit_config[modus]
							submit_config[modus].each do |file|
								db_pset.pset_files.create(:filename => file, :required => modus == 'required')
							end
						end
					end
				end
				process_subpages(page, db_page)
			end
	
		end
	end
	
	##
	# Reads the third-level subpages from the course repo.
	# Creates a subpage in the database for each.
	#
	def self.process_subpages(dir, parent_page)
		Dir.glob(files(dir, "*.md")) do |subpage|

			subpage_path = File.basename(subpage)
			subpage_info = split_info(subpage_path)
			
			# if parsable file name
			if subpage_info
				file = IO.read(File.join(dir, subpage_path))
				parent_page.subpages.create(:title => subpage_info[2], :position => subpage_info[1], :content => file)
			end
		end
	end

	##
	# Returns a subdir glob pattern.
	#
	def self.subdirs(*name)
		return File.join(name, "*/")
	end

	##
	# Returns a file glob pattern. Yes, this is a really simple function.
	#
	def self.files(*name)
		return File.join(name)
	end

	##
	# Splits a path name of the form "nn textextextext" into two parts.
	# Only accepts paths where the first characters are numbers and followed by white space.
	#
	def self.split_info(object)
		return object.match('(\d+)\s+(.*)')
	end
	
	##
	# Reads the config file and returns the contents.
	#
	def self.read_config(filename)
		if File.exists?(filename)
			return YAML.load_file(filename)
		else
			return false
		end
	end

end
