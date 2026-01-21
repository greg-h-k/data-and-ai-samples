# Ingress and Load Balancers in EKS Auto Mode

## Overview

Amazon EKS Auto Mode includes built-in support for Application Load Balancers (ALBs) without requiring the AWS Load Balancer Controller to be installed separately. This is a key feature that simplifies cluster management.

## How It Works in EKS Auto Mode

When you create an Ingress resource in EKS Auto Mode:
1. EKS automatically detects the Ingress
2. Creates an Application Load Balancer in AWS
3. Configures target groups and listener rules
4. Updates the Ingress status with the ALB DNS name

**No additional controller installation needed!**

## Diagnostic Steps

If your ingresses are not creating load balancers, follow these steps:

### Step 1: Check Ingress Resources Exist

```bash
# List all ingress resources
kubectl get ingress -A

# Expected output should show your ingresses
# NAMESPACE      NAME           CLASS   HOSTS                        ADDRESS   PORTS
# langflow-ide   langflow-ide   alb     langflow-ide.example.com               80, 443
```

**If no ingresses are listed:** The Helm charts didn't create them. Check:
- Did you deploy the applications with Helm?
- Are the ingress sections enabled in values.yaml files?

### Step 2: Check Ingress Details

```bash
# Describe a specific ingress to see events and status
kubectl describe ingress <ingress-name> -n <namespace>

# Example:
kubectl describe ingress langflow-ide -n langflow-ide

# Look for:
# - Events section at the bottom
# - Any error messages
# - Whether load balancer creation was attempted
```

### Step 3: Check Available Ingress Classes

```bash
# List ingress classes in the cluster
kubectl get ingressclass

# In EKS Auto Mode, you should see default ingress classes
# The class might be different from 'alb'
```

### Step 4: Check EKS Auto Mode Status

```bash
# Get cluster info
aws eks describe-cluster --name <cluster-name> --region <region>

# Verify Auto Mode is enabled:
# Look for "computeConfig": { "enabled": true }
```

### Step 5: Check Service Resources

Ingresses route to Services, which must exist:

```bash
# Check if services exist for your applications
kubectl get svc -A | grep -E 'langflow|langfuse'

# Verify services are ClusterIP type (correct for ALB)
```

## Common Issues and Solutions

### Issue 1: Ingress Resources Not Created

**Symptom:** `kubectl get ingress -A` shows no ingresses

**Cause:** Ingress not enabled in Helm values or chart doesn't support ingress

**Solution:**
```bash
# Check if ingress is enabled in your values file
grep -A5 "^ingress:" apps/langflow-ide/values.yaml

# Should show:
# ingress:
#   enabled: true

# If enabled: false, update and redeploy
helm upgrade langflow-ide langflow-ide \
  --repo https://langflow-ai.github.io/langflow-helm-charts \
  --version 0.1.1 \
  --values apps/langflow-ide/values.yaml \
  --namespace langflow-ide
```

### Issue 2: Wrong Ingress Class

**Symptom:** Ingress created but ADDRESS column stays empty

**Cause:** EKS Auto Mode might use a different default ingress class

**Solution:**

Try removing the explicit `ingressClassName` to use the cluster default:

```yaml
# In your values.yaml
ingress:
  enabled: true
  # ingressClassName: alb  # Comment this out or remove it
  annotations:
    alb.ingress.kubernetes.io/listen-ports: '[{"HTTPS":443}]'
    alb.ingress.kubernetes.io/scheme: internet-facing
    alb.ingress.kubernetes.io/target-type: ip
```

Or check what ingress classes are available and use one explicitly:
```bash
kubectl get ingressclass
```

### Issue 3: Missing Required Annotations

**Symptom:** Ingress exists but load balancer not provisioned

**Cause:** EKS Auto Mode might require specific annotations

**Solution:**

Ensure your ingress has these essential ALB annotations:

```yaml
ingress:
  enabled: true
  ingressClassName: alb  # or omit to use default
  annotations:
    alb.ingress.kubernetes.io/scheme: internet-facing  # or internal
    alb.ingress.kubernetes.io/target-type: ip
    alb.ingress.kubernetes.io/listen-ports: '[{"HTTPS":443}]'
  hosts:
    - host: your-app.your-domain.com
      paths:
        - path: /
          pathType: Prefix
```

### Issue 4: Certificate Issues (HTTPS)

**Symptom:** ALB created but HTTPS not working

**Cause:** Missing ACM certificate ARN

**Solution:**

Add certificate ARN annotation:

```yaml
annotations:
  alb.ingress.kubernetes.io/certificate-arn: arn:aws:acm:region:account:certificate/xxx
  alb.ingress.kubernetes.io/listen-ports: '[{"HTTPS":443}]'
```

Or use HTTP only for testing:
```yaml
annotations:
  alb.ingress.kubernetes.io/listen-ports: '[{"HTTP":80}]'
```

### Issue 5: Service Not Found

**Symptom:** ALB created but returns 503 errors

**Cause:** Ingress references service that doesn't exist

**Solution:**

```bash
# Check service exists
kubectl get svc -n <namespace>

# Verify ingress points to correct service
kubectl get ingress <ingress-name> -n <namespace> -o yaml | grep -A5 backend

# Should match your service name and port
```

## Recommended Ingress Configuration for EKS Auto Mode

### Basic Configuration (HTTP Only)

Good for testing and internal applications:

```yaml
ingress:
  enabled: true
  annotations:
    alb.ingress.kubernetes.io/scheme: internet-facing
    alb.ingress.kubernetes.io/target-type: ip
    alb.ingress.kubernetes.io/listen-ports: '[{"HTTP":80}]'
  hosts:
    - host: app.example.com
      paths:
        - path: /
          pathType: Prefix
```

### Production Configuration (HTTPS)

For production with SSL certificate:

```yaml
ingress:
  enabled: true
  annotations:
    alb.ingress.kubernetes.io/scheme: internet-facing
    alb.ingress.kubernetes.io/target-type: ip
    alb.ingress.kubernetes.io/listen-ports: '[{"HTTPS":443}]'
    alb.ingress.kubernetes.io/certificate-arn: arn:aws:acm:region:account:certificate/xxx
    alb.ingress.kubernetes.io/ssl-redirect: '443'
  hosts:
    - host: app.example.com
      paths:
        - path: /
          pathType: Prefix
```

### Shared Load Balancer Configuration (Cost Optimization)

To share one ALB across multiple applications:

```yaml
ingress:
  enabled: true
  annotations:
    alb.ingress.kubernetes.io/group.name: aiml-platform-ingress  # Same name = shared ALB
    alb.ingress.kubernetes.io/scheme: internet-facing
    alb.ingress.kubernetes.io/target-type: ip
    alb.ingress.kubernetes.io/listen-ports: '[{"HTTPS":443}]'
    alb.ingress.kubernetes.io/certificate-arn: arn:aws:acm:region:account:certificate/xxx
  hosts:
    - host: app.example.com
      paths:
        - path: /
          pathType: Prefix
```

**Benefits of shared ALB:**
- Single ALB for all applications saves ~$16/month per additional app
- Simplified DNS management (one ALB endpoint)
- Consistent security groups and access logs

## Verification Commands

After deploying with ingress enabled:

```bash
# 1. Check ingress was created
kubectl get ingress -A

# 2. Wait for ALB to be provisioned (can take 2-3 minutes)
kubectl get ingress <ingress-name> -n <namespace> -w

# 3. Once ADDRESS is populated, test it
ALB_DNS=$(kubectl get ingress <ingress-name> -n <namespace> -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
echo "ALB DNS: $ALB_DNS"

# 4. Test with curl (HTTP)
curl -H "Host: your-app.your-domain.com" http://$ALB_DNS

# 5. Test with curl (HTTPS, with proper DNS)
curl https://your-app.your-domain.com
```

## Troubleshooting Checklist

- [ ] Ingress resource exists (`kubectl get ingress -A`)
- [ ] Ingress has correct service backend (`kubectl describe ingress`)
- [ ] Service exists and is type ClusterIP (`kubectl get svc`)
- [ ] Pod is running and ready (`kubectl get pods`)
- [ ] Ingress has ADDRESS populated (ALB DNS)
- [ ] Can curl the ALB directly
- [ ] DNS points to ALB (if using custom domain)
- [ ] Certificate is valid in ACM (if using HTTPS)
- [ ] Security groups allow traffic from ALB to pods

## Alternative: Use LoadBalancer Service Type

If ingress continues to have issues, you can expose applications directly via LoadBalancer services:

```yaml
service:
  type: LoadBalancer
  annotations:
    service.beta.kubernetes.io/aws-load-balancer-scheme: internet-facing
    service.beta.kubernetes.io/aws-load-balancer-type: external
    service.beta.kubernetes.io/aws-load-balancer-nlb-target-type: ip
  port: 80
```

This creates a Network Load Balancer (NLB) instead of an Application Load Balancer (ALB).

## References

- [EKS Auto Mode Documentation](https://docs.aws.amazon.com/eks/latest/userguide/eks-auto-mode.html)
- [Kubernetes Ingress](https://kubernetes.io/docs/concepts/services-networking/ingress/)
- [AWS Load Balancer Annotations](https://kubernetes-sigs.github.io/aws-load-balancer-controller/v2.11/guide/ingress/annotations/)
