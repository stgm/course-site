namespace :app_config do
    desc "Show every AppConfig value, masked, and whether credentials decrypted"
    task status: :environment do
        enc = Rails.root.join("config/credentials/#{Rails.env}.yml.enc")
        key = Rails.root.join("config/credentials/#{Rails.env}.key")
        puts "environment:    #{Rails.env}"
        puts "encrypted file: #{enc.exist? ? 'present' : 'absent'}"
        puts "decryption key: #{key.exist? ? 'present' : 'ABSENT -- get it from the password manager, chmod 600'}"
        puts "keys decrypted: #{AppConfig.credentials.config.keys.size}"
        puts

        (AppConfig.singleton_methods(false).sort - %i[credentials]).each do |name|
            value = AppConfig.public_send(name)
            masked = case value
                     when nil then "-"
                     when true, false then value.to_s
                     else "#{value.to_s.first(4)}…(#{value.to_s.length})"
                     end
            puts format("%-28s %s", name, masked)
        end
    end
end
