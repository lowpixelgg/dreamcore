local describe, it, expect = lust.describe, lust.it, lust.expect


if (false) then 
  describe("Namespacer Suite", function () 
    it("should be able to create a namespacer", function () 
      local namespace = class:create("test-namespace");
  
      expect(namespace).to.be.a('table');
    end)
  
    it("should not be able to create a namespace with an existing name", function () 
      local namespace1 = class:create("test-namespace1");
      local namespace2 = class:create("test-namespace1");
  
      expect(namespace1).to.be.a('table');
      expect(namespace2).to.equal(false);
    end)
  
  
    it("should be able to call methods", function () 
      local namespace = class:create("test-methods");
      namespace.public.test = true;
      namespace.private.test = false;
  
      expect(namespace.public.test).to.equal(true);
      expect(namespace.private.test).to.equal(false);
    end)
  end)
end