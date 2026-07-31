require "test_helper"

# Losing the last admin is unrecoverable through the interface: no one would be left
# who can hand out roles again. The model refuses it, so every path that runs
# validations and callbacks is covered, not just the screens we remembered.
#
class User::LastAdminTest < ActiveSupport::TestCase

    def setup
        @admin = users(:test_user)
        @admin.update!(role: :admin)

        @other = users(:test_user_2)
        @other.update!(role: :student)
    end


    test "the last admin cannot be demoted" do
        assert @admin.last_admin?
        assert_not @admin.update(role: :student)
        assert_includes @admin.errors[:role], "cannot be taken away from the last admin"
        assert @admin.reload.admin?
    end

    test "the last admin cannot be destroyed" do
        assert_no_difference "User.count" do
            assert_not @admin.destroy
        end
        assert @admin.reload.admin?
    end

    test "update! on the last admin raises rather than silently demoting" do
        assert_raises ActiveRecord::RecordInvalid do
            @admin.update!(role: :guest)
        end
        assert @admin.reload.admin?
    end

    test "an admin can be demoted while another admin remains" do
        @other.update!(role: :admin)

        assert_not @admin.last_admin?
        assert @admin.update(role: :student)
        assert @admin.reload.student?
    end

    test "an admin can be destroyed while another admin remains" do
        @other.update!(role: :admin)

        assert_difference "User.count", -1 do
            assert @admin.destroy
        end
    end

    test "the last admin may still change other attributes" do
        assert @admin.update(name: "New Name")
        assert_equal "New Name", @admin.reload.name
    end

    test "promoting someone is never blocked" do
        assert @other.update(role: :admin)
        assert @other.reload.admin?
    end

    test "archiving does not reach the last admin" do
        @other.update!(role: :head)

        User.revoke_staff_rights!

        assert @admin.reload.admin?
        assert @other.reload.guest?
    end

end
