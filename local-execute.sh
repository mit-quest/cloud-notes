#!/bin/bash

docker build . --build-arg USER_ID=$(id -u $USER) -t pynb-cloud

while IFS= read -r line; do
    echo "$line" | perl ./ipynb-url -
done < <(docker run -i -p 8888:8888 pynb-cloud 2>&1)
