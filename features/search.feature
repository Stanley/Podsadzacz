Feature: search connections
  To find connections between stops
  A user
  Does fill form

  Scenario Outline:
    Given all lines
    And all stops
    And all timetables
    When I go to /search
    And I fill in "from" with "<start>"
    And I fill in "to" with "<meta>"
    And I select in "mode" with "<mode>"
    And I select in "hour" with "<time>"
    And I select in "day" with "<day>"
    And I press "Szukaj"
    Then I should see "Wyniki wyszukiwania"

  Examples: valid data
    | start       | meta        | mode       | time  | day         |
    | Urzędnicza  | Korona      | Przyjazdu  | 12:00 | 01.04.2009  |
    | AWF         | Filharmonia | Odjazdu    | 14:30 | 15.03.2009  |

  Scenario Outline:
    Given all lines
    And all stops
    And all timetables
    When I go to /search
    And I fill in "from" with "<start>"
    And I fill in "to" with "<meta>"
    And I select in "mode" with "<mode>"
    And I select in "hour" with "<time>"
    And I select in "day" with "<day>"
    And I press "Szukaj"
    Then I should see "Błąd"

  Examples: invalid data
    | start       | meta        | mode       | time  | day         |
    |             | Korona      | Przyjazdu  | 12:00 | 01.04.2009  |
    | AWF         |             | Odjazdu    | 14:30 | 15.03.2009  |