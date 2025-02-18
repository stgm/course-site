module User::HandRaiser

    extend ActiveSupport::Concern

    included do
        has_many :hands
    end

    def hands_overview
        hands.where(success: true).map do |h|
            if h.closed_at.present? && h.claimed_at.present?
                [ h.id, h.claimed_at, (h.closed_at - h.claimed_at)/60, h.assist_name || "" ]
            end
        end.compact
    end

end
