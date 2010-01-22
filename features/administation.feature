Feature: administation
  To administrate the site
  A administrator
  Does create, edit and delete lines
  And create, edit and delete stops
  And create and delete timetables

  Scenario Outline: create line
    Given I am authenticated
    When I go to /lines
    And I follow "Dodaj nową linię"
    And I fill in "line_no" with "<line_no>"
    And I fill in "line_begin" with "<line_begin>"
    And I check "line_active"
    And I press "Dodaj"
    Then I should see a green message
    And I should see "Dodano nową linię"
    And I should see "Linie wszystkie"

  Examples:
    | line_no | line_begin  |
    | 13      | 3.05.2008   |
    | 40      | 30.12.2009  |

  Scenario Outline: edit line
    Given I am authenticated
    And only line with no "<no>", begin "<begin>", active "<active>", temporary "<temp>" exists
    When I go to /lines
    And I follow "Nieznany"
    And I follow "Edytuj linię"
    And I check "line_temporary"
    And I press "Uaktualnij" 
    Then I should see a green message
    And I should see "Linia zaktualizowana"

  Examples:
    | no  | begin     | active  | temp  |
    | 5   | 2.09.2008 | true    | false |
    | 15  | 2.09.2008 | true    | true  |

  Scenario Outline: edit line
    Given I am authenticated
    And only line with no "<no>", begin "<begin>", active "<active>", temporary "<temp>" exists
    When I go to /lines
    And I follow "Nieznany"
    And I follow "Edytuj linię"
    And I uncheck "line_active"
    And I press "Uaktualnij" 
    Then I should see a green message
    And I should see "Linia zaktualizowana"
    And I should see "linia nie jest aktywna"

  Examples:
    | no  | begin     | active  | temp  |
    | 5   | 2.09.2008 | true    | false |
    | 15  | 2.09.2008 | true    | true  |

  Scenario: delete line
    Given I am authenticated
    And only line with no "17", begin "01.01.2009", active "true", temporary "false" exists
    When I go to /lines
    And I follow "Nieznany"
    And I follow "Usuń"
    Then I should see a green message
    And I should see "Linie wszystkie"

  Scenario Outline: create stop
    Given I am authenticated
    When I go to /stops
    And I follow "Nowy przystanek"
    And I fill in "stop_name" with "<name>"
    And I fill in "stop_lat" with "<lat>"
    And I fill in "stop_lng" with "<lng>"
    And I press "Dodaj"
    Then I should see a green message

  Examples:
    | name        | lat   | lng | trams | buses |
    | Wariatkowo  | 0.0   | 0.0 | true  | true  |
    | Bieżanowo   | 0.0   | 0.0 | true  | false |
    | Kobierzyn   | 0.0   | 0.0 | false | true  |
    | Zażółciowo  | 0.0   | 0.0 | false | false |   

  Scenario Outline: create stop failure
    Given I am authenticated
    When I go to /stops
    And I follow "Nowy przystanek"
    And I fill in "stop_name" with "<name>"
    And I fill in "stop_lat" with "<lat>"
    And I fill in "stop_lng" with "<lng>"
    And I press "Dodaj"
    Then I should see a red message

  Examples:
    | name  | lat   | lng   |
    | Lipa  |       |       |
    | Ę     | 12.2  | 56.7  |
    | Pole  | 45    | abc   |
    | Er    | 45    | 67    |

  Scenario: edit stop
    Given I am authenticated

  Scenario: delete stop
    Given I am authenticated


  Scenario Outline: create timetable
    Given I am authenticated

  Examples:
    | no  | beginning | direction   |
    | 4   | AWF       | Struga      |
    | 114 | Ruczaj    | Wyki        |
    | 144 | Wlotowa   | Makowskiego |
    | 601 | Kombinat  | Bronowice   |

  Scenario: delete timetable
    Given I am authenticated

  Scenario: denyed access