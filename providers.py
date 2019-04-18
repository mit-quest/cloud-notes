from enum import Enum

class CloudProvider(Enum):
    GoogleCloud = 'gcp'
    Azure = 'az'
    IBMCloud = 'ibm'
    AmazonWebServices = 'aws'
