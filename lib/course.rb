module Course
	
	# This class is responsible for importing course information from
	# the source into the database.
	# 
	#
	#

	COURSE_DIR = "public/course"
	
	#
	# Clear all settings, users, etc. Only available through the
	# command-line interface (rake).
	
	def Course.reset
		puts "Deleting any previous content..."
		Section.delete_all
		Page.delete_all
		Subpage.delete_all
		PsetFile.delete_all
		Pset.delete_all
		Track.delete_all

		puts "Deleting any user settings..."
		User.where("uvanetid not in (?)", Settings['admins']).delete_all
		Group.delete_all
		Answer.delete_all
		Submit.delete_all
		
		puts "Reloading all information..."
		load_course_info(COURSE_DIR)
		process_info(COURSE_DIR)
		process_sections(COURSE_DIR)
	end

	#
	#
	# Re-read the course contents from the git repository.
	
	def Course.reload
		# get update from from git remote (pull)
		update_repo(COURSE_DIR)

		# remove all previous content
		# TODO this is not too efficient but quite hard to prevent
		Section.delete_all
		Page.delete_all
		Subpage.delete_all
		PsetFile.delete_all
		Track.all.each do |t|
			t.psets.delete_all
		end
		
		# these tables have to be preserved nicely, because they contain user content
		# - Pset
		# - User
		# - Answer
		# - Submit

		# add course info pages and all sections, recursively
		load_course_info(COURSE_DIR)
		process_info(COURSE_DIR)
		process_sections(COURSE_DIR)
	end
		
private
	
	def Course.has_repo?
		g = Git.open(COURSE_DIR, :log => Rails.logger)
		return true
	rescue
		return false
	end
	
	#
	# Performs a git pull on the course repo. `Git.pull` has been
	# overridden in an initializer in order to function well!
	
	def Course.update_repo(dir)
		g = Git.open dir, :log => Rails.logger
		g.pull
	end
	
	#
	#
	# Loads course settings from the course.yml file
	
	def Course.load_course_info(dir)
		config = Course.read_config(File.join(dir, 'course.yml'))
		if config
			if config['course']
				Settings['long_course_name'] = config['course']['title'] if config['course']['title']
				Settings['short_course_name'] = config['course']['short'] if config['course']['short']
				Settings['submit_directory'] = config['course']['submit'] if config['course']['submit']
			end
			Settings['display_acknowledgements'] = config['acknowledgements'] if config['acknowledgements']
			Settings['display_license'] = config['license'] if config['license']
			Settings['cdn_prefix'] = config['cdn'] if config['cdn']
		
			load_schedules(File.join(dir, 'schedules')
		end
	end
	
	def Course.load_schedules(dir, new_track)
		# read schedules, if any
		subdirs_of(dir) do |schedule_dir|
			schedule_name = File.basename(schedule_dir)
			new_schedule = Schedule.where(name: schedule_name).first_or_create
			yaml_files_in(schedule_dir) do |span_conf_file|
				span_conf = Course.read_config(span_conf_file)
				span_name = File.basename(span_conf_file, '.yml')

				span = ScheduleSpan.where(schedule_id: new_schedule.id, name: span_name).first_or_initialize
				span.content = span_conf.to_yaml
				span.save
			end
		end
	end

	# Reads the `info` directory in the course repo. It creates a
	# page for it and fills it with the subpages. This special page
	# does not support forms and submitting of psets.
	
	def Course.process_info(dir)
		# info should be a subdir of the root course dir and contain markdown files
		info_dir = File.join(dir, 'info')
		if File.exist?(info_dir)
			info_page = Page.create(:title => Settings.long_course_name, :position => 0, :path => 'info')
			process_subpages(info_dir, info_page)
		end
	end
	
	#
	# Reads the top-level sections from the course repo. Creates a
	# section in the database and recursively reads pages in the section.
	
	def Course.process_sections(dir)
		
		# sections should be direct descendants of the root course dir
		subdirs_of(dir) do |section|
			
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
	
	#
	# Reads the second-level pages from the course repo. Creates a page
	# in the database and recursively reads subpages in the page.
	
	def Course.process_pages(dir, parent_section)
		
		# each page is a descendant of a section and contains one or more markdown subpages
		subdirs_of(dir) do |page|
			
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
					
					if submit_config['name']
						# checks if pset already exists under name
						db_pset = Pset.where(:name => submit_config['name']).first_or_initialize
						db_pset.description = page_info[2]
						db_pset.message = submit_config['message'] if submit_config['message']
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
					
					if submit_config['dependent_grades']
						Rails.logger.info "dependent grades"
						submit_config['dependent_grades'].each do |grade|
							Pset.where(:name => grade).first_or_create
						end
					end
				end
				process_subpages(page, db_page)
			end
	
		end
	end

	#
	# Reads the third-level subpages from the course repo. Creates a
	# subpage (tab) in the database for each.
	
	def Course.process_subpages(dir, parent_page)
		markdown_files_in(dir) do |subpage|

			subpage_path = File.basename(subpage)
			subpage_info = split_info(subpage_path)
			
			# if parsable file name
			if subpage_info
				file = IO.read(File.join(dir, subpage_path))
				parent_page.subpages.create(:title => subpage_info[2], :position => subpage_info[1], :content => file)
			end
		end
	end

	#
	#
	# Returns a subdir glob pattern.
	
	def Course.subdirs(*name)
		return File.join(name, "*/")
	end
	
	def Course.subdirs_of(*name)
		Dir.glob(subdirs(name)).each do |dir|
			yield dir
		end
	end

	#
	#
	# Returns a file glob pattern. Yes, this is a really simple function.
	
	def Course.files(*name)
		return File.join(name)
	end
	
	def Course.files_in(*name)
		Dir.glob(files(name)).each do |file|
			yield file
		end
	end
	
	def Course.markdown_files_in(*name)
		files_in(name, "*.md") do |file|
			yield file
		end
	end

	def Course.yaml_files_in(*name)
		files_in(name, "*.yml") do |file|
			yield file
		end
	end

	# Splits a path name of the form "nn textextextext" into two parts.
	# Only accepts paths where the first characters are numbers and
	# followed by white space.
	
	def Course.split_info(object)
		return object.match('(\d+)\s+(.*).md$') || object.match('(\d+)\s+(.*)$')
	end
	
	#
	#
	# Reads the config file and returns the contents.
	
	def Course.read_config(filename)
		if File.exists?(filename)
			return YAML.load_file(filename)
		else
			return false
		end
	end

end
