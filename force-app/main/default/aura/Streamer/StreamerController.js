/* global $ */

({
    doInit : function(component, event, helper) {
        console.log('doing init on streamer');

        // Retrieve the session id and initialize cometd
        let sessionAction = component.get("c.sessionId");
        let url = helper.buildUrl(component);

        sessionAction.setCallback(this, function(response) {
            let state = response.getState();
            if(state  === "SUCCESS") {
                let sessionId = response.getReturnValue();
                let authstring = "OAuth " + sessionId;

                //authenticate to the Streaming API
                $.cometd.init({
                    url: window.location.protocol + '//' + window.location.hostname + '/cometd/40.0/',
                    requestHeaders: { Authorization: authstring },
                    appendMessageTypeToURL : false
                });

                $.cometd.subscribe(url, function (message){
                    let evt = $A.get("e.ltng:sendMessage");
                    evt.setParams({"message" : message, "channel" : "streamingAPISubscriber"});
                    evt.fire();
                });
            }

        });

        $A.enqueueAction(sessionAction);
    }
})