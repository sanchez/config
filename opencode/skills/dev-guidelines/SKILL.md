---
name: dev-guidelines
description: Guidelines for writing code
compatibility: opencode
---

## Use Comments Sparingly, and When You Do, Make Them Meaningful

You don't need to comment on obvious things. Excessive or unclear comments can clutter the codebase and become outdated, leading to confusion and a messy codebase.

Example:

Before:

```python
def group_users_by_id(user_id):
  # This function groups users by id
  # ... complex logic ...
  # ... more code …
```

The comment about the function is redundant and adds no value. The function name already states that it groups users by id; there's no need for a comment stating the same.

Instead, use comments to convey the **why** behind specific actions or explain behaviors.

After:

```python
def group_users_by_id(user_id):
  """Groups users by id to a specific category (1-9).
  Warning: Certain characters might not be handled correctly.
  Please refer to the documentation for supported formats.
  Args:
    user_id (str): The user id to be grouped.
  Returns:
    int: The category number (1-9) corresponding to the user id.
  Raises:
    ValueError: If the user id is invalid or unsupported.
  """
  # ... complex logic ...
  # ... more code …
```

This comment provides meaningful information about the function's behavior and explains unusual behavior and potential pitfalls.

## Write Short Functions That Only Do One Thing

Follow the single responsibility principle (SRP), which means that a function should have one purpose and perform it effectively. Functions are more understandable, readable, and maintainable if they only have one job. It also makes testing them very easy. If a function becomes too long or complex, consider breaking it into smaller, more manageable functions.

Example:

Before:

```python
def process_data(data):
  # ... validate users...
  # ... calculate values ...
  # ... format output …
```

This function performs three tasks: validating users, calculating values, and formatting output. If any of these steps fail, the entire function fails, making debugging a complex issue. If we also need to change the logic of one of the tasks, we risk introducing unintended side effects in another task.

Instead, try to assign each task a function that does just one thing.

After:

```python
def validate_user(data):
  # ... data validation logic ...

def calculate_values(data):
  # ... calculation logic based on validated data ...

def format_output(data):
  # ... format results for display …
```

The improved code separates the tasks into distinct functions. This results in more readable, maintainable, and testable code. Also, If a change needs to be made, it will be easier to identify and modify the specific function responsible for the desired functionality.

## Follow the DRY (Don't Repeat Yourself) Principle and Avoid Duplicating Code or Logic

Avoid writing the same code more than once. Instead, reuse your code using functions, classes, modules, libraries, or other abstractions. This makes your code more efficient, consistent, and maintainable. It also reduces the risk of errors and bugs as you only need to modify your code in one place if you need to change or update it.

Example:

Before:

```python
def calculate_book_price(quantity, price):
  return quantity * price

def calculate_laptop_price(quantity, price):
  return quantity * price
```

In the above example, both functions calculate the total price using the same formula. This violates the DRY principle.

We can fix this by defining a single `calculate_product_price` function that we use for books and laptops. This reduces code duplication and helps improve the maintenance of the codebase.

After:

```python
def calculate_product_price(product_quantity, product_price):
  return product_quantity * product_price
```

## Encapsulate Nested Conditionals into Functions

One way to improve the readability and clarity of functions is to encapsulate nested if/else statements into other functions. Encapsulating such logic into a function with a descriptive name clarifies its purpose and simplifies code comprehension. In some cases, it also makes it easier to reuse, modify, and test the logic without affecting the rest of the function.

In the code sample below, the discount logic is nested within the `calculate_product_discount` function, making it difficult to understand at a glance.

Example:

Before:

```python
def calculate_product_discount(product_price):
  discount_amount = 0
  if product_price > 100:
    discount_amount = product_price * 0.1
  elif price > 50:
    discount_amount = product_price * 0.05
  else:
    discount_amount = 0
  final_product_price = product_price - discount_amount
  return final_product_price
```

We can clean this code up by separating the nested if/else condition that calculates discount logic into another function called `get_discount_rate` and then calling the `get_discount_rate` in the calculate_product_discount function. This makes it easier to read at a glance. The `get_discount_rate` is now isolated and can be reused by other functions in the codebase. It's also easier to change, test, and debug it without affecting the calculate_discount function.

After:

```python
def calculate_discount(product_price):
  discount_rate = get_discount_rate(product_price)
  discount_amount = product_price * discount_rate
  final_product_price = product_price - discount_amount
  return final_product_price

def get_discount_rate(product_price):
  if product_price > 100:
    return 0.1
  elif product_price > 50:
    return 0.05
  else:
    return 0
```
