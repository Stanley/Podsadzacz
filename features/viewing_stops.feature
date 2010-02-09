Feature: viewing stops
  To get all the informations about some stop
  A user
  Does go to the stops index
  And clicks the category link and clicks a link to stop
  In order to see details and statistics of choosen stop

  Scenario: indexing stops
    Given the following stops exist in the system:
      | name          | lat                 | lng                 | location      |
      | Baszta        | 1.123456789         | 50.123456789012345  |               |
      | Basztowa LOT  | 13.123456789012345  | 20.123456789        |               |
      | Krowoderska   | 2.21441             | 43.12121214578441   | ul. Basztowa  |
    When I go to stops page
    Then I should not see any stops
    And I should see "Live search"

  Scenario: indexing stops' categories
    Given the following stops exist in the system:
      | name          | lat                 | lng                 | location      | buses | trams |
      | Baszta        | 1.123456789         | 50.123456789012345  |               | true  | true  |
      | Basztowa LOT  | 13.123456789012345  | 20.123456789        |               | false | true  |
      | Krowoderska   | 2.21441             | 43.12121214578441   | ul. Basztowa  | false | false |
    When I go to /all-stops
    Then I should see "Przystanki wszystkie"
    And I should see "wszystkie" link highlighted
    And I should see 3 links to "stops"

    When I go to /bus-stops
    Then I should see "Przystanki autobusowe"
    And I should see "autobusowe" link highlighted
    And I should see 1 links to "stops"

  Scenario Outline: displaying stop with no timetables
    Given only stop with name "<name>", lat "<lat>", lng "<lng>" exists
    When I go to /all-stops
    And I follow "<name>"
    Then I should see "<name>"
    And I should see "przystanek nieczynny"

  Examples:
    | name    | lat                 | lng                 |
    | Testowy | 1.123456789         | 50.123456789012345  |
    | Zloc    | 13.123456789012345  | 20.123456789        |

  Scenario Outline: displaying stop with timetable
    Given only stop with name "<stop_name>", lat "<lat>", lng "<lng>" exists
    And only line "<line_no>" exists
    And timetable for given stop and line
    When I go to /all-stops
    And I follow "<stop_name>"
    Then I should see 1 links to "/lines/" as "<line_no>"
    And I should see next departures for line "<line_no>"
    And I should see non-zero stats

  Examples:
    | stop_name | line_no | lat                 | lng                 |
    | Urzędnicza| 12      | 1.123456789         | 50.123456789012345  |
    | AWF       | 4       | 13.123456789012345  | 20.123456789        |

  Scenario Outline: displaying stop with one opposite stop
    Given only stop with name "<name>", lat "<lat>", lng "<lng>" exists
    And 1 opposite stop
    When I go to /all-stops
    And I follow "<name>"
    Then I should see "przystanek w drugą stronę" link

  Examples:
    | name    | lat                 | lng                 |
    | Testowy | 1.123456789         | 50.123456789012345  |
    | Zloc    | 13.123456789012345  | 20.123456789        |

  Scenario: displaying stop many opposite stop
    Given only stop with name "Testowy", lat "13.12", lng "13.42" exists
    And 3 opposite stops
    When I go to /all-stops
    Then I should see 4 links to "/stops/" as "Testowy"
    When I go to /all-stops
    And I follow "Testowy"
    Then I should see "Przesiadki"
    And I should see 3 links to "/stops/" as "Testowy"