## Agenda
* The problem, from manual to automated. 
* What is github actions 
* What github actions can autoamte 
* CI/CD 
* Github actions vs Jenkins
* Who should move to github actions 
* What are we trying to build in the course (Course Content)

## The problem, from manual to automated. 

* Pulling the latest code from the repo
* Installing dependncies on the target machine 
* RUnning those tests manually
* Build the application
* Creating the Docker image 
* Image > deploying to diff env (across diff servers)
* Verify the deployment worked
* perfoming hte same again and agian across diff env(dev, test, stage,prod)
* This was very slow, error prone and its impossible to scale across ,multiple application and teams. 
* Team started using automation

### Team started adopted Jenkins to solve this problem
* Jenkins automated the repetitive steps. 
* instead of executing manual commands, teams had pipelines. 
* pipleines used to un on agents.
* But the over the time jenkins itself becomae something that needes to be managed:
    * A server > java > install jenkins 
        * multi vm > lb > NFS 
    * Sever mainitnace 
    * Plugins to install , upgrade, manage 
    * Plugin conflict, based on the version 
    * Slaves configuration > live (offline) 
    * Disk issues monitor 
    * backup to monitor 
    * Jenkins > a full time 
    * 
* Our application atutomation 
* Automation > tool

* Github actions solve both the problems
    * Automate your manual steps 
    * inorder to implement this automation
        * no server to install
        * No agent configuration 
        * No plugins to manage 
        * Write some yaml file are available in repo version, review, pr .

## what exactly is github actions :
* Github actions is an automation platform built directly into github.  
* When something happens inside a gihub repo
        * code push, 
        * pull request
        * tag create
        * issues 
        * schedule time 
    * github can autpmatically execute a set of tasks(we will be giving those task) in reponse
* No seperatte server 
* no plugin manage,ment
* no agents to cofnigure 
* the pipeliens are defined in YAML > insidet your repo > application code .

## What github actions can automate:
        * code push > tests, app build deploy  
        * pull request > open/close > validate code , enforce standards
        * tag create > Create a release, push 
        * issues 
        * schedule time 
## Github actions vs Jenkins:
* Jenkins : Old legacy complicated 
* Github actions: 
    * new projects 
    * Migrating jenkins 
* groovy > yaml 

Migating form jenkins 
adoption
server management 
*** plugin management



CI/CD delivery, deployments






app code > Jenkinsfile(groovy)
app code > yml



github.com/i27org/auth-service.git




        yaml : ansible(d), k8s, azure pip, gcloud b

    cloud enginner > terraform > automated 
    app code > automate > 
    network engi> automate 
    QA enginner > automated


We will learn writting workflows
automations 


