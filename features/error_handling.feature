Feature: Error handling

  @announce-stderr
  Scenario: Undefined steps work
    And a file named "features/scenario_with_unmatched_step_def.feature" with:
    """
      Feature: Outline

        @tagtag
        Scenario: blah blah
          Given this passes
      """
    And a file named "features/step_definitions/steps.rb" with:
    """
      Given /^this passes$/ do
      end
     Given /^this passes$/ do
      end
      """
    When I run bilgerat with: `cucumber --format Bilgerat --out na --format pretty`
    Then there should be a hipchat post matching /Ambiguous match of "this passes"/