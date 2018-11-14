class Setting < ApplicationRecord
  serialize:fixed, Array
  serialize:keyword, Array
  serialize:price, Array
  serialize:title, Array
end
