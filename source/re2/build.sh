#!/usr/bin/env bash
# Copyright 2015 Cloudera Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Exit on non-true return value
set -e
# Exit on reference to uninitialized variable
set -u

set -o pipefail

source $SOURCE_DIR/functions.sh
THIS_DIR="$( cd "$( dirname "$0" )" && pwd )"
prepare $THIS_DIR

# Download the dependency from S3
download_dependency $PACKAGE "${PACKAGE_STRING}.tgz" $THIS_DIR

if needs_build_package ; then
  setup_package_build $PACKAGE $PACKAGE_VERSION

  # For some reason, re2 doesnt play nice with prefix installations and other
  # typical configuration parameters
  EXTENSION=
  if [[ "$OSTYPE" == "darwin"* ]]; then
    EXTENSION=.bak
  fi
  sed -i $EXTENSION 's/CXXFLAGS=-Wall/CXXFLAGS+=-Wall/' Makefile
  sed -i $EXTENSION 's/LDFLAGS=-pthread/LDFLAGS+=-pthread/' Makefile
  sed -i $EXTENSION 's/CXX=g\+\+/CXX?=g\+\+/' Makefile
  sed -i $EXTENSION 's/prefix=\/usr/prefix?=\/usr/' Makefile
  prefix=$LOCAL_INSTALL wrap make -j${BUILD_THREADS:-4} install

  footer $PACKAGE $PACKAGE_VERSION
fi
