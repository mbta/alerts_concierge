import l from "aws-lambda";
import { SecretsManager } from "@aws-sdk/client-secrets-manager";

export function decodeEvent(
  ev: l.CloudWatchLogsEvent
): l.CloudWatchLogsDecodedData {
  const data = ev.awslogs.data;
  const log = Buffer.from(data, "base64").toString("utf8");
  const logData: l.CloudWatchLogsDecodedData = JSON.parse(log);

  return logData;
}

export async function createAlertsConfig() {
  const client = new SecretsManager({ region: "us-east-1" });

  const endpoints = await Promise.all(
    ["alerts", "alerts-dev", "alerts-dev-green"].map(async (s) => {
      const url = `https://${s}.mbtace.com/sms_failure`;
      const secretName = `${s}-sms-failure-key`;
      const secret = await client.getSecretValue({
        SecretId: secretName,
      });

      const secretString = secret.SecretString;
      if (!secretString) {
        throw new Error(
          `SecretString for ${secretName} was undefined. Is the secret set up as a string in AWS?`
        );
      }

      return {
        url,
        secret: secretString,
      };
    })
  );

  return { endpoints };
}
