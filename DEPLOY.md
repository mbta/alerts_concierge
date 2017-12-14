### Overview
How to deploy the application to the current EC2 staging server.

### Installing the .pem file
On you local machine, edit the `~/.ssh/config` file. Associate the hostname with the appropriate `.pem` file.

```
Host ec2-34-205-43-57.compute-1.amazonaws.com
  IdentityFile ~/.ssh/concierge_staging_id_dsa
```

### Do a deployment

From the project root, run: `./beta-deploy.sh`

### How to Change Environment Variables

Login to the server, manually update the `/home/ubuntu/app/.env` file.

### How to Run a DB Migrations

Database migrations will be automatically run when the application is started in production.
