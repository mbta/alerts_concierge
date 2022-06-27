/* eslint-disable @typescript-eslint/no-explicit-any */

import { parseFailureLogs, forward } from "./alerts";

jest.mock("node-fetch");
import fetch from "node-fetch";
const fetchMock = fetch as unknown as jest.Mock<typeof fetch>;

function message(destination: string) {
  return {
    message: JSON.stringify({
      delivery: {
        destination,
        providerResponse: "Phone number is unavailable",
      },
      status: "FAILURE",
    }),
  };
}

describe("alerts", () => {
  describe("failureLogs", () => {
    test("works with valid data", async () => {
      const number1 = "+18008675309";
      const number2 = "+1800MYLEMON";
      const event = {
        logEvents: [message(number1), message(number2)],
      } as any;

      const [{ number: a }, { number: b }] = parseFailureLogs(event);

      expect(a).toBe(number1);
      expect(b).toBe(number2);
    });
  });

  describe("forward", () => {
    test("fetches endpoint properly", async () => {
      fetchMock.mockReturnValue(Promise.resolve({ ok: true }) as any);
      const event = {
        logEvents: [message("a"), message("b")],
      } as any;
      const logs = [...parseFailureLogs(event)];

      const secretA = "a";
      const secretB = "b";

      await forward(event, {
        endpoints: [
          {
            url: "https://test.com/a",
            secret: secretA,
          },
          {
            url: "https://test.com/b",
            secret: secretB,
          },
        ],
      });

      expect(fetchMock).toHaveBeenCalledWith("https://test.com/a", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify({ logs, secret: secretA }),
      });
      expect(fetchMock).toHaveBeenCalledWith("https://test.com/b", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify({ logs, secret: secretB }),
      });
    });

    test("throws when fetch fails", async () => {
      fetchMock.mockReturnValue(
        Promise.resolve({
          ok: false,
          status: 400,
          text: () => "test",
        }) as any
      );

      const event = {
        logEvents: [message("a"), message("b")],
      } as any;

      await expect(
        forward(event, {
          endpoints: [
            {
              url: "https://test.com",
              secret: "secret",
            },
          ],
        })
      ).rejects.toThrow(
        "POST to https://test.com failed with status 400: test"
      );

      fetchMock.mockReset();
    });
  });
});
