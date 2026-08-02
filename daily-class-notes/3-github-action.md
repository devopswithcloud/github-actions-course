* Workflow 
* Events
* Jobs
* Steps
* Runners 
## Workflow:
* A workflow is an automated process defined in YAML file. 
* its a file
* this workflow (in yaml) live inside your repository and tells the github actions what to do and when to do it. 
## Events: 
* An event is what triggers a workflow .Without this nothing happens 
```
on: push 
on: pull_request
on: workflow_dispatch # runs when manually triggered
on: schedule
```
## Jobs:
* A job is a group of steps that run together on the same machine.
* Every workflow has atleast on job 
* Think of it as a task list assogined to one machiner(one worker)
workflow
build 
    clone 
    mvn package 

tests
> imageb > push > arlo > deploy
## Steps:
* A steps is a single task inside a job.
* * Steps run 

## Runners 
* A runner is a machine where your job executes. Every job needs a runner
* Think of it as a fresh laptop github hands over to your job and it will wipe out the runner once your job is completed. 
* Every job gets a brand new machines
* Your job will on that machines

* github hosted runners 
* self hosted runners 


* both the jobs starts at the same time: parallel execution
* Each job will run on its own runner 
* both jobs are independely

When a step failes inside a job, all remaining steps in that job are skippeed immediatley and the job is marked as faile.

use needs: to make one job wait for another to complete before starting. 
This creates a secquential execution order

needs:
Job fail, skippe
stage 


Worflow:

Event:
    trigger the workflow 
        consists of jobs
            each job will run on a runner 
                each job contains steps 
                    each step runs a command or uses actions****



## Event Deep Dive
* Event is an activity that happens in your github repo > it will trigger a workflow to run 
* Each workflow must declare at least one event under `on:`
```bash
on: push            # run the workflow when a code is pushed to my repo
on: pull_request    # when a PR is opened or updated
on: workflow_dispatch # Runs when manually triggered
on: schedule        # runs on a prticular schedule.
```

on: push > 