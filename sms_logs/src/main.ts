import l from "aws-lambda";
import { AWSLambda as Sentry } from "@sentry/serverless";

import { forward } from "./alerts";
import { decodeEvent, createAlertsConfig } from "./aws";

Sentry.init();

async function handle(event: l.CloudWatchLogsEvent) {
  const alertsConfig = await createAlertsConfig();
  const logData = decodeEvent(event);

  await forward(logData, alertsConfig);
}

export const handler = Sentry.wrapHandler(handle);
