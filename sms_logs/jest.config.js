export default {
  preset: "ts-jest",
  resetModules: true,
  testEnvironment: "node",
  transform: { "^.+\\.(ts|tsx|js)$": "ts-jest" },
  transformIgnorePatterns: [],
  testPathIgnorePatterns: ["/node_modules/", "/build/", "/dist/"],
};
