# Welcome to the GCP Example terraform!
In here you will deploy a Cloud Run-based GCP Integration service!

## Requirements

1. Create an Artifact registry in a GCP project (if you haven't already)
1. Pull our AMD64 based Docker image: `docker pull ghcr.io/port-labs/port-ocean-gcp --platform amd64`
1. Push this docker image to the artifact registry from step 1
1. Make sure you are logged in with `gcloud auth application-default login`
1. Run `terraform init` from this folder
1. Run `terraform apply` from this folder. Once you finished- You're done!

## Q&A

**Q: Why does the my integration not creating any entities on startup?**

**A:** From the official docs ([link](https://cloud.google.com/iam/docs/manage-access-service-accounts)):  ``In general, policy changes take effect within 2 minutes. However, in some cases, it can take 7 minutes or more for changes to propagate across the system.`` TL;DR- Wait for a few minutes and run RESYNC again. We added a 3min sleep to make sure you are onboarded with all your entities- this may be not enough.

**Q: How can I filter which projects does my integration process?**
**A:** Change the `var.projects` to a list of project ids relevant to you.
