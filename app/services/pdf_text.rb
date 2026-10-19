# Makes text safe to print with Prawn's built-in fonts.
module PdfText

    private

    # Converts text to what Prawn's built-in fonts can print. They only cover
    # Windows-1252 and the app ships no other font, so accents survive and
    # exotic characters become "?".
    def pdf_safe(text)
        text.to_s.encode(
            "Windows-1252",
            fallback: ->(char) { I18n.transliterate(char, replacement: "?") }
        ).encode("UTF-8")
    rescue Encoding::UndefinedConversionError, Encoding::InvalidByteSequenceError
        text.to_s.encode("Windows-1252", invalid: :replace, undef: :replace, replace: "?").encode("UTF-8")
    end

end
