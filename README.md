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

# SECTIONS BELOW ARE STILL WIP

- Document limitations and constraints

# What you need to know about Backup-copy

This blueprint is designed to enable the restoration of a workload from a secondary copy in the event of a disaster affecting the location profile where backups are exported. It also covers scenarios involving a complete disaster.

## Architectural context
LLet's imagine you have two different datacenters.

In DC#1, you have a Kubernetes cluster running a workload and a Veeam Kasten instance. The Veeam Kasten instance is configured to run a backup policy on the workload and export the backup to an S3 storage located in DC#1. As part of this policy, you add the backup-copy-bp blueprint as a post-export hook, configuring the SECONDARY_LOCATION_PROFILE to point to the S3 storage in DC#2.

Meanwhile, you also have a K10-DR policy running regularly, which exports Veeam Kasten's own backup to the S3 storage in DC#2.

*Due to the way Veeam Kasten manages its encryption keys, **running the Veeam Kasten DR to DC#2 is mandatory**. This ensures that you can restore the entire Kasten catalog, which contains all the encryption keys used for workload backups as well as all the restore points.*

## Recover from a huge disaster on DC#1
Let's imagine you're now facing a catastrophic disaster in DC#1, where everything is lost (S3 storage, Kubernetes cluster, Veeam Kasten, workload, etc.), and you need to restore your workloads in DC#2.

The first step is to recreate your Kubernetes cluster, if it hasn't already been done.

Next, you'll need to reinstall Veeam Kasten on the newly created cluster. This installation will be blank, with an empty catalog. Therefore, you'll have to restore the catalog from the Veeam Kasten backup (originally from DC#1) that was exported to the S3 storage in DC#2.

Once Veeam Kasten is restored, you'll be able to retrieve all the exported restore points from the S3 storage in DC#2 and use them to restore your applications.



