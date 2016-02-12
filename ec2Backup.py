import boto3

ec = boto3.client('ec2')


reservations = ec.describe_instances(
    #Filter all instances with the key:pair of AutoBackup:True
    Filters=[
        {'Name':'tag:AutoBackup', 'Values':['True']},
    ]
).get(
    'Reservations', []
)

#Locate Instances to be backed up.
instances = sum(
    [
        [i for i in r['Instances']]
        for r in reservations
    ], [])
print "Found %d instances that need backing up" % len(instances)

for instance in instances:
    for dev in instance['BlockDeviceMappings']:
        if dev.get('Ebs', None) is None:
            # skip anything that does not have EBS volumes
            continue
        vol_id = dev['Ebs']['VolumeId']
        print "Found EBS volume %s on instance %s" % (
            vol_id, instance['InstanceId'])
        ec.create_snapshot(
            VolumeId=vol_id,
        )