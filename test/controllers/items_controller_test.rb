require 'test_helper'

class ItemsControllerTest < ActionDispatch::IntegrationTest
  test "should get get" do
    get items_get_url
    assert_response :success
  end

end
