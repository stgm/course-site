module Embed

    # Whether the navbar widget served by the separate hands app should be around
    # at all. Deliberately kept here rather than on the local Hand model: the
    # embed is a bridge to an external app and travels as one unit.
    class Widget

        def self.available?
            Settings.hands_embed_enabled && !Settings.registration_phase_archival?
        end

    end

end
