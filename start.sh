#!/usr/bin/env bash
set -e

source .env

if [[ -z "${HOSTNAME}" ]]; then
  echo "Set the HOSTNAME environment variable!"
  exit 1
fi

# the directory of the script
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# the temp directory used, within $DIR
# omit the -p parameter to create a temporal directory in the default location
WORK_DIR=$(mktemp -d -p "$DIR")

# check if tmp dir was created
if [[ ! "$WORK_DIR" || ! -d "$WORK_DIR" ]]; then
  echo "Could not create temp dir"
  exit 1
fi

# deletes the temp directory
function cleanup {
  rm -rf "$WORK_DIR"
  echo "Deleted temp working directory $WORK_DIR"
}

# register the cleanup function to be called on the EXIT signal
trap cleanup EXIT

# Copy all files to the temp directory, envsubsting them on the way
for file in $(find . -type f -not -path './.git/*' -not -path './.env' -not -path './.gitignore'); do
  mkdir -p "$WORK_DIR/$(dirname "${file}")"
  envsubst '$NAME $REGION $HOSTNAME $LEMMY_ADMIN_USERNAME $LEMMY_ADMIN_PASSWORD $LEMMY_EMAIL_SMTP_SERVER $LEMMY_EMAIL_SMTP_LOGIN $LEMMY_EMAIL_SMTP_PASSWORD $PICTRS_API_KEY' < "$file" > "$WORK_DIR/$file"
done

# Create our applications
fly apps create "${NAME}-lemmy-ui" || true
fly deploy -a "${NAME}-lemmy-ui" -c "${WORK_DIR}/fly/lemmy-ui.toml" "${WORK_DIR}"

fly apps create "${NAME}-pictrs" || true
fly deploy -a "${NAME}-pictrs" -c "${WORK_DIR}/fly/pictrs.toml" "${WORK_DIR}"

fly pg create --initial-cluster-size=1 -n "${NAME}-lemmy-postgres" -r "${REGION}" --volume-size=10 --vm-size="shared-cpu-1x" || true
fly apps create "${NAME}-lemmy" || true
fly pg attach -a "${NAME}-lemmy" -c "${WORK_DIR}/fly/lemmy.toml" --variable-name LEMMY_DATABASE_URL "${NAME}-lemmy-postgres" || true
fly deploy -a "${NAME}-lemmy" -c "${WORK_DIR}/fly/lemmy.toml" "${WORK_DIR}"

fly apps create "${NAME}-lemmy-proxy" || true
fly deploy -a "${NAME}-lemmy-proxy" -c "${WORK_DIR}/fly/proxy.toml" "${WORK_DIR}"
fly certs create --app "${NAME}-lemmy-proxy" "${HOSTNAME}" || true
fly certs create --app "${NAME}-lemmy-proxy" "*.${HOSTNAME}" || true
