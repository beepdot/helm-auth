import os, requests, jwt, subprocess
import sys

osEnv = dict(os.environ)
url = os.environ.get("KONG_ADMIN_URL", "http://kong:8001")
checkIfSecretExistsCommand = os.environ.get("CHECK_SECRETS_COMMAND", "kubectl get secrets kong-jwt-secrets")
createSecretCommand = os.environ.get("CREATE_SECRETS_COMMAND", "kubectl create secret generic kong-jwt-secrets --from-env-file /tmp/tokens.txt")
replaceSecretCommand = os.environ.get("REPLACE_SECRETS_COMMAND", "kubectl create secret generic kong-jwt-secrets --from-env-file /tmp/tokens.txt -o=yaml --dry-run=client | kubectl replace -f -")
consumerPath = "/consumers"
jwtPath = "/jwt"
params = {"size": 1}
consumerList = os.environ.get("CONSUMER_LIST", "api-admin, echo-user")
consumerList = consumerList.split(",")
jwtTokenFile = open("/tmp/tokens.txt", "w")
consumers = requests.get(url = url + consumerPath).json()['data']
for c in consumerList:
    jwts = requests.get(url = url + consumerPath + "/" + c.strip() + jwtPath, params=params)
    if jwts.status_code == 200:
      key = jwts.json()['data'][0]['key']
      secret = jwts.json()['data'][0]['secret']
      encoded_jwt = jwt.encode({"iss": key}, key=secret, algorithm="HS256")
      jwtTokenFile.writelines(c.strip() + "=" + encoded_jwt + "\n")
jwtTokenFile.close()
secretExists = subprocess.run(checkIfSecretExistsCommand.split(), stderr=subprocess.DEVNULL, stdout=subprocess.DEVNULL)
if secretExists.returncode != 0:
    createSecret = subprocess.run(createSecretCommand, shell=True, env=osEnv)
    sys.exit(createSecret.returncode)
else:
    replaceSecret = subprocess.run(replaceSecretCommand, shell=True, env=osEnv)
    sys.exit(replaceSecret.returncode)