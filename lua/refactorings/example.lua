-- Example file to demonstrate refactoring techniques
-- This file contains code that can benefit from various refactorings

local M = {}

--- Calculates the total order amount including taxes and discounts
-- @param items table List of items with price, quantity, and category
-- @param tax_rate number Tax rate as a decimal (e.g., 0.08 for 8%)
-- @param discount_rate number Discount rate as a decimal (e.g., 0.1 for 10%)
-- @return number The final order total
-- @error If any input is invalid
function M.calculate_order_total(items, tax_rate, discount_rate)
  -- Input validation
  if type(items) ~= "table" or #items == 0 then
    error("Items must be a non-empty table")
  end
  
  if type(tax_rate) ~= "number" or tax_rate < 0 then
    error("Tax rate must be a non-negative number")
  end
  
  if type(discount_rate) ~= "number" or discount_rate < 0 or discount_rate > 1 then
    error("Discount rate must be a number between 0 and 1")
  end

  -- Calculate subtotal by summing up all items
  local subtotal = M.calculate_subtotal(items)
  
  -- Calculate tax and discount amounts
  local tax_amount = subtotal * tax_rate
  local discount_amount = subtotal * discount_rate
  
  -- Calculate and return final total
  return subtotal + tax_amount - discount_amount
end

--- Calculates the subtotal for a list of items
-- @param items table List of items with price, quantity, and category
-- @return number The subtotal amount
local function calculate_subtotal(items)
  local subtotal = 0
  
  for _, item in ipairs(items) do
    if not item.price or not item.quantity then
      error("Each item must have price and quantity")
    end
    
    local item_total = item.price * item.quantity
    
    -- Apply premium category surcharge if applicable
    if item.category == "premium" then
      item_total = item_total * 1.1  -- 10% premium
    end
    
    subtotal = subtotal + item_total
  end
  
  return subtotal
end

-- Make the function available for testing
M.calculate_subtotal = calculate_subtotal

--- Processes user data and determines if the user is an adult
-- @param user_data table Table containing user information
-- @return table Processed user data with standardized field names
-- @error If input is invalid or missing required fields
function M.process_user_data(user_data)
  -- Input validation
  if type(user_data) ~= "table" then
    error("User data must be a table")
  end
  
  local name = user_data.name
  local email = user_data.email
  local age = user_data.age
  
  -- Validate required fields
  if not name or type(name) ~= "string" or name:match("^%s*$") then
    error("Valid name is required")
  end
  
  if not email or type(email) ~= "string" or not email:match("^[%w._%+-]+@[%w.-]+%.[a-z]+$") then
    error("Valid email is required")
  end
  
  if not age or type(age) ~= "number" or age < 0 or age > 150 then
    error("Age must be a number between 0 and 150")
  end
  
  local is_adult = age >= 18
  
  return {
    name = name,
    email = email,
    adult = is_adult
  }
end

-- Example usage of the refactoring library
function M.demonstrate_refactoring()
  local refactorings = require("refactorings")

  -- Example: Extract method
  -- refactorings.extract_method(10, 18, 'calculate_subtotal')

  -- Example: Rename variable
  -- refactorings.rename_variable('x', 'tax_amount')
  -- refactorings.rename_variable('y', 'discount_amount')
  -- refactorings.rename_variable('z', 'total_with_tax_and_discount')

  -- Example: Inline temp
  -- refactorings.inline_temp('final_result')

  print("Run these refactoring commands to improve the code above!")
end

return M
