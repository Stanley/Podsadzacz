Feature: viewing lines
  To get all the informations about some line
  A user
  Does go to the line index
  And clicks the particular line

  Scenario Outline: indexing active lines
    Given the following active lines exist in the system:
      | no  | begin       |
      | 15  | 01.01.2009  |
      | 55  | 01.01.2009  |
      | 144 | 01.01.2009  |
      | 200 | 01.01.2009  |
      | 202 | 01.01.2009  |
      | 505 | 01.01.2009  |
      | 505 | 01.01.2009  |
      | 901 | 01.01.2009  |
    When I go to /active-<category>-lines
    Then I should see "<lines>" lines numbers
    And I should see "<count>" links to line show page
    And I should see "<category>" link highlighted

  Examples:
    | category   | display        | count | lines |
    | all        | wszystkie      | 8     | 7     |
    | tram       | tramwajowe     | 2     | 2     |
    | bus        | autobusowe     | 6     | 5     |
    | zonalBus   | aglomeracyjne  | 2     | 1     |
    | nightBus   | nocne          | 1     | 1     |

  Scenario: displaying empty line
    Given only line with no "16", begin "01.01.2009" exists
    When I go to /lines
    And I follow "Nieznany"
    Then I should see statistics
    And I should not see link to line's timetables
    And I should not see link to opposite line

  Scenario: displaying competed line with opposite line
    Given only line with no "16", begin "01.01.2009" exists
    And line with no "16", begin "01.01.2009" exists
    When I go to /lines
    And I follow "Nieznany"
    Then I should see link to opposite line

  Scenario: displaying competed line (without opposite)
    Given only line with no "4", begin "01.01.2009" exists
    And the following stops exist in the system:
      | name        | lat     | lon         | trams |
      | Lubicz      | 13.2345 | 20.1234     | true  |
      | Urzędnicza  | 1.12346 | 50.12345678 | true  |
      | Biprostal   | 13.2345 | 20.1234     | true  |
      | Wesele      | 13.2345 | 20.1234     | true  |
    And random timetables connecting given line and stops
    When I go to /lines
    And I follow "Wesele"
    Then I should see statistics
    And I should see line's route
    And I should see link to line's timetables

  Scenario Outline: accessing show line page by it's number and direction
    Given only lines with no "<no>", beginning "<beginning>" and direction "<direction>"
    When I go to /lines/<no>-<beginning>
    And I should see line's route beginning with "<direction>"
    When I go to /lines/<no>-<direction>
    And I should see line's route beginning with "<beginning>"
  
  Examples: lines with opposites
    | no  | beginning | direction   |
    | 4   | AWF       | Struga      |
    | 114 | Ruczaj    | Wyki        |
    | 144 | Wlotowa   | Makowskiego |
    | 601 | Kombinat  | Bronowice   |