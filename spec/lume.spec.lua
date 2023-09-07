local describe, it, expect = lust.describe, lust.it, lust.expect


if (get("enviorement") == "development") then
  describe("Lume Suite", function () 
    it("should be able to round a float", function () 
      expect(lume.round(2.3)).to.equal(2);
    end);
  end);
end