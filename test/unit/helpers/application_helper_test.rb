require 'test_helper'

class ApplicationHelperTest < ActionView::TestCase
    ASSET_PREFIX = "https://raw.githubusercontent.com/spcourse/progns/main"

    # --- Math ---

    test "block math renders katex" do
        html = render_markdown("$$x^2 + y^2 = z^2$$", trusted: true)
        assert_includes html, "katex"
    end

    test "inline math renders katex" do
        html = render_markdown("Text with $$x$$ inline math.", trusted: true)
        assert_includes html, "katex"
    end

    test "single dollar math mode renders katex" do
        html = render_markdown("Some $x$ math", single_dollar_math: true, trusted: true)
        assert_includes html, "katex"
    end

    # --- Videos ---

    test "embed image renders responsive iframe" do
        html = render_markdown("![embed](https://www.youtube.com/embed/abc123)", trusted: true)
        assert_includes html, "<iframe"
        assert_includes html, "ratio-16x9"
        assert_includes html, "https://www.youtube.com/embed/abc123"
    end

    test "embed paragraph is not wrapped in a p tag" do
        html = render_markdown("![embed](https://www.youtube.com/embed/abc123)", trusted: true)
        assert_not_includes html, "<p>"
    end

    # --- Links ---

    test "relative link is prefixed with asset_prefix" do
        html = render_markdown("[notes](notes.pdf)", asset_prefix: ASSET_PREFIX, trusted: true)
        assert_includes html, ASSET_PREFIX
    end

    test "external link gets target blank" do
        html = render_markdown("[link](https://example.com)", trusted: true)
        assert_includes html, 'target="_blank"'
    end

    test "anchor link gets no target blank" do
        html = render_markdown("[section](#top)", trusted: true)
        assert_not_includes html, 'target="_blank"'
    end

    test "anchor link is not prefixed with asset_prefix" do
        html = render_markdown("[section](#top)", asset_prefix: ASSET_PREFIX, trusted: true)
        assert_not_includes html, ASSET_PREFIX
    end

    test "absolute link is not prefixed with asset_prefix" do
        html = render_markdown("[link](/some/path)", asset_prefix: ASSET_PREFIX, trusted: true)
        assert_not_includes html, ASSET_PREFIX
    end

    # --- Images ---

    test "relative image src is prefixed with asset_prefix" do
        html = render_markdown("![alt text](diagram.png)", asset_prefix: ASSET_PREFIX, trusted: true)
        assert_includes html, ASSET_PREFIX
        assert_includes html, "diagram.png"
    end

    # --- Tables ---

    test "table is wrapped in table-responsive div" do
        md = <<~MD
            | Col1 | Col2 |
            |------|------|
            | a    | b    |
        MD
        html = render_markdown(md, trusted: true)
        assert_includes html, "table-responsive"
        assert_includes html, "<table"
    end

    # --- Trust ---

    test "trusted content renders raw HTML blocks" do
        html = render_markdown("<div class='custom'>hello</div>", trusted: true)
        assert_includes html, "<div"
        assert_includes html, "custom"
    end

    test "untrusted content strips script tags" do
        html = render_markdown("<script>alert('xss')</script>", trusted: false)
        assert_not_includes html, "<script"
    end

    # --- Exam buttons ---

    test "exam button for unknown exam renders error string" do
        html = render_markdown("[start](exam_button:nonexistent_exam)", trusted: true)
        assert_includes html, "nonexistent_exam"
        assert_includes html, "could not be found"
    end

    test "exam button for known exam renders a form button" do
        exam = Exam.create!(pset: psets(:tentamen))
        html = render_markdown("[start exam](exam_button:tentamen)", trusted: true)
        assert_includes html, "<form"
        exam.destroy
    end
end
