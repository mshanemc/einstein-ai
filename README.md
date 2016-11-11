# Predictive Vision Service

### PVS (currently pilot) classifies photos.  
Docs are here:
http://docs.metamind.io/docs/introduction-to-the-einstein-predictive-vision-service

## Goal of this project
* Access the predictive vision in Salesforce without writing code

### User creates a model and labels using Salesforce objects

  * Users can control the probability threshold and whether secondary predictions are shown.
  * Users can view (Lightning Experience Only) the model's statistics via a Lightning Component
  * Users can access the auth tokens via the browser console

### Users can clean up after themselves

* deleting a model in Salesforce deletes it from the PVS

### Users get predictions

* Invoke the model by posting either a file or an image to the chatter feed for that Label.  
* Einstein (via another user) will chatter back the predictions according to the model's settings.

### Users can create examples via a local .bash script

```
	~/SomeOther/Place/directoryUploader.sh c7f7d45327504236c6dfd897cbeffd42a40be485 1952 795
```
where the three parameters are the `token`, the `labelId`, and the `modelId`.

After you create a model and some labels, click on a label to view the label-specific terminal command to run, including a valid token (#onlyInLightning).  You're welcome!

This directoryUploader will take every image in the user's current directory and upload it to that indicated label. Notice that the script is in some other place, and the current directory only has the images in it.

### Users can train a model

Just hit the train button on a model and the code will handle the rest #onlyInLightning Love those new Lightning Actions!

### Custom Settings

* Manage your Einstein Credentials
* Manage the security cert used when you sign up for an account
* **Be sure to populate these before trying to use the service** 

### Using Standard Models
* For the food model, set the `Einstein Trained Model Id` to `FoodImageClassifier`
* For the general model, set the `Einstein Trained Model Id` to `GeneralImageClassifier`

### Fun things to do
* be sure to walk around with Salesforce1 attaching photos to a model of anything around.
* Have Einstein idenfity dog breeds

## Basic Setup

1. First, install this repo into your org.

<a href="https://githubsfdeploy.herokuapp.com">
  <img alt="Deploy to Salesforce"
       src="https://raw.githubusercontent.com/afawcett/githubsfdeploy/master/deploy.png">
</a>


2. Create your self-signed certificate and metamind org per http://docs.metamind.io/docs/what-you-need-to-call-api . Stop where it says *Scenario*.
3. In Salesforce, go to Custom Settings, to EinsteinVision, and then click Manage.
4. Create a new setting at the organizational default level
5. Set the Einstein Username you signed up with, and CertName to be the name of the cert from step 2.  
6. Pick a userId to be the Einstein user (bonus points for having a user named Einstein and setting their chatter picture!). 
7. token expiration time should be 3600
8. certificate issuer: developer.force.com
9. *Try the standard model*: In Salesforce, create a model (you can call it anything) and set the `Einstein Trained Model Id` to `GeneralImageClassifier`
10. Post an image as a file or as a link to the Chatter feed.
11. Click on the comment box (live feed) or reload the page to see the response
