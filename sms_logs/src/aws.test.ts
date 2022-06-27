import { createAlertsConfig, decodeEvent } from "./aws";

const mockGetSecretValue = jest.fn();
jest.mock("@aws-sdk/client-secrets-manager", () => ({
  SecretsManager: jest.fn().mockImplementation(() => ({
    getSecretValue: mockGetSecretValue,
  })),
}));

describe("aws", () => {
  describe("decodeEvent", () => {
    test("works", () => {
      const data = { hello: "world" };

      const ev = {
        awslogs: {
          data: Buffer.from(JSON.stringify(data)).toString("base64"),
        },
      };

      expect(decodeEvent(ev)).toStrictEqual(data);
    });
  });

  describe("createAlertsConfig", () => {
    afterEach(() => {
      mockGetSecretValue.mockReset();
    });

    test("gets secrets from AWS Secrets Manager", async () => {
      mockGetSecretValue.mockImplementation(
        ({ SecretId }: { SecretId: string }) =>
          Promise.resolve({ SecretString: SecretId })
      );
      await createAlertsConfig();

      expect(mockGetSecretValue).toHaveBeenCalledWith({
        SecretId: "alerts-sms-failure-key",
      });
      expect(mockGetSecretValue).toHaveBeenCalledWith({
        SecretId: "alerts-dev-sms-failure-key",
      });
      expect(mockGetSecretValue).toHaveBeenCalledWith({
        SecretId: "alerts-dev-green-sms-failure-key",
      });
    });

    test("throws when secret has no SecretString", async () => {
      mockGetSecretValue.mockImplementation(
        ({ SecretId }: { SecretId: string }) =>
          Promise.resolve({ SecretBinary: SecretId })
      );

      expect(async () => {
        await createAlertsConfig();
      }).rejects.toThrowError();
    });
  });
});
