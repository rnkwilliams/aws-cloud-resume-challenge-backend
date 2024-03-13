describe("Test visit count API", () => {
  it("fetches updateViewsCounter", () => {
    cy.request("POST", "/").then((response) => {
      const data = response.body;

      expect(response.status).to.eq(200);

      expect(data).to.not.be.oneOf([null, "", undefined]);
    });
  });
});
