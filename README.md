# Predictive Vision Service

### PVS (currently pilot) classifies photos.  
Docs are here:
http://docs.metamind.io/docs/introduction-to-the-einstein-predictive-vision-service

## Goal of this project
* Access the predictive vision without writing code

### User creates a model and labels using Salesforce objects

  * Users can control the probability threshold and whether secondary predictions are shown.
  * Users can view (Lightning Experience Only) the model's statistics via a Lightning Component
  * Users can access the auth tokens via the browser console

### Users get predictions

* Invoke the model by posting either a file or an image to the chatter feed for that Label.  
* Einstein (via another user) will chatter back the predictions according to the model's settings.

### Users can create examples via a local .bash script

```
	~/code/EinsteinVision/directoryUploader.sh c7f7d45327504236c6dfd897cbeffd42a40be485 1952 795
```
where the three parameters are the `token`, the `labelId`, and the `modelId`.

This script will take every image in the user's current directory and upload it to that indicated label.

You can get the token by looking in the browser console of the Model record in Salesforce.

### Custom Settings

* Manage your Einstein Credentials
* Manage the security cert used when you sign up for an account

### Known issues
There's a button to kick off the model training, but it always seems to return a 403/forbidden.  Kick off model training via Postman or similar API-calling tool.  You can use the token from the model's Salesforce record page.

