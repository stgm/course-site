set -euxo pipefail

docker buildx build --platform linux/amd64 . -t fnwicr.azurecr.io/minprog
docker push fnwicr.azurecr.io/minprog    

VERSION="0.2.6"
NAME="minprog"
helm package --version "${VERSION}" --app-version "${VERSION}" "charts/${NAME}"
#helm chart save "${NAME}-${VERSION}.tgz" "fnwicr.azurecr.io/helm/${NAME}:${VERSION}"
helm push "${NAME}-${VERSION}.tgz" oci://fnwicr.azurecr.io/helm