class AdminController < ApplicationController
	
	COURSE_DIR = "data/course"

	def import
		# clean page for now
	end

	def import_do

		Dir.glob(dir()) do |section|
			section = File.basename(section)
			section_info = split_info(section)
  			db_sec = Section.create(:title => section_info[2], :position => section_info[1])

			Dir.glob(dir(section)) do |page|
				page = File.basename(page)
				page_info = split_info(page)
	  			db_page = db_sec.pages.create(:title => page_info[2], :position => page_info[1])

				Dir.glob(dir(section, page)) do |subpage|
					subpage = File.basename(subpage)
					subpage_info = split_info(subpage)
					file = IO.read(File.join(COURSE_DIR, section, page, subpage))
		  			db_subpage = db_page.subpages.create(:title => subpage_info[2], :position => subpage_info[1], :content => file)
				end
			end
		end
	end
	
	private
	
	def dir(*name)
		return File.join(COURSE_DIR, name, "*")
	end
	
	def split_info(object)
		return object.match('(\d)\s+([^\.]*)')
	end
	
end
