require "../../spec_helper"

struct TokenStorageTest < ASPEC::TestCase
  def test_token : Nil
    token_storage = ASEC::Authentication::Token::Storage.new
    token_storage.token.should be_nil

    token = ASEC::Authentication::Token::UsernamePassword.new ASEC::User::InMemory.new("username", "password"), "provider"
    token_storage.token = token
    token_storage.token.should be token

    token_storage.token = nil
    token_storage.token.should be_nil
  end

  def test_initializer : Nil
    token_storage = ASEC::Authentication::Token::Storage.new
    token = TestToken.new
    calls = 0

    token_storage.initializer = -> do
      calls += 1
      token_storage.token = token

      nil
    end

    calls.should eq 0
    token_storage.token.should be token
    token_storage.token.should be token
    calls.should eq 1
  end

  def test_setting_a_token_calls_the_initializer_first : Nil
    token_storage = ASEC::Authentication::Token::Storage.new
    token = TestToken.new
    calls = 0

    token_storage.initializer = -> do
      calls += 1
      token_storage.token = TestToken.new

      nil
    end

    token_storage.token = token

    calls.should eq 1
    token_storage.token.should be token
  end

  def test_removing_the_token_discards_the_initializer : Nil
    token_storage = ASEC::Authentication::Token::Storage.new

    token_storage.initializer = -> do
      token_storage.token = TestToken.new

      nil
    end

    token_storage.token = nil

    token_storage.token.should be_nil
  end

  def test_reset : Nil
    token_storage = ASEC::Authentication::Token::Storage.new
    token_storage.token = TestToken.new

    token_storage.reset

    token_storage.token.should be_nil
  end
end
