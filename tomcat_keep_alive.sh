requestUrl='http://localhost/NicoTradeJSServer/trade?action=ping'
httpCode=$(curl --connect-timeout 5 --max-time 10 --write-out %{http_code} --silent --output /dev/null "${requestUrl}")
if [ "$httpCode" != "200" ]; then
    systemctl restart tomcat
fi