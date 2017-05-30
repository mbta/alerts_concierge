defmodule AlertProcessor.DigestDateHelperTest do
  @moduledoc false
  use ExUnit.Case

  alias AlertProcessor.{DigestDateHelper, Model}
  alias Model.{Alert, DigestDateGroup}
  alias Calendar.DateTime, as: DT

  @thursday DT.from_erl!({{2017, 05, 25}, {0, 0, 0}}, "America/New_York")

  @ap1 [
    %{
      start: DT.from_erl!({{2017, 06, 27}, {0, 0, 1}}, "America/New_York"),
      end: DT.from_erl!({{2017, 06, 28}, {0, 0, 0}}, "America/New_York")
     }
  ]

  @ap2 [
    %{
      start: DT.from_erl!({{2017, 05, 30}, {0, 0, 1}}, "America/New_York"),
      end: DT.from_erl!({{2017, 06, 03}, {0, 0, 1}}, "America/New_York")
    }
  ]

  @ap3 [
    %{
      start: DT.from_erl!({{2017, 05, 26}, {1, 0, 1}}, "America/New_York"),
      end: DT.from_erl!({{2017, 05, 26}, {23, 0, 0}}, "America/New_York")
    }
  ]

  @ap4 [
    %{
      start: DT.from_erl!({{2017, 05, 27}, {1, 0, 1}}, "America/New_York"),
      end: DT.from_erl!({{2017, 05, 28}, {23, 0, 0}}, "America/New_York")
    }
  ]


  @alert1 %Alert{
    id: "1",
    header: "test1",
    active_period: @ap1
  }

  @alert2 %Alert{
    id: "2",
    header: "test2",
    active_period: @ap2
  }

  @alert3 %Alert{
    id: "3",
    header: "test3",
    active_period: @ap3
  }

  @alert4 %Alert{
    id: "4",
    header: "test4",
    active_period: @ap4
  }

  test "calculate_date_groups/1 adds date group array to each alert" do
   alerts = [@alert1, @alert2, @alert3, @alert4]

   assert {_alerts, digest_date_group} = DigestDateHelper.calculate_date_groups(alerts, @thursday)
   assert %DigestDateGroup{
     upcoming_weekend: %{
        timeframe: _,
        alert_ids: ["4"]
      },
      upcoming_week: %{
        timeframe: _,
        alert_ids: ["2"]
      },
      next_weekend: %{
        timeframe: _,
        alert_ids: ["2"]
      },
      future: %{
        timeframe: _,
        alert_ids: ["1"]
      }
    } = digest_date_group
  end
end
