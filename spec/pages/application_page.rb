# frozen_string_literal: true

class ApplicationPage
  include Capybara::DSL

  def element_attribute(element, attribute, scope = {Capybara.default_selector => "html"})
    scope_key = scope.keys[0]
    within(scope_key, scope[scope_key]) do
      key = element.keys[0]
      find(key, element[key])[attribute]
    end
  end

  def wait_until(condition, timeout = 60)
    WaitUtil.wait_for_condition("page wait condition", timeout_sec: timeout) do
      condition
    end
  end

  def present?(element, scope = {Capybara.default_selector => "html"})
    scope_key = scope.keys[0]
    within(scope_key, scope[scope_key]) do
      key = element.keys[0]
      has_selector?(key, element[key])
    end
  end

  def click(element, scope = {Capybara.default_selector => "html"})
    scope_key = scope.keys[0]
    within(scope_key, scope[scope_key]) do
      key = element.keys[0]
      first(element.keys[0], element[key]).click
    end
  end

  def enter(element, scope = {Capybara.default_selector => "html"})
    scope_key = scope.keys[0]
    within(scope_key, scope[scope_key]) do
      key = element.keys[0]
      find(key, element[key]).native.send_keys(:return)
    end
  end

  def type(element, value, scope = {Capybara.default_selector => "html"})
    scope_key = scope.keys[0]
    within(scope_key, scope[scope_key]) do
      key = element.keys[0]
      find(key, element[key]).set(value)
    end
  end

  def not_present?(element, scope = {Capybara.default_selector => "html"})
    scope_key = scope.keys[0]
    within(scope_key, scope[scope_key]) do
      key = element.keys[0]
      has_no_selector?(key, element[key])
    end
  end

  def all_elements(element, scope = {Capybara.default_selector => "html"})
    scope_key = scope.keys[0]
    within(scope_key, scope[scope_key]) do
      key = element.keys[0]
      all(element.keys[0], element[key])
    end
  end

  def verify_text(element, value, scope = {Capybara.default_selector => "html"})
    scope_key = scope.keys[0]
    within(scope_key, scope[scope_key]) do
      key = element.keys[0]
      find(key, element[key]).text.include?(value)
    end
  end
end
