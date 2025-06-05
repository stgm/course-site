namespace :app do
    desc "Reset the app by removing public directories and resetting the database"
    task reset: :environment do
        require 'fileutils'

        dirs_to_remove = ['public/course', 'public/materials']
        dirs_to_remove.each do |dir|
            path = Rails.root.join(dir)
            if Dir.exist?(path)
                FileUtils.rm_rf(path)
                puts "Deleted #{path}"
            else
                puts "Directory #{path} does not exist"
            end
        end

        Rake::Task['db:reset'].invoke
    end
end
