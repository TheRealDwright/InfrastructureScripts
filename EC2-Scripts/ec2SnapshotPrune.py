#Author Daniel Wright
#Last Updated: 20160212

import re
import datetime
import boto3

ec = boto3.client('ec2')
iam = boto3.client('iam')

#This function looks at *all* snapshots that have a "deleteOnDate" tag containing
#the current day formatted as YYYY-MM-DD. This function should be run at least
#daily.

#Snapshot prune Function. Add this to a Lambda Function by putting the below block
# In a Lambda Function: def lambda_handler(event, context):


def lambda_handler(event, context):
    account_ids = list()
    try:
        iam.get_user()
    except Exception as e:
    # use the exception message to to display account ID the function executes under
        account_ids.append(re.search(r'(arn:aws:sts::)([0-9]+)', str(e)).groups()[1])

    deleteOnDate = datetime.date.today().strftime('%Y-%m-%d')
    filters = [
        {'Name': 'tag-key', 'Values': ['deleteOnDate']},
        {'Name': 'tag-value', 'Values': [deleteOnDate]},
    ]
    snapshot_response = ec.describe_snapshots(OwnerIds=account_ids, Filters=filters)

    for snap in snapshot_response['Snapshots']:
        print "Deleting snapshot %s" % snap['SnapshotId']
        ec.delete_snapshot(SnapshotId=snap['SnapshotId'])
