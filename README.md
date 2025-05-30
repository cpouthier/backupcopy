# Backup Copy

This blueprint automates the process of exporting the latest restore point of a specified Kubernetes application to a secondary storage location using Veeam Kasten.

**WARNING**

The provided blueprint **is not supported by the editor and is supplied as-is**. Functionality, compatibility, and correctness are not guaranteed. Please verify and adjust as needed before use.

## Here's a breakdown of its functionality

### Identify the Latest Local Restore Point:

* Queries all restore points in the namespace.
* Filters out restore points that have already been exported.
* Sorts them by creation timestamp.
* Selects the most recent one.

### Create an On-Demand Export Action:

Generates an **exportAction** custom resource that:
* Targets the latest restore point.
* Exports it using the secondary location profile.
* Creates the export action in Kubernetes.

# How to use this blueprint

## Pre-requisite

Before adding the blueprint, you must ensure that the secondary repository has been configured into Veeam Kasten as a new location profile as it needs to be hardcoded in the blueprint to run properly.

## Create and apply the blueprint in Veeam Kasten's GUI

In the Veeam Kasten's GUI, click on Blueprints and then "Add a blueprint" or "Create New Blueprint":

![alt text](https://raw.githubusercontent.com/cpouthier/backupcopy/main/img/bpstep1.png)

In the Add Blueprint screen copy and paste the content of the blueprint. **Do not forget to modifiy it indicating the location profile to be used to export the backup copy.** Once you're done, click on "Validate and Save".

![alt text](https://raw.githubusercontent.com/cpouthier/backupcopy/main/img/bpstep2.png)

This blueprint is unsing the bitnami/kubectl image. So if you're running into an airgapped environment you must ensure that you can pull this image from a private registry, and then you'll need to modify the image address into the blueprint:

![alt text](https://raw.githubusercontent.com/cpouthier/backupcopy/main/img/bpstep-airgap.png)

You can now create your backup policy as usual, but add in the "Pre and Post-Export Action Hooks" section add the blueprint as shown below and save the policy.

**WARNING: You need to set up a 1-day minimal retention for your shapshot on the policy!**

![alt text](https://raw.githubusercontent.com/cpouthier/backupcopy/main/img/bpstep3.png)

You can now run your policy!

## Optionnally

### Specific retention
If you want to set up a retention date for the backup copy.

The expiration timestamp needs to be hardcoded in the blueprint following RFC3339 format.

As an example, if you want your second copy to be retained for one month, set the "expiresAt:" spec value as:

`expiresAt: $(date -u --date="1 month" "+%Y-%m-%dT%H:%M:%SZ")`

### Third export
If for any reason you need also to have a third copy you can simply add a new export action in the blueprint as below and modify it appropriately:

```
            THIRD_LOCATION_PROFILE=third_copy_location

              # Create on-demand export action that exports $LATEST_RESTORE_POINT
              # from the $APPLICATION_NAMESPACE using $THIRD_LOCATION_PROFILE.
              # Assumes that Veeam Kasten is installed in 'kasten-io' namespace.


              echo | kubectl apply -f -  <<EOF

              apiVersion: actions.kio.kasten.io/v1alpha1

              kind: ExportAction

              metadata:
                generateName: export-$APPLICATION_NAMESPACE-$LATEST_RESTORE_POINT-3
                namespace: kasten-io
                labels:
                  k10.kasten.io/exportType: portableAppData
              spec:
                # Expiration timestamp in ``RFC3339`` format. Optional.
                # Garbage collector will automatically retire expired exports if this field is set.
                #expiresAt: "2002-10-02T15:00:00Z"
                expiresAt: $(date -u --date="1 day" "+%Y-%m-%dT%H:%M:%SZ")
                subject:
                  kind: RestorePoint
                  name: $LATEST_RESTORE_POINT
                  namespace: $APPLICATION_NAMESPACE
                profile:
                  name: $THIRD_LOCATION_PROFILE
                  namespace: kasten-io
                exportData:
                  enabled: true
              EOF
```

## Error handling

In anycase, the blueprint which creates the export action will only run if initial export succeeded (post-export action hook configured with **"After-On Success"**). In other terms, that means:

* If the snapshot phase doesn't succeed, then the initial export as well as the backup copy export will not run.
* If the snapshot phase succeed and the initial export fails, then the second backup copy will not run.
* If the snapshot phase as well as the inital export succeed, then the second backup copy will run.

When the backup copy will run, it will create a new manual export action in Veeam Kasten and you'll be able to monitor it in the GUI:

![alt text](https://raw.githubusercontent.com/cpouthier/backupcopy/main/img/bpdashboard.png)


# What you need to know about Backup-copy

This blueprint is designed to enable the restoration of a workload from a secondary copy in the event of a disaster affecting the location profile where backups are exported. It also covers a wider scenario involving a complete disaster.

## Architectural context

Let's imagine you have two different datacenters in an Active-Passive way.

In DC#1, you have a Kubernetes cluster running a workload and a Veeam Kasten instance. The Veeam Kasten instance is configured to run a backup policy on the workload and export the backup to an S3 storage located in DC#1. As part of this policy, you add the backup-copy-bp blueprint as a post-export hook, configuring the SECONDARY_LOCATION_PROFILE to point to the S3 storage in DC#2.

Meanwhile, you also have a K10-DR policy running regularly, which exports Veeam Kasten's own backup to the S3 storage in DC#2.

*Due to the way Veeam Kasten manages its encryption keys, **running the Veeam Kasten DR to DC#2 is mandatory**. This ensures that you can restore the entire Kasten catalog, which contains all the encryption keys used for workload backups as well as all the restore points.*

![alt text](https://raw.githubusercontent.com/cpouthier/backupcopy/main/img/step1.png)

## Recover from a huge disaster on DC#1

Imagine you're now facing a catastrophic disaster in DC#1, where everything is lost (S3 storage, Kubernetes cluster, Veeam Kasten, workload, etc.), and you need to restore your workloads in DC#2.

The first step is to recreate your Kubernetes cluster, if it hasn't already been done.

Next, you'll need to reinstall Veeam Kasten on the newly created cluster. This installation will be blank, with an empty catalog. 

![alt text](https://raw.githubusercontent.com/cpouthier/backupcopy/main/img/step2.png)

Therefore, you'll have to restore the catalog from the Veeam Kasten backup (originally from DC#1) that was exported to the S3 storage in DC#2.

![alt text](https://raw.githubusercontent.com/cpouthier/backupcopy/main/img/step3.png)

Once Veeam Kasten is restored, you'll be able to retrieve all the exported restore points from the S3 storage in DC#2 and use them to restore your applications.

![alt text](https://raw.githubusercontent.com/cpouthier/backupcopy/main/img/step4.png)

![alt text](https://raw.githubusercontent.com/cpouthier/backupcopy/main/img/step5.png)

