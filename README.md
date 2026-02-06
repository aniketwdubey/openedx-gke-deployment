### Quick start
```bash
# Launch Open edX on Kubernetes
tutor k8s launch

# Set Tutor data directory (adjust path as needed)
export TUTOR_ROOT=/home/username/.local/share/tutor

# Check cluster status
tutor k8s status
```

## Open edX on GKE - Operations Cheatsheet

### Domains
- **CMS_HOST**: studio.openedx-stage.example.com
- **LMS_HOST**: openedx-stage.example.com

### Quick health checks (inside cluster / port-forwarded to 8000)
```bash
# LMS
curl -I -H "Host: openedx-stage.example.com" http://localhost:8000/heartbeat
curl -sS -H "Host: openedx-stage.example.com" "http://localhost:8000/heartbeat?extended=1"

# CMS
curl -I -H "Host: studio.openedx-stage.example.com" http://localhost:8000/heartbeat
curl -sS -H "Host: studio.openedx-stage.example.com" "http://localhost:8000/heartbeat?extended=1"

# External host override samples
curl -I -H "Host: studio.openedx-demo.example.com" http://studio.openedx-stage.example.com/heartbeat
curl -I -H "Host: openedx-demo.example.com" http://openedx-stage.example.com/heartbeat
```

### Configure readiness probes
```bash
# LMS deployment
kubectl patch deployment lms -n openedx --patch '{
  "spec": {"template": {"spec": {"containers": [{
    "name": "lms",
    "readinessProbe": {
      "httpGet": {
        "path": "/heartbeat",
        "port": 8000,
        "httpHeaders": [{"name": "Host", "value": "openedx-stage.example.com"}]
      },
      "initialDelaySeconds": 30,
      "periodSeconds": 10,
      "timeoutSeconds": 5,
      "successThreshold": 1,
      "failureThreshold": 3
    }
  }]}}}
}'

# CMS deployment
kubectl patch deployment cms -n openedx --patch '{
  "spec": {"template": {"spec": {"containers": [{
    "name": "cms",
    "readinessProbe": {
      "httpGet": {
        "path": "/heartbeat",
        "port": 8000,
        "httpHeaders": [{"name": "Host", "value": "studio.openedx-stage.example.com"}]
      },
      "initialDelaySeconds": 30,
      "periodSeconds": 10,
      "timeoutSeconds": 5,
      "successThreshold": 1,
      "failureThreshold": 3
    }
  }]}}}
}'
```

### Create admin user
```bash
tutor k8s do createuser --staff --superuser admin admin@example.com
```


### Scale replicas
```bash
kubectl patch deployment cms -n openedx --type=merge -p '{"spec":{"replicas":2}}'
kubectl patch deployment lms -n openedx --type=merge -p '{"spec":{"replicas":2}}'
kubectl patch deployment cms-worker -n openedx --type=merge -p '{"spec":{"replicas":2}}'
kubectl patch deployment lms-worker -n openedx --type=merge -p '{"spec":{"replicas":2}}'
```


