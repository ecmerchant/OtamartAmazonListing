require 'test_helper'

class AccountsControllerTest < ActionDispatch::IntegrationTest
  test "should get regist" do
    get accounts_regist_url
    assert_response :success
  end

end
