# cloud-notes
## A Cloud Agnostic deployment service for Python Notebooks

### Purpose
To enable developers and researchers to get up and running in the cloud without previous cloud provision knowledge or the time to learn the skills needed to setup a cloud environment.

## Getting Started (Local)
1. Place all Jupyter notebooks and code dependencies in the workspace folder.
2. run `./local-execute.sh` whih will launch a Jupyter server inside a docker continer.
---
    NOTE: Any changes you make in the container should be reflected on the local machine. You can also add more files to the workspace without the need to restart the container and the server should reflect those changes.
---
