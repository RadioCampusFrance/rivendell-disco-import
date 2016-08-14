Feature: Manage Cart attributes
  In order to make the correct import
  An user
  wants to manage carts attributes according importing file
  
  Scenario: Seletec the cart group
    Given a configuration with this prepare block 
     """
     cart.group = 'MUSIC'
     """ 
    When a file "dummy.wav" is imported   
    Then the task should have destination "Cart in group MUSIC"

  Scenario: Seletec a cart by number
    Given a configuration with this prepare block 
     """
     cart.number = 123
     """ 
    When a file "dummy.wav" is imported   
    Then the task should have destination "Cart 123"
