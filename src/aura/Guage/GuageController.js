/* global JustGage */

({
	afterScriptsLoaded : function(component, event, helper) {
		console.log('in afterScriptsLoaded');

    let left = new JustGage({
			id: "left", // How can I pass in just the Id of the HTML element?
    	value: 67,
    	min: 0,
    	max : 100,
    	title: "Left"
    });

	}
})