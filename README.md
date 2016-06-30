# webService-deployer
<!-- TOC depthFrom:2 depthTo:6 withLinks:1 updateOnSave:1 orderedList:0 -->

- [Installation Guide (Debian)](#installation-guide-debian)
- [User Guide](#user-guide)
	- [Create a new Project](#create-a-new-project)
	- [Delete a Project](#delete-a-project)
- [Framework tested](#framework-tested)
	- [Django](#django)

<!-- /TOC -->
##Installation Guide (Debian)
Create a Git Server:
```
$ sudo adduser git
$ su git
$ cd
$ mkdir .ssh && chmod 700 .ssh
$ touch .ssh/authorized_keys && chmod 600 .ssh/authorized_keys
```

now copy your public ssh key inside the .ssh/authorized_keys file

Install Perl 5 and the library Config::Simple (you can easily use cpan)

Configigure software:
  - set all path in deploy.conf
  - leave blank or add optional configuration in post-receive.conf

[Optional] Add a symbolic link of command `deplot.plx` in your folder `/usr/sbin`

##User Guide
Use the command `deploy.plx` for create a new project or remove an existing one. With the different option it is possible to choose the domain name, the port number and the language of the project. This is the usage scheme of the deployer command:
```
usage: deployer add|remove webService_name [options]
  option:
    -p, --port    port_number        port number for the nginx configuration file [default:80]
    -d, --domain  domain_name        domain name for the nginx configuration file [default: not set]
    -l, --lang    node|python|php  set language for dependency resolving after push event [default:php]
    -h, --help    show this help
```

###Create a new Project
For instance you can create a new project `hello_world` with the language `python` on the domain `hello_world.example.com` with the following command:
```
# deployer add hello_world -d hello_world.example.com -l python`
```
Now all the configuration on the server are done. We have to go on the local pc to setting up the project folder; If the project is in nodejs or python we have to check that the project structure its correct for working with Phusion-Passenger (`tmp` and `public` folder and correct file name for the main file), otherwise in a Html/php project you can skip this. In addition of that structure you have to add same file for the deployer:
  - for Python:
    - `requirements.txt` with all the pip library (generate with the command `pip freeze > requirement.txt`)
    - `runtime.txt` with the name of the python executible (in debian python for python-2.7 and python3 for python 3.2)
  - for Nodejs:
    - `package.json` with the npm library (generate it with the option --save of npm)
    - `runtime.txt` with the name of the nodejs executible (in debian node)

Eventually we can setting up git for deploy the file to the server. You can create a new git repository if you didn't have one or only add a new remote url called live:
```
$ git init
$ git remote add live git@<your_server_url>:hello_world.git
$ git add .
$ git commmit -m 'init'
$ git push live master
```
If all works you can reach your web service at url `hello_world.example.com`

###Delete a Project
If you need to remove a project you can simple do the command:
```
# deployer remove <project_name>
```

## Framework tested
### Django

- add  the `passenger_wsgi.py` in the root directory of the django project.
```
#passenger_wsgi.py

import myproject.wsgi
application = myproject.wsgi.application
```
- Insert in the `settings.py` in the django project folder two lines:

   - `STATIC_ROOT = os.path.join(os.path.dirname(__file__), '../public/')`  ; this create the public folder in yout app if it doesn't not exist, the folder will contain all the static files.
   -  `STATIC_URL = '/public/'` indicates to the django that the static ursl are found in the public folder.

-  Execute `python manage.py collectstatic`.This copy all the static file found in the django applications (the folder must be named with the proper name) in the `static_root` folder.
