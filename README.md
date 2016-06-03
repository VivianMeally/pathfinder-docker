Start it with
docker run -p 80:80 -e HOSTNAME=<HOSTNAME> -e SSO_CCP_CLIENT_ID=<CLIENTID> -e SSO_CCP_SECRET_KEY=<SECRETKEY> vivianmeally/pathfinder

Before run, you need to create a application under https://developers.eveonline.com/applications CALLBACK_URL is http://<HOSTNAME>/sso/callbackAuthorization
