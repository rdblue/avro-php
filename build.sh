#!/bin/bash

# Licensed to the Apache Software Foundation (ASF) under one or more
# contributor license agreements.  See the NOTICE file distributed with
# this work for additional information regarding copyright ownership.
# The ASF licenses this file to You under the Apache License, Version 2.0
# (the "License"); you may not use this file except in compliance with
# the License.  You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

set -e

cd `dirname "$0"`

dist_dir="../../dist/php"
build_dir="pkg"
version=$(cat VERSION)
libname="avro-php-$version"
lib_dir="$build_dir/$libname"
tarball="$libname.tar.bz2"

test_tmp_dir="test/tmp"

function clean {
    rm -rf "$test_tmp_dir"
    rm -rf "$build_dir"
}

function dist {
    mkdir -p "$build_dir/$libname" "$lib_dir/examples"
    cp -pr lib "$lib_dir"
    cp -pr examples/*.php "$lib_dir/examples"
    cp README.txt LICENSE NOTICE "$lib_dir"
    cd "$build_dir"
    tar -cjf "$tarball" "$libname"
    mkdir -p "../$dist_dir"
    cp "$tarball" "../$dist_dir"
}

case "$1" in
     interop-data-generate)
       php test/generate_interop_data.php
       ;;

     test-interop)
       phpunit test/InterOpTest.php
       ;;

     test)
       phpunit test/AllTests.php
       ;;

     dist)
        dist
       ;;

     clean)
       clean
       ;;

     docker)
       docker build -t avro-php .
       if [ "$(uname -s)" == "Linux" ]; then
         USER_NAME=${SUDO_USER:=$USER}
         USER_ID=$(id -u $USER_NAME)
         GROUP_ID=$(id -g $USER_NAME)
       else # boot2docker uid and gid
         USER_NAME=$USER
         USER_ID=1000
         GROUP_ID=50
       fi
       docker build -t avro-php-${USER_NAME} - <<UserSpecificDocker
FROM avro-build
RUN groupadd -g ${GROUP_ID} ${USER_NAME} || true
RUN useradd -g ${GROUP_ID} -u ${USER_ID} -k /root -m ${USER_NAME}
ENV HOME /home/${USER_NAME}
UserSpecificDocker
       docker run --rm=true -t -i \
         -v ${PWD}:/home/${USER_NAME}/avro \
         -w /home/${USER_NAME}/avro \
         -v ${HOME}/.gnupg:/home/${USER_NAME}/.gnupg \
         -u ${USER_NAME} \
         avro-php-${USER_NAME}
       ;;

     *)
       echo "Usage: $0 {interop-data-generate|test-interop|test|dist|clean}"
esac


exit 0
