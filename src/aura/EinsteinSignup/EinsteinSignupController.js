({
    handleClick : function(component, event, helper) {
        //    public static void EinsteinSignup (string firstname, string lastname, string email, string username){
        
        var action = component.get("c.EinsteinSignup");
        action.setParams({
            "firstname" : component.get("v.firstName"),
            "lastname" : component.get("v.lastName"),
            "email" : component.get("v.email"),
            "username" : component.get("v.username")            
        });
        action.setCallback( this, function (a){
            console.log(a);
            component.set("v.status", a.getState());
            if (a.getState()==="SUCCESS"){
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        "title": "Success!",
                        "message": "Check your email for the signup link",
                        "mode" : "sticky",
                        "type" : "success"
                    });
                    toastEvent.fire();
                
            }
        });
        $A.enqueueAction(action);
    }
})