defmodule AlertProcessor.DigestDateHelperTest do
  @moduledoc false
  use ExUnit.Case

  alias AlertProcessor.{DigestDateHelper, Model, Helpers.DateTimeHelper}
  alias Model.{Alert, DigestDateGroup}
  alias Calendar.DateTime, as: DT

  @thursday DT.from_erl!({{2017, 05, 25}, {0, 0, 0}}, "America/New_York")

  @ap1 [
    %{
      start: DT.from_erl!({{2017, 06, 27}, {2, 30, 0}}, "America/New_York"),
      end: DT.from_erl!({{2017, 06, 28}, {0, 0, 0}}, "America/New_York")
     }
  ]

  @ap2 [
    %{
      start: DT.from_erl!({{2017, 05, 30}, {2, 30, 0}}, "America/New_York"),
      end: DT.from_erl!({{2017, 06, 01}, {2, 30, 1}}, "America/New_York")
    },
    %{
      start: DT.from_erl!({{2017, 06, 03}, {2, 30, 0}}, "America/New_York"),
      end: DT.from_erl!({{2017, 06, 04}, {2, 30, 1}}, "America/New_York")
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
      start: DT.from_erl!({{2017, 05, 27}, {2, 30, 0}}, "America/New_York"),
      end: DT.from_erl!({{2017, 05, 28}, {23, 0, 0}}, "America/New_York")
    }
  ]

  @ap5 [
    %{
      start: DT.from_erl!({{2017, 05, 29}, {2, 30, 0}}, "America/New_York"),
      end: nil
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

  @alert5 %Alert{
    id: "5",
    header: "test5",
    active_period: @ap5
  }

  test "calculate_date_groups/1 adds date group array to each alert" do
   alerts = [@alert1, @alert2, @alert3, @alert4]
   upcoming_weekend = DateTimeHelper.upcoming_weekend(@thursday)
   upcoming_week = DateTimeHelper.upcoming_week(@thursday)
   next_weekend = DateTimeHelper.next_weekend(@thursday)
   future = DateTimeHelper.future(@thursday)

   assert {_alerts, digest_date_group} = DigestDateHelper.calculate_date_groups(alerts, @thursday)
   assert %DigestDateGroup{
     upcoming_weekend: %{
        timeframe: u_weekend,
        alert_ids: ["4"]
      },
      upcoming_week: %{
        timeframe: u_week,
        alert_ids: ["2"]
      },
      next_weekend: %{
        timeframe: n_weekend,
        alert_ids: ["2"]
      },
      future: %{
        timeframe: fut,
        alert_ids: ["1"]
      }
    } = digest_date_group

    assert u_weekend == upcoming_weekend
    assert u_week == upcoming_week
    assert n_weekend == next_weekend
    assert fut == future
  end

  test "handle for nil active_period.end" do
    alerts = [@alert5]

    assert {_alerts, digest_date_group} = DigestDateHelper.calculate_date_groups(alerts, @thursday)
    assert %DigestDateGroup{
     upcoming_weekend: %{
        timeframe: _u_weekend,
        alert_ids: []
      },
     upcoming_week: %{
        timeframe: _u_week,
        alert_ids: ["5"]
      },
      next_weekend: %{
        timeframe: _n_weekend,
        alert_ids: []
      },
      future: %{
        timeframe: _fut,
        alert_ids: []
      }
    } = digest_date_group
  end
end
