class GptJob < ApplicationJob
    queue_as :default

    def perform(hand, query)
        client = OpenAI::Client.new
        response = client.chat(
            parameters: {
                model: "gpt-3.5-turbo", # Required.
                messages: [{
                    role: "user",
                    content: query
                }], # Required.
                temperature: 0.7,
            })
            Rails.logger.info response
        hand.update(hint: response['choices'].first['message']['content']) if response['choices']
    end
end
