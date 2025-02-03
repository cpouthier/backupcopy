# Backup Copy
This script is designed to automate the export of the most recent restore point of a Kubernetes application to a secondary storage location using also Veeam Kasten data management platform.

## Here's a breakdown of its functionality:

### Set Variables:
APPLICATION_NAMESPACE=*yourapplication*: Specifies the Kubernetes namespace of the application.

SECONDARY_LOCATION_PROFILE=*yoursecondaryrepository*: Defines the profile name for the secondary storage location.

### Identify the Latest Local Restore Point:
This part of the script retrieves the most recent restore point within the specified application namespace that has been previously exported.

It uses kubectl to list restore points, sorts them by creation timestamp, and filters out those already associated with an export profile.

The name of the latest restore point is stored in the LATEST_RESTORE_POINT variable.

### Create an On-Demand Export Action:
An export action is defined in YAML format, specifying the restore point to be exported and the secondary location profile.

The script then applies this configuration initiating the export process.

In summary, this script automates the process of exporting the latest restore point of a specified Kubernetes application to a secondary storage location using Veeam Kasten.

# Work In Progress
- Include this script into a Kanister blueprint as a post-export hook for ease of use into Veeam Kasten GUI.
- Document limitations and constraints