#!/usr/bin/python2.7 -u

"""
USAGE:  cloudformation [--wait] [ (--start|--update--|--create) --stack-name=<stack> --template-url=<url> --parameters=<param> ]

 <stackname> is the name of the cloud formation stack
 --help    Prints this message
 --wait    Wait for the status to one of the *_COMPLETE statuses
 --start   Checks if stack exists, and then executes an update (if it exists) or create operation.
 --create  Executes a create operation
 --update  Executes an update operation
 --yes     Answer yes to any confirmation prompts.

Examples:
  Wait for a stack to be ready:
    cloudformation --wait --stack-name MYSTACK

  Create or update a stack and wait for completion:
    cloudformation --wait --stack-name MYSTACK --template-url=http://something --parameters=Key=Value
"""

import subprocess
import re
import getopt
import sys
import datetime
import time

class Action:
    START = 1
    UPDATE = 2
    CREATE = 3

class Options:
    region = None
    action = None
    confirm = True
    template_url = None
    region = None
    parameters = None
    stack_name = None
    wait = False

# print optional error message, usage doc, and exit
def usage(message=None):
    if message:
        print("\nERROR: %s" % message)
    print(__doc__)
    exit(2)

def abort(code, message=None):
    if message:
        print("\nERROR: %s" % message)
    print("\nERROR: exit code %d" % code)
    exit(code)

# execute a shell command and return (exitcode, stdout) as results
def run_command(cmd):
    p = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    out,err = p.communicate()
    return p.returncode, out, err

# extract a string value from the json block using a regex
# returns a string or none if not found
def find_json_value(key, text):
    match = re.search(r"\"%s\": +\"(.*)\"" % key, text, re.MULTILINE)
    if match:
        return match.group(1)
    else:
        return None

# runs the describe-stacks call and returns (exitcode, stackstatus)
def check_status(options):
    cmd = ['aws','cloudformation','describe-stacks','--region',options.region,'--stack-name',options.stack_name]
    err, json, stderr = run_command(cmd)
    if err == 0:
        status = find_json_value('StackStatus', json)
    else:
        status = stderr
    return err, status

# writes a time-stamped log to stdout
def log(message):
    timestamp = datetime.datetime.strftime(datetime.datetime.now(), '%Y-%m-%d %H:%M:%S')
    print("%s: %s" % (timestamp, message))

# Read the status until it becomes one of the completed statuses
def cfn_wait(options):
    print("Waiting for %s to complete." % options.stack_name)
    complete_statuses = ['CREATE_COMPLETE', 'ROLLBACK_COMPLETE', 'DELETE_COMPLETE', 'UPDATE_COMPLETE']
    failure_statuses = ['UPDATE_ROLLBACK_COMPLETE']
    period = 10.
    while True:
        time0 = datetime.datetime.now()
        err, status = check_status(options)
        log(status)
        if err != 0 or status in complete_statuses:
            return err, status
        if status in failure_statuses:
            return 1, status
        time1 = datetime.datetime.now()
        delay = period - (time1-time0).total_seconds()
        if delay > 0:
            time.sleep(delay)

# Read the status once, print it, and return.
def cfn_status(options):
    print("Checking status of %s." % options.stack_name)
    err, status = check_status(options)
    if err == 0:
        log(status)
    else:
        abort(err, status)

def cfn_start(options):
    print("Looking for existing stack %s." % options.stack_name)
    err, status = check_status(options)
    if err == 0:
        cfn_update(options)
    elif err == 255:
        cfn_create(options)
    else:
        abort(err, status)

def construct_aws_command(options, action):
    if options.template_url == None:
        usage("Missing template-url")
    if options.stack_name == None:
        usage("Missing stack-name")
    cmd = [
        'aws',
        'cloudformation',
        '--region', options.region,
        'update-stack' if action == Action.UPDATE else 'create-stack',
        '--stack-name',    options.stack_name,
        '--template-url',  options.template_url,
        '--capabilities',  'CAPABILITY_IAM'
        ]

    if options.parameters:
        cmd += ['--parameters', options.parameters]

    print(" ".join(cmd))
    return cmd

def cfn_update(options):
    print("Updating stack %s." % options.stack_name)
    cmd = construct_aws_command(options, Action.UPDATE)
    err, json, stderr = run_command(cmd)
    if err != 0:
        abort(err, stderr)
    print json

def cfn_create(options):
    print("Creating stack %s." % options.stack_name)
    cmd = construct_aws_command(options, Action.CREATE)
    err, json, stderr = run_command(cmd)
    if err != 0:
        abort(err, stderr)
    print json

def main():
    options = Options()
    options.region = 'us-west-1'

    try:
        opts, args = getopt.getopt(sys.argv[1:], "whsucyt:p:n:r:", ["wait","help","start","update","create","yes","template-url=","parameters=","stack-name=","region="])
    except getopt.error, msg:
        usage(msg)

    for o,a in opts:
        if o in ("-h", "--help"):
            usage()
        if o in ("-w", "--wait"):
            options.wait = True
        if o in ("-s", "--start"):
            options.action = Action.START
        if o in ("-u", "--update"):
            options.action = Action.UPDATE
        if o in ("-c", "--create"):
            options.action = Action.Start
        if o in ("-y", "--yes"):
            options.confirm = False
        if o in ("-r", "--region"):
            options.region = a
        if o in ("-t", "--template-url"):
            options.template_url = a
        if o in ("-p", "--parameters"):
            options.parameters = a
        if o in ("-n", "--stack-name"):
            options.stack_name = a

    if len(args) != 0:
        print args
        usage("Unexpected arguments.")

    if options.action == Action.START:
        cfn_start(options)
    elif options.action == Action.UPDATE:
        cfn_update(options)
    elif options.action == Action.CREATE:
        cfn_create(options)
    elif not options.wait:
        cfn_status(options)

    if options.wait:
        cfn_wait(options)

if __name__ == "__main__":
    main()
