({
	buildUrl : function(component) {
		if (component.get("v.topic")){
			return '/topic/'+component.get("v.topic");
		} else if (component.get("v.platformEvent")){
			return '/event/'+component.get("v.platformEvent");
		} else {
			console.error('Neither the topic nor the platform event is specified');
		}

	}
})