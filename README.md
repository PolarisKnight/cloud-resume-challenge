# Welcome to my Cloud Resume Challenge Repo

This repo contains the backend associated with my portfolio created with the Cloud Resume Challenge.

## About The "Challenge"

The Cloud Resume Challenge, put simply, is something of a checklist of requirements to complete in order to host your resume/portfolio in the cloud using cloud-native infrastructure you built yourself.

Some of the requirements are as follows:
- Must be hosted on a public cloud platform (typically AWS but can be Azure/GCP if you prefer)
- Must use GitOps principles and CI/CD like GitHub Actions
- Must use IaC for the infrastructure (many choose Terraform but it's not required)
- Needs to include a function running code behind an API Gateway connected to a NoSQL key-value database for a website visitor counter 

The Cloud Resume Challenge was initially created in 2020 by Forrest Brazeal and more can be read about it on [his website](https://cloudresumechallenge.dev/). 



## Some Technical Decisions

> This is a brief technical overview of what I decided for this project. For more on my experience, please check out my [blog post](https://dev.to/polarisknight/cloud-resume-challenge-building-a-cloud-native-portfolio-k25) on dev.to. 

When it comes to the challenge, it may be completed in many different ways. Some may do the bare minimum, while others see it more as an ongoing portfolio project that they want to perfect. I lean more toward the latter. For me, doing everything "by the book" with the infrastructure was a little insufficient for what I wanted to do. Luckily, veering off a little bit is not against the "rules" at all!

### Security Keys
This is where I veered off the most. Instead of keeping secrets for AWS within GitHub, I decided to take advantage of my already existing Hashicorp Vault instance running on my Kubernetes homelab. GitHub Actions will use OIDC to connect to my Hashicorp Vault instance over Tailscale (an awesome mesh VPN) and grab AWS credentials for a Terraform-specific IAM user. It connects to my home network via an Apple TV 4K (yes, *that* Apple TV... it does a lot more than just stream video) that acts as a subnet router for my home LAN. The whole process takes only seconds for the GH Actions workflow to fetch my ID and Secret keys. 

Additionally, Hashicorp Vault uses JWT roles for extra security. The roles use bound claims with defined GitHub repos. If the repo invoking the request does not match, it will be denied access. The Tailscale trust also has limited access at the destination to ensure the security of my LAN if there is a breach on the GitHub side.

### The Website
The frontend for the website is hosted on [this repo](https://github.com/PolarisKnight/cloud-resume-website). It is not very interesting in comparison since it really is just HTML, CSS and a few lines of Javascript to fetch the API for the visitor counter. There is also a GH Action workflow to sync the contents to the S3 bucket hosting the website's files. More details will be in the blog post.


This README was last updated on 2026/9/17.