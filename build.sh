set -euxo pipefail

docker build . -t fnwicr.azurecr.io/minprog
docker push fnwicr.azurecr.io/minprog    

VERSION="0.2.3"
NAME="minprog"
helm package --version "${VERSION}" --app-version "${VERSION}" "charts/${NAME}"
helm chart save "${NAME}-${VERSION}.tgz" "fnwicr.azurecr.io/helm/${NAME}:${VERSION}"
helm chart push "fnwicr.azurecr.io/helm/${NAME}:${VERSION}"