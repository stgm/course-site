require 'course_git'
require 'course_tools'

class CourseLoader
	
	# This class is responsible for importing course information from
	# the source into the database.

	COURSE_DIR = "public/course"
	
	def initialize
		@touched_subpages = []
	end
	
	# Re-read the course contents from the git repository.
	def start
		# get update from from git remote (pull)
		update_repo(COURSE_DIR)

		# add course info pages
		load_course_info(COURSE_DIR)
		process_info(COURSE_DIR)
		load_schedules(COURSE_DIR)
		
		# and all sections, recursively
		process_sections(COURSE_DIR)
				
		# remove old stuff
		prune_untouched
		prune_empty
		
		# put psets in order
		CourseTools.clean_psets
	end

private

	def prune_untouched
		# remove any subpage that was apparently not in the repo anymore
		Subpage.where("id not in (?)", @touched_subpages).delete_all
	end
	
	def prune_empty
		# remove all pages having no subpages
		to_delete = Page.includes(:subpages).where(:subpages => { :id => nil }).pluck(:id)
		Page.where("id in (?)", to_delete).delete_all

		# remove all sections having no pages
		to_delete = Section.includes(:pages).where(:pages => { :id => nil }).pluck(:id)
		Section.where("id in (?)", to_delete).delete_all
		
		# remove psetfiles for psets that have no parent page
		orphan_psets = Pset.includes(:page).where(:pages => { :id => nil }).each do |p|
			p.pset_files.delete_all
		end
		
		# remove psets that have no submits and no parent page
		to_remove = Pset.where("psets.id in (?)", orphan_psets.map(&:id)).includes(:submits).where(:submits => { :id => nil }).pluck(:id)
		Pset.where("psets.id in (?)", to_remove).delete_all
	end
	
	# Performs a git pull on the course repo. `Git.pull` has been
	# overridden in an initializer in order to function well!
	#
	def update_repo(dir)
		CourseGit.pull
	end
	
	# Loads course settings from the course.yml file
	#
	def load_course_info(dir)
		if config = read_config(File.join(dir, 'course.yml'))
			if config['course']
				Settings['long_course_name'] = config['course']['title'] if config['course']['title']
				Settings['short_course_name'] = config['course']['short'] if config['course']['short']
				Settings['submit_directory'] = config['course']['submit'] if config['course']['submit']
				Settings['mail_address'] = config['course']['mail'] if config['course']['mail']
			end
			Settings['display_acknowledgements'] = config['acknowledgements'] if config['acknowledgements']
			Settings['display_license'] = config['license'] if config['license']
			Settings['cdn_prefix'] = config['cdn'] if config['cdn']
			Settings['psets'] = config['psets'] if config['psets']
		end

		if grading = read_config(File.join(dir, 'grading.yml'))
			Settings['grading'] = grading
		end
	end
	
	def load_schedules(dir)
		if schedule = read_config(File.join(dir, 'schedule.yml'))
			Rails.logger.info "Schedule found"
			backup_position = ScheduleSpan.find(Settings.schedule_position).name if Settings.schedule_position
			Rails.logger.info "Backed up: #{backup_position}"
			new_schedule = Schedule.where(name: 'Standard').first_or_create
			new_schedule.schedule_spans.delete_all
			schedule.each do |sch_name, items|
				span = ScheduleSpan.where(schedule_id: new_schedule.id, name: sch_name).first_or_initialize
				span.content = items.to_yaml
				span.save
			end
			# restore current week
			if backup_position && pos = ScheduleSpan.find_by_name(backup_position)
				Settings.schedule_position = pos.id
			end
		else
			Rails.logger.info "No schedule found"
		end
	end

	# Reads the `info` directory in the course repo. It creates a
	# page for it and fills it with the subpages. This special page
	# does not support forms and submitting of psets.
	#
	def process_info(dir)
		# info should be a subdir of the root course dir and contain markdown files
		info_dir = File.join(dir, 'info')
		if File.exist?(info_dir)
			info_page = Page.create(:title => Settings.long_course_name, :position => 0, :path => 'info')
			process_subpages(info_dir, info_page)
		end
	end
	
	# Reads the top-level sections from the course repo. Creates a
	# section in the database and recursively reads pages in the section.
	#
	def process_sections(dir)
		
		# sections should be direct descendants of the root course dir
		subdirs_of(dir) do |section|
			
			section_path = File.basename(section)
			next if section_path == "info" # skip info directory

			# if this directory name is parsable
			section_info = split_info(section_path)
			if section_info
				# db_sec = Section.create(:title => section_info[2], :position => section_info[1], :path => section_path)
				db_sec = Section.find_by_path(section_path) || Section.new(path: section_path)
				db_sec.title = section_info[2]
				db_sec.position = section_info[1]
				db_sec.save
				
				process_pages(section, db_sec)
			end
		end

	end
	
	# Reads the second-level pages from the course repo. Creates a page
	# in the database and recursively reads subpages in the page.
	#
	def process_pages(dir, parent_section)
		
		# each page is a descendant of a section and contains one or more markdown subpages
		subdirs_of(dir) do |page|
			
			page_path = File.basename(page)    # only the directory name
			page_info = split_info(page_path)  # array of position and page name

			# if this directory name is parsable
			if page_info
				# create the page
				# db_page = parent_section.pages.create(:title => page_info[2], :position => page_info[1], :path => page_path)
				
				puts "PATH #{page_path} #{parent_section.pages.inspect}"
				db_page = parent_section.pages.find_by_path(page_path) || parent_section.pages.new(path: page_path)
				db_page.title = page_info[2]
				db_page.position = page_info[1]
				db_page.save
				puts "DONE"

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
						db_pset.url = !!submit_config['url']
						db_pset.page = db_page  # restore link to owning page!
						db_pset.save
						
						Pset.where("id != ?", db_pset).where(page_id: db_page).update_all(page_id: nil)

						# remove previous files
						db_pset.pset_files.delete_all

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
				else
					Pset.where(page_id: db_page).update_all(page_id: nil)
				end
				process_subpages(page, db_page)
			end
	
		end
	end

	# Reads the third-level subpages from the course repo. Creates a
	# subpage (tab) in the database for each.
	#
	def process_subpages(dir, parent_page)
		markdown_files_in(dir) do |subpage|

			subpage_path = File.basename(subpage)
			subpage_info = split_info(subpage_path)
			
			# if parsable file name
			if subpage_info
				file = IO.read(File.join(dir, subpage_path))
				# new_subpage = parent_page.subpages.create(:title => subpage_info[2], :position => subpage_info[1], :content => file)
				new_subpage = parent_page.subpages.find_by_title(subpage_info[2]) || parent_page.subpages.new(title: subpage_info[2])
				new_subpage.position = subpage_info[1]
				new_subpage.content = file
				new_subpage.save
				@touched_subpages << new_subpage.id
			end
		end
	end

	# Returns a subdir glob pattern.
	#
	def subdirs(*name)
		return File.join(name, "*/")
	end
	
	def subdirs_of(*name)
		Dir.glob(subdirs(name)).each do |dir|
			yield dir
		end
	end

	# Returns a file glob pattern. Yes, this is a really simple function.
	#	
	def files(*name)
		return File.join(name)
	end
	
	def files_in(*name)
		Dir.glob(files(name)).each do |file|
			yield file
		end
	end
	
	def markdown_files_in(*name)
		files_in(name, "*.md") do |file|
			yield file
		end
	end

	def yaml_files_in(*name)
		files_in(name, "*.yml") do |file|
			yield file
		end
	end

	# Splits a path name of the form "nn textextextext" into two parts.
	# Only accepts paths where the first characters are numbers and
	# followed by white space.
	#	
	def split_info(object)
		return object.match('(\d+)\s+(.*).md$') || object.match('(\d+)\s+(.*)$')
	end
	
	# Reads the config file and returns the contents.
	#
	def read_config(filename)
		if File.exists?(filename)
			return YAML.load_file(filename)
		else
			return false
		end
	end

end
