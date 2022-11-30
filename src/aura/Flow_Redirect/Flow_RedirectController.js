({
	invoke : function(component, event, helper) {
		var urlRedirect = component.get("v.urlString") + component.get("v.recordId");
    	var redirect = $A.get("e.force:navigateToURL");
		redirect.setParams({
        	"url": urlRedirect
		});
		// Open the record
		redirect.fire(); 
  	}
})