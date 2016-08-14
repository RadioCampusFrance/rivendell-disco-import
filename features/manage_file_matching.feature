Feature: Manage file matching

  Scenario: Select a file by Ruby regexp
    Given a configuration with this prepare block
     """
     if file.match /dummy/
       task.tags << 'matched'
     end
     """
    When a file "dummy.wav" is imported
    Then the task should have tag "matched"

  Scenario: Select a file with helper 'with'
    Given a configuration with this prepare block
     """
     with /dummy/ do
       task.tag 'matched'
     end
     """
    When a file "dummy.wav" is imported
    Then the task should have tag "matched"

  Scenario: Select a cast by file name
    Given a cart "123" exists with title:"A long Title"
    And a configuration with this prepare block
     """
     cart.find_by_title file.basename
     """
    When a file "a-long-title.wav" is imported
    Then the task should have destination "Cart 123"

  Scenario: Select a cast by file name
    Given a cart "123" exists with title:"A long Title", group:"PAD"
    And a cart "666" exists with title:"A long Title", group:"MUSIC"
    And a configuration with this prepare block
     """
     cart.find_by_title file.basename, :group => 'PAD'
     """
    When a file "a-long-title.wav" is imported
    Then the task should have destination "Cart 123"
