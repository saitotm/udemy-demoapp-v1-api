require 'test_helper'

class AuthenticatorTest < ActionDispatch::IntegrationTest
  # test "the truth" do
  #   assert true
  # end
  def setup
    @user = active_user
    @token = @user.to_token
  end

  test "jwt_decode" do
    payload = UserAuth::AuthToken.new(token: @token).payload
    sub = payload["sub"]
    exp = payload["exp"]
    aud = payload["aud"]

    assert_equal(@user.id, sub)

    assert exp.present?

    assert_in_delta(2.week.from_now, Time.at(exp), 1.minute)

    assert aud.present?

    assert_equal(ENV["API_DOMAIN"], aud)
  end

  test "authenticate_user_method" do
    key = UserAuth.token_access_key

    cookies[key] = @token
    get api_url("/users/current_user")
    assert_response 200
    assert_equal(@user, @controller.send(:current_user))

    invalid_token = @token + "a"
    cookies[key] = invalid_token
    get api_url("/users/current_user")
    assert_response 401
    assert @response.body.blank?

    cookies[key] = nil
    get api_url("/users/current_user")
    assert_response 401

    travel_to (UserAuth.token_lifetime.from_now - 1.minute) do
      cookies[key] = @token
      get api_url("/users/current_user")
      assert_response 200
      assert_equal(@user, @controller.send(:current_user))
    end

    travel_to (UserAuth.token_lifetime.from_now + 1.minute) do
      cookies[key] = @token
      get api_url("/users/current_user")
      assert_response 401
    end

    cookies[key] = @token
    other_user = User.where.not(id: @user.id).first
    header_token = other_user.to_token

    get api_url("/users/current_user"), headers: { Authorization: "BEarer #{header_token}" }

    assert_equal(header_token, @controller.send(:token))

    assert_equal(other_user, @controller.send(:current_user))
  end
end