#!/usr/bin/env bash

# Copyright The Helm Authors.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
set -euo pipefail

# Skip on pull request builds
if [[ -n "${CIRCLE_PR_NUMBER:-}" ]]; then
  exit
fi

: ${AWS_ACCESS_KEY_ID:?"AWS_ACCESS_KEY_ID environment variable is not set"}
: ${AWS_ACCESS_KEY_SECRET:?"AWS_ACCESS_KEY_SECRET environment variable is not set"}
: ${AWS_STORAGE_BUCKET_NAME:?"AWS_STORAGE_BUCKET_NAME environment variable is not set"}


VERSION=
if [[ -n "${CIRCLE_TAG:-}" ]]; then
  VERSION="${CIRCLE_TAG}"
elif [[ "${CIRCLE_BRANCH:-}" == "main" ]]; then
  VERSION="canary"
else
  echo "Skipping deploy step; this is neither a releasable branch or a tag"
  exit
fi

echo "Installing AWS CLI"
sudo apt install apt-transport-https
sudo apt update
sudo apt install awscli

aws configure set aws_access_key_id ${AWS_ACCESS_KEY_ID}
aws configure set aws_secret_access_key ${AWS_ACCESS_KEY_SECRET}

echo "Building helm binaries"
make build-cross
make dist checksum VERSION="${VERSION}"


echo "Pushing binaries to AWS"
if [[ "${VERSION}" == "canary" ]]; then
  aws s3 cp ./_dist/linux-amd64/helm s3://${AWS_STORAGE_BUCKET_NAME}/helm-${VERSION}/
else
  aws s3 cp ./_dist/linux-amd64/helm s3://${AWS_STORAGE_BUCKET_NAME}/helm/
fi
