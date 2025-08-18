local example = require('refactorings.example')
local lu = require('luaunit')

TestRefactoredFunctions = {}

function TestRefactoredFunctions:test_calculate_order_total()
  -- Test basic calculation
  local items = {
    { price = 10, quantity = 2 },
    { price = 20, quantity = 1 }
  }
  local total = example.calculate_order_total(items, 0.1, 0.05) -- 10% tax, 5% discount
  lu.assertEquals(math.floor(total * 100) / 100, 41.8) -- (10*2 + 20) * 1.1 * 0.95 = 41.8
  
  -- Test premium items
  local premium_items = {
    { price = 10, quantity = 1, category = "premium" },
    { price = 10, quantity = 1 }
  }
  total = example.calculate_order_total(premium_items, 0, 0)
  lu.assertEquals(math.floor(total * 100) / 100, 21) -- (10*1.1 + 10) = 21
  
  -- Test input validation
  lu.assertError(example.calculate_order_total, {}, 0.1, 0.05) -- Empty items
  lu.assertError(example.calculate_order_total, "not a table", 0.1, 0.05) -- Invalid items
  lu.assertError(example.calculate_order_total, items, -0.1, 0.05) -- Negative tax
  lu.assertError(example.calculate_order_total, items, 0.1, 1.1) -- Invalid discount rate
  
  -- Test missing price/quantity
  local invalid_items = {{ price = 10 }}
  lu.assertError(example.calculate_subtotal, invalid_items)
end

function TestRefactoredFunctions:test_process_user_data()
  -- Test adult user
  local user_data = {
    name = "John Doe",
    email = "john@example.com",
    age = 25
  }
  local result = example.process_user_data(user_data)
  lu.assertEquals(result.name, "John Doe")
  lu.assertEquals(result.email, "john@example.com")
  lu.assertEquals(result.adult, true)
  
  -- Test minor user
  user_data.age = 15
  result = example.process_user_data(user_data)
  lu.assertEquals(result.adult, false)
  
  -- Test input validation
  lu.assertError(example.process_user_data, nil) -- nil input
  lu.assertError(example.process_user_data, {}) -- missing fields
  lu.assertError(example.process_user_data, {name = "", email = "test@test.com", age = 30}) -- empty name
  lu.assertError(example.process_user_data, {name = "Test", email = "invalid-email", age = 30}) -- invalid email
  lu.assertError(example.process_user_data, {name = "Test", email = "test@test.com", age = -1}) -- invalid age
  lu.assertError(example.process_user_data, {name = "Test", email = "test@test.com", age = 200}) -- invalid age
end

-- Run the tests
os.exit(lu.LuaUnit.run())
