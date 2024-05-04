function ensure_hc_tool() {
    local TOOL=$1
    local VERSION=$2
    local DIR
    DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

    platform=$(uname -s)

    if [ "${platform}" == "Darwin" ] || [ "${platform}" == "Linux" ]; then
        PLATFORM=${platform,,}
    else
        echo "Platform ${platform} is currently not supported" >&2 && exit 1
    fi

    arch="$(uname -m)"
    if [ "${arch}" == "x86_64" ]; then
        ARCH="amd64"
    elif [ "${arch}" == "arm64" ]; then
        ARCH="arm64"
    else
        echo "Unsupported architecture: [${arch}], only [x86_64, arm64] are supported for now" >&2 && exit 1
    fi

    ARCHIVE="${TOOL}_${VERSION}_${PLATFORM}_${ARCH}.zip"
    CACHE_DIR="${TOOL}-${VERSION}"

    if ! [ -f "$DIR/.cache/${CACHE_DIR}/BOOTSTRAPPED" ]; then
        echo "Missing ${TOOL} binary for version [${VERSION}] -- will download." >&2
        PACKAGE_FULL_URL="https://releases.hashicorp.com/${TOOL}/${VERSION}/${ARCHIVE}"
        mkdir -p "$DIR/.cache"
        pushd "$DIR/.cache" >/dev/null 2>&1 || exit 1
        echo "Downloading ${PACKAGE_FULL_URL}..." >&2
        curl -#L -O "${PACKAGE_FULL_URL}" ||
            (echo "Failed to download ${PACKAGE_FULL_URL}." && exit 1)

        (rm -rf "${CACHE_DIR}" &&
            unzip "${ARCHIVE}" -d "${CACHE_DIR}") >&2 ||
            (echo "Failed to extract ${PACKAGE_FULL_URL}." && exit 1)
        rm -rf "${ARCHIVE}"
        touch "${CACHE_DIR}/BOOTSTRAPPED"
        popd >/dev/null 2>&1 || exit 2
    fi

    echo "${DIR}/.cache/${TOOL}-${VERSION}/${TOOL}"
}
