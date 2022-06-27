import l from "aws-lambda";
import { z } from "zod";
import fetch from "node-fetch";

export const SMSDeliveryFailureLog = z.object({
  delivery: z.object({
    destination: z.string(),
    providerResponse: z.string(),
  }),
  status: z.literal("FAILURE"),
});
export type SMSDeliveryFailureLog = z.infer<typeof SMSDeliveryFailureLog>;

export function parseFailureLogs(data: l.CloudWatchLogsDecodedData) {
  return data.logEvents.map((ev) => {
    const obj = JSON.parse(ev.message);
    const parsed = SMSDeliveryFailureLog.parse(obj);

    return {
      number: parsed.delivery.destination,
      message: parsed.delivery.providerResponse,
    };
  });
}

export interface Config {
  endpoints: {
    url: string;
    secret: string;
  }[];
}

export async function forward(
  data: l.CloudWatchLogsDecodedData,
  config: Config
) {
  const logs = parseFailureLogs(data);

  const promises = config.endpoints.map(async ({ url, secret }) => {
    const res = await fetch(url, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
      },
      body: JSON.stringify({ logs, secret }),
    });

    if (!res.ok) {
      throw new Error(
        `POST to ${url} failed with status ${res.status}: ${await res.text()}`
      );
    }
  });

  await Promise.all(promises);
}
