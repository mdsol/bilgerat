Feature: Scenario outlines

  Background:
    Given a standard Cucumber project directory structure

  Scenario: Full information is only printed for the first example
    And a file named "features/scenario_with_failing_examples.feature" with:
    """
      Feature: Outline

        @tagtag
        Scenario Outline: blah blah
          Given this <fails or passes>
          Examples:
            | fails or passes |
            | passes     |
            | fails     |
            | fails   |
      """
    And a file named "features/step_definitions/steps.rb" with:
    """
      Given /^this (fails|passes)$/ do |str|
        str.should == 'passes'
      end
      """
    When I run bilgerat with: `cucumber --format Bilgerat --out na --format pretty`
    Then there should be a hipchat post matching /.*@tagtag.*Example #2 failed.*/
    And there should not be a hipchat post matching /@tagtag.*Example #3 failed.*/
    And there should be a hipchat post matching /.*Example #3 failed.*/

