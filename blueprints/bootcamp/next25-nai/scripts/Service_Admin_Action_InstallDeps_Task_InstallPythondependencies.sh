#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

## install boto3 and dotenv
## required for Objects configuration
pip install boto3 dotenv