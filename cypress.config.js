const { defineConfig } = require("cypress");

module.exports = defineConfig({
  e2e: {
    setupNodeEvents(on, config) {
      // implement node event listeners here
    },
    baseUrl:
      "https://yl6ejqfirwkzfnk7tdwhisc2fa0dmndm.lambda-url.us-east-1.on.aws/",
  },
});
