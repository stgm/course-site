namespace :teacher do

	task :delete_all => :environment do
		Section.delete_all
		Page.delete_all
		Subpage.delete_all
	end

end
