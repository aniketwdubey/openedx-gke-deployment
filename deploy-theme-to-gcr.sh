#!/bin/bash
set -e

# ================================
# CONFIGURATION (edit these)
# ================================
GCP_PROJECT_ID="my-gcp-project"
GCP_REGION="asia-south1"          # e.g., asia-south1 = Mumbai
GCR_REPO=""
IMAGE_NAME=""
IMAGE_TAG="mytheme-v3"
NAMESPACE="openedx"               # K8s namespace used by Tutor

# ================================
# Derived variables
# ================================
FULL_IMAGE="${GCP_REGION}-docker.pkg.dev/${GCP_PROJECT_ID}/${GCR_REPO}/${IMAGE_NAME}:${IMAGE_TAG}"

echo "🚀 Deploying Open edX theme to GCR & K8s..."
echo "📦 Image will be: ${FULL_IMAGE}"

# 1️⃣ Authenticate with GCP Artifact Registry
echo "🔑 Authenticating with GCP..."
gcloud auth configure-docker ${GCP_REGION}-docker.pkg.dev

# 3️⃣ Build Open edX image with custom theme
echo "⚙️ Setting image in Tutor config..."
tutor config save --set DOCKER_IMAGE_OPENEDX=${FULL_IMAGE}
tutor images build openedx

# 4️⃣ Push image to Artifact Registry
echo "⬆️ Pushing image to Artifact Registry..."
docker push ${FULL_IMAGE}

# 5️⃣ Update Tutor config to use new image
echo "⚙️ Updating Tutor config..."
tutor config save --set DOCKER_IMAGE_OPENEDX=${FULL_IMAGE}

# 6️⃣ Deploy to Kubernetes
echo "🚢 Deploying to Kubernetes..."
tutor k8s upgrade

echo "♻️ Restarting LMS & CMS pods..."
kubectl rollout restart deployment lms -n ${NAMESPACE}
kubectl rollout restart deployment cms -n ${NAMESPACE}

echo "✅ Deployment complete! Using image: $FULL_IMAGE"

# 7️⃣ Verify deployment
echo "🔍 Verifying new image in deployments..."
kubectl -n ${NAMESPACE} get pods
kubectl -n ${NAMESPACE} describe deployment lms | grep Image

echo "✅ Deployment complete!"