### Overview
This document covers the various devops considerations of managing the beta server environment.

### Access Remote Server
On your local machine, edit the `~/.ssh/config` file. Associate the hostname with the appropriate `.pem` file.

For example:

```
Host ec2-34-205-43-57.compute-1.amazonaws.com
  IdentityFile ~/.ssh/concierge_staging_id_dsa
```

To login:

```
ssh ubuntu@ec2-34-205-43-57.compute-1.amazonaws.com
```

### Restart Product Application

From the `/apps/concierge_site` directory, run:

```
mix edeliver stop staging
mix edeliver start staging
mix edeliver ping staging
```

### Deploy a New Application Verion

From the project root, checkout the master branch. Then, run: `./beta-deploy.sh`.

Running this script will:

- build a new release version
- copy the binary to the remote server
- restart the application
- trigger database migrations to run
- push a release tag to github

### Change Production Environment Variables & Configurations

There are three private configutation variables that can be modified. The following table shows the file name and where it must reside on the production server.

| File     | Path                     |
|----------|--------------------------|
| .profile | /home/ubuntu/.profile    |
| .env     | /home/ubuntu/app/.env    |
| vm.args  | /home/ubuntu/app/vm.args |


The environment files are stored in the LastPass website. They can be accessed at the following path:

`Shared-Devops > T-Alerts Concierge > beta`

To make changes:

- download the file locally
- make the change
- upload to production
- restart the application
- make the changes to the LastPass file
- remove your local version

### Database Migrations on Prod Environment

Database migrations are automatically triggered when a new release is deployed or if the application is restarted.

### Configure a New EC2 Instance

```
mkdir /home/ubuntu/app
chmod -R 755 /home/ubuntu/app
```

Copy the configuration files from LastPass.

### Configure a New PostgreSQL Instance

In addition to adding a non-root user and setting access credentials, you must run the following command:

```
CREATE EXTENSION "uuid-ossp";
```
