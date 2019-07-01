# rocketplate

~Boilerplate for your next web project.~

Rocketplate for your next adventure 🚀


## Getting started

To get started, create a Google Cloud project and get authenticated:

```
gcloud auth application-default login
gcloud auth configure-docker
```

Now, we need to wire up Terraform and GCS. You can use the `./bootstrap.bash` tool to do this:

```
./bootstrap.bash TERRAFORM_BUCKET_NAME
```

which will create a GCS bucket for Terraform and authenticate Google Cloud Build.

To configure your new deployment, copy the example `tfvars`:

```
cp -n example.tfvars production.tfvars
```

and change anything that needs to be changed.

All that's left is to deploy!

```
# Replace TERRAFORM_BUCKET_NAME
terraform init --backend-config=bucket=TERRAFORM_BUCKET_NAME --backend-config=prefix=tfstate/production

# You might need to run this twice
terraform apply -var-file=production.tfvars
```

You now are admin-ing your own GKE cluster 😎


## DNS

To get your domain name pointing at this cluster, point the domain name's nameservers at the Google Managed Zone's DNS servers.

You can get these by going to the Google Cloud UI > Network Services > Cloud DNS > [Your Managed Zone] > Registrar Setup (top right corner).


## Persisting secrets

The `tfvars` files are `.gitignore`d, so, to persist them, you can use the `./tfvars.bash` tool:

```
./tfvars.bash upload production
```

Which will upload `production.tfvars` for you to your terraform bucket.

To have your team download, they can run:

```
./tfvars.bash download production
```

The CI system, Google Cloud Build, can now also download your secrets and deploy for you.


## CI

To use Google Cloud Build, first you need to build the custom cloud builder:

```
cd cloud-builder
gcloud builds submit --config=cloudbuild.yaml
```

Then, to run a remote deployment:

```
STAGE=production TF_BUCKET=rocketplate-terraform ./deploy.bash remote
```

To get builds happening automatically, head to the Google Cloud Build dashboard and set up an automatic trigger.


## Data

The database in this project is [Postgres](https://www.postgresql.org/), and the migration system is [rambler](https://github.com/elwinar/rambler).

Rambler has it's own folder, in `./rambler/`

Unfortunately, we're waiting on [this PR](https://github.com/terraform-providers/terraform-provider-kubernetes/pull/411) to land to finish up the Google Cloud side of rambler.


## Development

To get the development environment up and running, run

```
docker-compose up
```

which will get Postgres and rambler running.

Next would be to get `api` and `web` and running:

```
cd api
cp -n .env.example .env
npm run install
npm run dev
```

```
cd web
cp -n .env.example .env
npm run install
npm run dev
```

The way it's set up, environment variables are read from .env in both services.

You can open up both `localhost:3000` (web) and `localhost:3001` (api) and start building stuff!


## Techs

This system uses (from metal to user):

 * [Google Cloud Platform](https://cloud.google.com/)
 * [Terraform](https://www.terraform.io/)
 * [Postgres](https://www.postgresql.org/)
 * [Kubernetes](https://kubernetes.io/)
 * [Helm](https://helm.sh/)
 * [rambler](https://github.com/elwinar/rambler)
 * [Node.js](https://nodejs.org/)
 * [Micro](https://github.com/zeit/micro)
 * [React](https://reactjs.org/)
 * [Next.js](https://nextjs.org/)
 * [Kubernetes Nginx Ingress](https://kubernetes.github.io/ingress-nginx/)


## Cleaning up

To destroy everything, we can mostly just use Terraform. Doing a simple `terraform destory` fails unfortunatley though, because the Kubernetes node pool gets destroyed before helm (if you can create a PR to fix this, hats off to you!).

So, to destroy everything completely:

```
terraform destroy -var-file=production.tfvars
terraform state rm \
  module.ingress.helm_release.kube_lego \
  module.ingress.helm_release.nginx_ingress
terraform destroy -var-file=production.tfvars
```

And you should be good to go.


## Troubleshooting

### Error waiting for Create Service Networking Connection

Try running [this command](https://github.com/terraform-providers/terraform-provider-google/issues/3294#issuecomment-476715149).


## Todo

 - Move rambler deploy to terraform job resource when it lands: https://github.com/terraform-providers/terraform-provider-kubernetes/milestone/8
