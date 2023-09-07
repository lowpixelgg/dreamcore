local describe, it, expect = lust.describe, lust.it, lust.expect


if (process.env.enableSuiteTests) then 
  describe("Environment Variables Suite", function () 
    lust.before(function () 
      env.config(".env-spec");
    end)

    it("should be able to get environment variables", function () 
      expect(process.env.ctf).to.equal(true);
    end);
  end)
end