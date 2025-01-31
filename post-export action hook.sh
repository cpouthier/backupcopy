#!/bin/bash

# Define Application Namespace
APPLICATION_NAMESPACE=wordpress
# Define Secondary Location Profile
SECONDARY_LOCATION_PROFILE=s3-standard

#Identifying latest local restore point...
LATEST_RESTORE_POINT=$(kubectl get restorepoints.apps.kio.kasten.io -n $APPLICATION_NAMESPACE --sort-by=.metadata.creationTimestamp -o json | \
    jq -r '.items[] | select(.metadata.labels["k10.kasten.io/exportProfile"] | not) | .metadata.name' | tail -n 1)


# Create on-demand export action that exports $LATEST_RESTORE_POINT
# from the $APPLICATION_NAMESPACE using $SECONDARY_LOCATION_PROFILE.
# Assumes that Veeam Kasten is installed in 'kasten-io' namespace.

cat > export-action.yaml <<EOF
apiVersion: actions.kio.kasten.io/v1alpha1
kind: ExportAction
metadata:
  generateName: export-$APPLICATION_NAMESPACE-$LATEST_RESTORE_POINT
  namespace: kasten-io
spec:
  # Expiration timestamp in ``RFC3339`` format. Optional.
  # Garbage collector will automatically retire expired exports if this field is set.
  #expiresAt: "2002-10-02T15:00:00Z"
  subject:
    kind: RestorePoint
    name: $LATEST_RESTORE_POINT
    namespace: $APPLICATION_NAMESPACE
  profile:
    name: $SECONDARY_LOCATION_PROFILE
    namespace: kasten-io
EOF

# Execute the export action
kubectl create -f export-action.yaml

# Clean up the temporary file
rm -f export-action.yaml

# Get the name of the export action into a variable
EXPORT_ACTION_NAME=$(kubectl get exportaction -n kasten-io --sort-by=.metadata.creationTimestamp -o json | \
  jq -r --arg prefix "export-$APPLICATION_NAMESPACE-$LATEST_RESTORE_POINT" '.items[] | select(.metadata.name | startswith($prefix)) | .metadata.name' | tail -n 1)

# Extract the creationTimestamp and receiveString fields from the export action so it can be reused in a DR plan with another Kasten instance.
# Define the output file

OUTPUT_LOG="latest_secondary_export.txt"

# Extract the secondary export timestamp and receive string from the export action and store them in the output log file
kubectl get exportaction $EXPORT_ACTION_NAME -n kasten-io -o yaml | \
  awk '/creationTimestamp:/ && !found {print "Creation Timestamp:", $2; found=1} /receiveString:/ {print "Receive String:", $2} END {print ""}' > "$OUTPUT_LOG"

# Note: each time an export is done it seems a secret is created in the namespace of kasten with the name export-xxxxxxxxxxxxx-migration-token so there's maybe another way to get the receiveString
