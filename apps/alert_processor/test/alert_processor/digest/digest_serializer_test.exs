defmodule AlertProcessor.DigestSerializerTest do
  @moduledoc false
  use AlertProcessor.DataCase

  alias AlertProcessor.{DigestSerializer, Model}
  alias Model.{Alert, Digest, DigestDateGroup, User}
  alias Calendar.DateTime, as: DT

 @alert1 %Alert{
    id: "1",
    header: "test1",
    service_effect: "s1"
  }

  @alert2 %Alert{
    id: "2",
    header: "test2",
    service_effect: "s2"
  }

  @user %User{id: "1"}

  @saturday DT.from_erl!({{2017, 06, 03}, {0, 0, 0}}, "America/New_York")
  @sunday DT.from_erl!({{2017, 06, 04}, {23, 59, 59}}, "America/New_York")
  @monday DT.from_erl!({{2017, 06, 05}, {0, 0, 0}}, "America/New_York")
  @friday DT.from_erl!({{2017, 06, 09}, {23, 59, 59}}, "America/New_York")
  @next_saturday DT.from_erl!({{2017, 06, 10}, {0, 0, 0}}, "America/New_York")
  @next_sunday DT.from_erl!({{2017, 06, 11}, {23, 59, 59}}, "America/New_York")
  @next_monday DT.from_erl!({{2017, 06, 12}, {0, 0, 0}}, "America/New_York")
  @future DT.from_erl!({{3017, 06, 03}, {0, 0, 0}}, "America/New_York")

  @ddg %DigestDateGroup{
    upcoming_weekend: %{
      timeframe: {@saturday, @sunday},
      alert_ids: ["1"]
    },
    upcoming_week: %{
      timeframe: {@monday, @friday},
      alert_ids: ["1", "2"]
    },
    next_weekend: %{
      timeframe: {@next_saturday, @next_sunday},
      alert_ids: ["1"]
    },
    future: %{
      timeframe: {@next_monday, @future},
      alert_ids: ["1"]
    }
  }

  test "serialize/1 returns a map that mimics the email layout with titles" do
    digest = %Digest{
      user: @user,
      alerts: [@alert1, @alert2],
      digest_date_group: @ddg
    }

    serialized_digest = DigestSerializer.serialize(digest)

    expected = %{
      upcoming_weekend: %{
        alerts: [@alert1],
        title: "This Weekend, June 3 - 4"
      },
      upcoming_week: %{
        alerts: [@alert1, @alert2],
        title: "Next Week, June 5 - 9"
      },
      next_weekend: %{
        alerts: [@alert1],
        title: "Next Weekend, June 10 - 11"
      },
      future: %{
        alerts: [@alert1],
        title: "Future Alerts"
      },
    }

    assert serialized_digest == expected
  end

  test "serialize/1 filters alerts that don't belong to that user" do
    digest = %Digest{
      user: @user,
      alerts: [@alert1],
      digest_date_group: @ddg
    }

    serialized_digest = DigestSerializer.serialize(digest)

    expected = %{
      upcoming_weekend: %{
        alerts: [@alert1],
        title: "This Weekend, June 3 - 4"
      },
      upcoming_week: %{
        alerts: [@alert1],
        title: "Next Week, June 5 - 9"
      },
      next_weekend: %{
        alerts: [@alert1],
        title: "Next Weekend, June 10 - 11"
      },
      future: %{
        alerts: [@alert1],
        title: "Future Alerts"
      },
    }

    assert serialized_digest == expected
  end

  test "serialize/1 removes sections with no alerts" do
    digest = %Digest{
      user: @user,
      alerts: [@alert2],
      digest_date_group: @ddg
    }

    serialized_digest = DigestSerializer.serialize(digest)

    expected = %{
      upcoming_week: %{
        alerts: [@alert2],
        title: "Next Week, June 5 - 9"
      }
    }

    assert serialized_digest == expected
  end
end
