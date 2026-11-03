require "../spec_helper"

struct RoleHierarchyTest < ASPEC::TestCase
  def test_reachable_role_names : Nil
    role = ASEC::Role::Hierarchy.new({
      "ROLE_ADMIN"       => ["ROLE_USER"],
      "ROLE_SUPER_ADMIN" => ["ROLE_ADMIN", "ROLE_FOO"],
    })

    role.reachable_role_names(["ROLE_USER"]).should eq ["ROLE_USER"]
    role.reachable_role_names(["ROLE_FOO"]).should eq ["ROLE_FOO"]
    role.reachable_role_names(["ROLE_ADMIN"]).should eq ["ROLE_ADMIN", "ROLE_USER"]
    role.reachable_role_names(["ROLE_FOO", "ROLE_ADMIN"]).should eq ["ROLE_FOO", "ROLE_ADMIN", "ROLE_USER"]
    role.reachable_role_names(["ROLE_SUPER_ADMIN"]).should eq ["ROLE_SUPER_ADMIN", "ROLE_ADMIN", "ROLE_USER", "ROLE_FOO"]
    role.reachable_role_names(["ROLE_SUPER_ADMIN", "ROLE_SUPER_ADMIN"]).should eq ["ROLE_SUPER_ADMIN", "ROLE_ADMIN", "ROLE_USER", "ROLE_FOO"]
  end

  def test_reachable_role_names_with_cycle : Nil
    role = ASEC::Role::Hierarchy.new({
      "ROLE_A" => ["ROLE_B"],
      "ROLE_B" => ["ROLE_A", "ROLE_C"],
    })

    role.reachable_role_names(["ROLE_A"]).should eq ["ROLE_A", "ROLE_B", "ROLE_C"]
  end

  def test_reachable_role_names_with_placeholders : Nil
    role = ASEC::Role::Hierarchy.new({
      "ROLE_BAZ_*"     => ["ROLE_USER"],
      "ROLE_FOO_*"     => ["ROLE_BAZ_FOO"],
      "ROLE_BAR_*"     => ["ROLE_BAZ_BAR"],
      "ROLE_QUX_*_BAR" => ["ROLE_FOOBAR"],
    })

    role.reachable_role_names(["ROLE_BAZ_A"]).should eq ["ROLE_BAZ_A", "ROLE_USER"]
    role.reachable_role_names(["ROLE_FOO_A"]).should eq ["ROLE_FOO_A", "ROLE_BAZ_FOO", "ROLE_USER"]
    role.reachable_role_names(["ROLE_QUX_A_BAR"]).should eq ["ROLE_QUX_A_BAR", "ROLE_FOOBAR"]

    # Multiple roles matching the same placeholder
    role.reachable_role_names(["ROLE_FOO_A", "ROLE_FOO_B"]).should eq ["ROLE_FOO_A", "ROLE_FOO_B", "ROLE_BAZ_FOO", "ROLE_USER"]

    # Multiple roles matching multiple placeholders
    role.reachable_role_names(["ROLE_FOO_A", "ROLE_BAR_A"]).should eq ["ROLE_FOO_A", "ROLE_BAR_A", "ROLE_BAZ_FOO", "ROLE_BAZ_BAR", "ROLE_USER"]

    # Placeholders don't match more than their pattern
    role.reachable_role_names(["FOO_ROLE_FOO_A"]).should eq ["FOO_ROLE_FOO_A"]
    role.reachable_role_names(["ROLE_QUX_A_BARA"]).should eq ["ROLE_QUX_A_BARA"]
  end

  def test_reachable_role_names_with_recursive_placeholders : Nil
    role = ASEC::Role::Hierarchy.new({
      "ROLE_FOO_*" => ["ROLE_BAR_BAZ"],
      "ROLE_BAR_*" => ["ROLE_FOO_BAZ"],
      "ROLE_QUX_*" => ["ROLE_QUX_BAZ"],
    })

    # ROLE_FOO_* expanded once
    role.reachable_role_names(["ROLE_FOO_A"]).should eq ["ROLE_FOO_A", "ROLE_BAR_BAZ", "ROLE_FOO_BAZ"]

    # ROLE_FOO_* expanded once even with multiple ROLE_FOO_* input roles
    role.reachable_role_names(["ROLE_FOO_A", "ROLE_FOO_B"]).should eq ["ROLE_FOO_A", "ROLE_FOO_B", "ROLE_BAR_BAZ", "ROLE_FOO_BAZ"]

    # ROLE_BAR_* expanded once with ROLE_FOO_A => ROLE_FOO_* => ROLE_BAR_BAZ => ROLE_BAR_* => ROLE_FOO_BAZ
    role.reachable_role_names(["ROLE_FOO_A", "ROLE_BAR_A"]).should eq ["ROLE_FOO_A", "ROLE_BAR_A", "ROLE_BAR_BAZ", "ROLE_FOO_BAZ"]

    # Self matching placeholder
    role.reachable_role_names(["ROLE_QUX_A"]).should eq ["ROLE_QUX_A", "ROLE_QUX_BAZ"]
    role.reachable_role_names(["ROLE_QUX_BAZ"]).should eq ["ROLE_QUX_BAZ"]
  end

  def test_invalid_placeholder_syntax_is_not_resolved : Nil
    role = ASEC::Role::Hierarchy.new({
      "ROLE_FOO*"     => ["ROLE_FOOBAR"],
      "ROLE_*FOO"     => ["ROLE_FOOBAR"],
      "ROLE_FOO_*BAR" => ["ROLE_FOOBAR"],
      "ROLE_FOO*_BAR" => ["ROLE_FOOBAR"],
    })

    role.reachable_role_names(["ROLE_FOOA"]).should eq ["ROLE_FOOA"]
    role.reachable_role_names(["ROLE_AFOO"]).should eq ["ROLE_AFOO"]
    role.reachable_role_names(["ROLE_FOO_ABAR"]).should eq ["ROLE_FOO_ABAR"]
    role.reachable_role_names(["ROLE_FOOA_BAR"]).should eq ["ROLE_FOOA_BAR"]
  end

  def test_placeholder_matching_a_role_holding_regex_characters : Nil
    role = ASEC::Role::Hierarchy.new({"ROLE_A/B.C_*" => ["ROLE_USER"]})

    role.reachable_role_names(["ROLE_A/B.C_READ"]).should eq ["ROLE_A/B.C_READ", "ROLE_USER"]
    role.reachable_role_names(["ROLE_A/BXC_READ"]).should eq ["ROLE_A/BXC_READ"]
  end
end
