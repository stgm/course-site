require 'test_helper'

class GradesHelperTest < ActionView::TestCase

    # --- subgrade_header ---

    test "a worded part becomes its initial and a number stays whole" do
        assert_equal "V1", subgrade_header("vraag_1")
        assert_equal "D2", subgrade_header("deel_2")
        assert_equal "V12", subgrade_header("vraag_12")
    end

    test "every part is shortened, however many there are" do
        assert_equal "V1B", subgrade_header("vraag_1_bonus")
        assert_equal "A1B2", subgrade_header("alpha_1_beta_2")
    end

    test "letters meeting digits split without a separator" do
        assert_equal "V1", subgrade_header("vraag1")
        assert_equal "V1", subgrade_header("v1")
        assert_equal "X11", subgrade_header("xx11")
    end

    test "any non-alphanumeric character separates parts" do
        assert_equal "D.A", subgrade_header("deel_a")
        assert_equal "D.A", subgrade_header("deel a")
        assert_equal "D.A", subgrade_header("deel-a")
    end

    test "two initials running together are separated by a dot" do
        assert_equal "D.A", subgrade_header("deel_a")
        assert_equal "D.A.B", subgrade_header("deel_a_b")
    end

    test "a number beside a letter needs no dot" do
        assert_equal "V1B", subgrade_header("vraag_1_bonus")
        assert_equal "A1B2", subgrade_header("alpha_1_beta_2")
        assert_equal "X11", subgrade_header("xx11")
    end

    test "a name of one part has no structure to shorten" do
        assert_equal "Opzet", subgrade_header("opzet")
        assert_equal "1", subgrade_header("1")
        assert_equal "_1", subgrade_header("_1")
    end

end
