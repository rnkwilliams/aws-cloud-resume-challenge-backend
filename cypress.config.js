const { defineConfig } = require("cypress");

module.exports = defineConfig({
  e2e: {
    setupNodeEvents(on, config) {
      // implement node event listeners here
    },
    baseUrl:
      "https://dwr7wvsxisifgqhvyq5qvcgmdu0svufq.lambda-url.us-east-1.on.aws/",
  },
});
