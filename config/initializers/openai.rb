OpenAI.configure do |config|
    config.access_token = ENV.fetch("COURSE_SITE_OPENAI_ACCESS_TOKEN")
    # config.organization_id = ENV.fetch("OPENAI_ORGANIZATION_ID") # Optional.
    # config.uri_base = "https://oai.hconeai.com/" # Optional
    # config.api_type = :azure
    # config.api_version = "2023-03-15-preview"
end
