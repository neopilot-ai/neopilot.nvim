local example = require('refactorings.example')

describe('Refactored Functions', function()
  describe('calculate_order_total', function()
    it('should calculate total with tax and discount', function()
      local items = {
        { price = 10, quantity = 2 },
        { price = 20, quantity = 1 }
      }
      local total = example.calculate_order_total(items, 0.1, 0.05) -- 10% tax, 5% discount
      assert.are.equal(math.floor(total * 100) / 100, 41.8) -- (10*2 + 20) * 1.1 * 0.95 = 41.8
    end)

    it('should handle premium items correctly', function()
      local premium_items = {
        { price = 10, quantity = 1, category = "premium" },
        { price = 10, quantity = 1 }
      }
      local total = example.calculate_order_total(premium_items, 0, 0)
      assert.are.equal(math.floor(total * 100) / 100, 21) -- (10*1.1 + 10) = 21
    end)

    it('should validate input parameters', function()
      assert.has_error(function() example.calculate_order_total({}, 0.1, 0.05) end) -- Empty items
      assert.has_error(function() example.calculate_order_total("not a table", 0.1, 0.05) end) -- Invalid items
      assert.has_error(function() example.calculate_order_total({{price=10,quantity=1}}, -0.1, 0.05) end) -- Negative tax
      assert.has_error(function() example.calculate_order_total({{price=10,quantity=1}}, 0.1, 1.1) end) -- Invalid discount rate
    end)
  end)

  describe('process_user_data', function()
    it('should process adult user data correctly', function()
      local user_data = {
        name = "John Doe",
        email = "john@example.com",
        age = 25
      }
      local result = example.process_user_data(user_data)
      assert.are.equal(result.name, "John Doe")
      assert.are.equal(result.email, "john@example.com")
      assert.is_true(result.adult)
    end)

    it('should process minor user data correctly', function()
      local user_data = {
        name = "Jane Smith",
        email = "jane@example.com",
        age = 15
      }
      local result = example.process_user_data(user_data)
      assert.is_false(result.adult)
    end)

    it('should validate user data', function()
      assert.has_error(function() example.process_user_data(nil) end)
      assert.has_error(function() example.process_user_data({}) end) -- missing fields
      assert.has_error(function() example.process_user_data({name="", email="test@test.com", age=30}) end) -- empty name
      assert.has_error(function() example.process_user_data({name="Test", email="invalid-email", age=30}) end) -- invalid email
      assert.has_error(function() example.process_user_data({name="Test", email="test@test.com", age=-1}) end) -- invalid age
      assert.has_error(function() example.process_user_data({name="Test", email="test@test.com", age=200}) end) -- invalid age
    end)
  end)
end)
