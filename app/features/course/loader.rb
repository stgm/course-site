class Course::Loader
	
	# This class is responsible for importing course information from
	# the source into the database.

	COURSE_DIR = "public/course"
	
	def initialize
		@errors = []
		@touched_subpages = []
		@index = Hash.new { |hash, key| hash[key] = [] }
	end
	
	# Re-read the course contents from the git repository.
	def run
		begin
			# get update from from git remote (pull)
			update_repo(COURSE_DIR)

			# add course info pages
			load_course_info(COURSE_DIR)
			process_info(COURSE_DIR)
		
			# and all standard pages, recursively
			if Course.submodule
				raise "Not implemented (anymore)"
			else
				Dir.chdir(COURSE_DIR) do
					process_pages(Pathname.new('.'), '')
					Settings.page_tree = traverse(Pathname.new('.'), '')
				end
			end
			
			# load_schedules(COURSE_DIR)
			
			# remove old stuff
			prune_untouched
			prune_empty
		
			# put psets in order
			Course::Tools.clean_psets
		rescue SQLite3::BusyException
			@errors << "A timeout occurred while loading the new course content. Just try again!"
		end
		
		Settings['keyword_index'] = @index
		
		return @errors
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

		# remove psetfiles for psets that have no parent page
		# orphan_psets = Pset.includes(:page).where(:pages => { :id => nil })
		#.each do |p|
			# p.pset_files.delete_all
		# end
		
		# remove psets that have no submits and no parent page
		# to_remove = Pset.where("psets.id in (?)", orphan_psets.map(&:id)).includes(:submits).where(:submits => { :id => nil }).pluck(:id)
		# Pset.where("psets.id in (?)", to_remove).delete_all
	end
	
	# Performs a git pull on the course repo. `Git.pull` has been
	# overridden in an initializer in order to function well!
	#
	def update_repo(dir)
		if !Course::Git.pull
			@errors << "Repo could not be updated from remote. You can simply try again."
		end
	end
	
	# Loads course settings from the course.yml file
	#
	def load_course_info(dir)
		if config = read_config(File.join(dir, 'course.yml'))
			Settings["course"] = config
		else
			@errors << "You do not have a course.yml!"
		end

		if grading = read_config(File.join(dir, 'grading.yml'))
			Settings['grading'] = grading
		end
	end
	
	# def load_schedules(dir)
	# 	# load the default schedule in schedule.yml, if available
	# 	if contents = read_config(File.join(dir, 'schedule.yml'))
	# 		schedule = Schedule.first || Schedule.where(name: 'Standard').first_or_create
	# 		schedule.load(contents)
	# 	end
	#
	# 	# load all schedules in schedules.yml, if available
	# 	if contents = read_config(File.join(dir, 'schedules.yml'))
	# 		contents.each do |name, items|
	# 			schedule = Schedule.where(name: name).first_or_create
	# 			schedule.load(items)
	# 		end
	# 	end
	# end

	# Reads the `info` directory in the course repo. It creates a
	# page for it and fills it with the subpages. This special page
	# does not support forms and submitting of psets.
	#
	def process_info(dir)
		# info should be a subdir of the root course dir and contain markdown files
		info_dir = File.join(dir, 'info')
		if File.exist?(info_dir)
			info_page = Page.create(:title => "Syllabus", :position => 0, :path => 'info')
			process_subpages(info_dir, info_page)
		end
	end

	# Walk the directory structure, recursively:
	#  - stores the structurs in a Hash to later render the table of contents (TOC)
	#  - creates pages w/ subpages in the database
	#
	def traverse(curdir, path)
		# this is the tree for the TOC
		res={}

		# get all subdirectories in alphanumerical order
		subdirs = curdir.each_child.filter{|name| !name.to_s.start_with?('.') && name.directory?}.sort
		
		subdirs.each do |subdir|
			# take the subfolder name and sluggify
			curslug = split_info(subdir.basename.to_s)[2].parameterize

			# first time, we start out with the subdir-slug
			# if we would use File.join immediately, it would introduce a leading /
			subslug = path.present? ? File.join(path,curslug) : curslug

			# collect the subtree
			subsubs = traverse(subdir, subslug)

			# create a page at this position
			page = process_pages(subdir, subslug)

			if subsubs.any?
				# if we found a subtree, we add that for the TOC, even if a page is also found here
				# however, the page may still be found at the slugged URL
				res[curslug] = subsubs
			elsif page
				# no subdirs, so add a link to this page
				res[page.title] = page.slug
			end
		end

		return res
	end

	def upcase_first_if_all_downcase(s)
		s == s.downcase && s.sub(/\S/, &:upcase) || s
	end

	# Reads the second-level pages from the course repo. Creates a page
	# in the database and recursively reads subpages in the page.
	#
	def process_pages(page_path, parent_slug)
		
		# page_path=dir
		page_info = split_info(File.basename(page_path))  # array of position and page name
		page_title = upcase_first_if_all_downcase(page_info[2])

		# if this directory contains any documents
		if page_path.glob("*.{md,adoc}").any?
			# create the page
			db_page = Page.find_by_path(page_path.to_s) || Page.new(path: page_path.to_s)
			db_page.title = page_title
			db_page.slug = parent_slug
			db_page.position = page_info[1]
			db_page.save

			# load submit info if available
			submit_config = read_config(files(page_path, "submit.yml"))

			# add pset to database
			if submit_config
				
				db_pset = nil
				
				if submit_config['name']
					# checks if pset already exists under name
					db_pset = Pset.where(:name => submit_config['name']).first_or_initialize
					db_pset.description = page_info[2]
					db_pset.message = submit_config['message'] if submit_config['message']
					db_pset.form = !!submit_config['form']
					db_pset.url = !!submit_config['url']
					db_pset.page = db_page  # restore link to owning page!
					if submit_config['files']
						db_pset.files = submit_config['files']
					else
						db_pset.files = nil
					end

					db_pset.config = submit_config
					db_pset.save
						
					Pset.where("id != ?", db_pset).where(page_id: db_page).update_all(page_id: nil)

					# remove previous files
					# db_pset.pset_files.delete_all

					# always recreate so it's possible to remove files from submit
					# ['required', 'optional'].each do |modus|
					# 	if submit_config[modus]
					# 		submit_config[modus].each do |file|
					# 			db_pset.pset_files.create(:filename => file, :required => modus == 'required')
					# 		end
					# 	end
					# end
				end
			else
				Pset.where(page_id: db_page).update_all(page_id: nil)
			end
			process_subpages(page_path, db_page)
		else
			db_page = nil
		end

		# load module info if available
		if content_links = read_config(files(page_path, "module.yml"))
			if content_links.class==Hash && content_links.has_key?('name')
				name = content_links['name']
				content = content_links['content']
			else
				name = page_info[2].parameterize
				content = content_links
			end
			mod = Mod.where(name: name).first_or_initialize.load(content, page_path)
		end
		
		# load schedule if available
		if schedule_contents = read_config(files(page_path, "schedule.yml"))
			schedule_name = page_title != '.' ? page_title : 'Standard'
			schedule = Schedule.where(name: schedule_name).first_or_create
			schedule.load(schedule_contents, db_page)
		end
		
		return db_page
	end
	
	def add_to_index(keywords, subpage_id)
		if keywords.present?
			keywords.each do |k|
				@index[k] << subpage_id
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
				# file = IO.read(File.join(dir, subpage_path))
				file = FrontMatterParser::Parser.parse_file(File.join(dir, subpage_path))
				
				# new_subpage = parent_page.subpages.create(:title => subpage_info[2], :position => subpage_info[1], :content => file)
				title = file['title'].present? && "#{parent_page.title} / #{file['title']}"
				
				new_subpage = parent_page.subpages.find_by_title(title || subpage_info[2]) || parent_page.subpages.new(title: title || subpage_info[2])
				new_subpage.position = subpage_info[1]
				new_subpage.content = file.content
				new_subpage.description = file.front_matter['description']
				new_subpage.save
				add_to_index(file.front_matter['keywords'], new_subpage.id)
					
				@touched_subpages << new_subpage.id
			end
		end

		asciidoc_files_in(dir) do |subpage|

			subpage_path = File.basename(subpage)
			subpage_info = split_info(subpage_path)
			
			# if parsable file name
			if subpage_info
				file = IO.read(File.join(dir, subpage_path))
				
				document = Asciidoctor.load file, safe: :safe, attributes: { 'showtitle' => true, 'imagesdir' => parent_page.public_url, 'skip-front-matter' => true, 'stem' => true }
				html = document.convert
				
				new_subpage = parent_page.subpages.find_by_title(subpage_info[2]) || parent_page.subpages.new(title: subpage_info[2])
				new_subpage.position = subpage_info[1]
				new_subpage.content = html
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

	def asciidoc_files_in(*name)
		files_in(name, "*.adoc") do |file|
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
		return object.match('(\d+)\s+(.*).md$') || object.match('(\d+)\s+(.*)$') || [object, 0, object]
	end
	
	# Reads the config file and returns the contents.
	#
	def read_config(filename)
		if File.exists?(filename)
			begin
				return YAML.load_file(filename)
			rescue
				@errors << "A yml was in an unreadable format. Did you confuse tabs and spaces?"
				return false
			end
		else
			return false
		end
	end

end
