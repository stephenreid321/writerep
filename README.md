campaign-kit
=================

 [![Deploy](https://www.herokucdn.com/deploy/button.png)](https://heroku.com/deploy) 

1. Create a new instance of the app by clicking the 'Deploy to Heroku' button above. When it says 'Your app was successfully deployed', click View.
2. Create an account. Log in with the account details.
3. Import some representatives. Visit /import/x, where x is one of

  * mps
  * hackney_councillors
  * london_borough_councillors
  * bristol_city_councillors
  * north_somerset_councillors

  The page will probably time out, but that's OK. You'll get an email when the import is finished.

4. Visit /admin, click 'Campaigns' and create a campaign. (If you're working with councillors, change the postcode lookup url to http://campaign-kit-postcode.herokuapp.com/councillor?postcode=)
5. Click 'View/edit' to return to the campaign, scroll to the bottom and add some decisions (you'll probably want to use the 'Bulk create decisions' tool)
6. Navigate to /campaigns/your-campaign-slug to check out your campaign. Return to /admin to make changes.