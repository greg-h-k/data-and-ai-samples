# Sample Documentation Template

Use this template when creating new samples. Copy the structure below into your sample's `README.md`.

---

# [Sample Name]

> **Services:** Service1, Service2, Service3
> **Complexity:** Beginner | Intermediate | Advanced
> **Last Updated:** YYYY-MM-DD

Brief one-paragraph description of what this sample does and the problem it solves.

## Overview

### What This Sample Does

Explain in 3-5 bullet points what the sample demonstrates:

- First capability or feature
- Second capability or feature
- Third capability or feature

### Why This Approach?

Explain the business value or technical advantage. Consider using a comparison:

**Traditional Approach:**
```
Component A → Component B → Component C
         ↓
    Pain points listed here
```

**This Approach:**
```
Simplified flow
         ↓
    Benefits listed here
```

### Use Cases

- Use case 1
- Use case 2
- Use case 3

## Architecture

Include an architecture diagram. ASCII diagrams work well and don't require external tools:

```
┌─────────────────┐
│   Component A   │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│   Component B   │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│   Component C   │
└─────────────────┘
```

For complex architectures, consider linking to an image file:

![Architecture Diagram](./docs/architecture.png)

## Prerequisites

### AWS Resources

List AWS resources that must exist before deployment:

1. **Resource Type** - Description and any specific configuration
2. **IAM Permissions** - Required permissions (include sample policy if helpful)

### Local Environment

- Tool 1 with version requirement
- Tool 2 with version requirement
- AWS CLI configured with appropriate credentials

## Deployment

### Step 1: [First Step Title]

```bash
# Commands to run
command --with-flags
```

Brief explanation of what this step does.

### Step 2: [Second Step Title]

```bash
# More commands
another-command
```

### Step 3: [Third Step Title]

Continue with remaining steps...

### Verification

How to verify the deployment was successful:

```bash
# Command to check status
aws service describe-something --name example
```

Expected output or success indicators.

## Usage

Show how to use the deployed sample:

```bash
# Example usage
./run-example.sh
```

Include sample queries, API calls, or interactions as appropriate.

## Configuration Reference

| Parameter | Default | Description |
|-----------|---------|-------------|
| `PARAM_NAME` | `default-value` | What this parameter controls |
| `ANOTHER_PARAM` | `default` | Description |

## File Descriptions

| File | Description |
|------|-------------|
| `main-file.py` | Primary script that does X |
| `config.yaml` | Configuration for Y |
| `helper.sql` | SQL queries for Z |

## Cleanup

**Important:** Follow these steps to avoid ongoing charges.

### Step 1: Remove [Component]

```bash
# Delete command
aws service delete-thing --name example
```

### Step 2: Remove [Another Component]

```bash
# Another delete command
aws service delete-other-thing --name example
```

### Step 3: Verify Cleanup

```bash
# Verify resources are deleted
aws service list-things
```

## Troubleshooting

### Issue: [Common Problem 1]

**Symptoms:** What the user sees

**Cause:** Why this happens

**Solution:** How to fix it

### Issue: [Common Problem 2]

**Symptoms:** Description

**Solution:** Fix

## Best Practices

1. **Practice 1** - Explanation
2. **Practice 2** - Explanation
3. **Practice 3** - Explanation

## Cost Considerations

Estimate the AWS costs for running this sample:

| Resource | Estimated Cost | Notes |
|----------|---------------|-------|
| Service A | ~$X/hour | Usage assumptions |
| Service B | ~$Y/month | Usage assumptions |

**Tip:** Remember to clean up resources when not in use.

## Further Reading

- [Official Documentation](https://docs.aws.amazon.com/...)
- [Related Blog Post](https://aws.amazon.com/blogs/...)
- [Additional Resource](https://...)

---

## Template Checklist

Before publishing your sample, ensure you have:

- [ ] Clear, descriptive title
- [ ] Services and complexity tags
- [ ] Overview explaining what and why
- [ ] Architecture diagram (even ASCII is fine)
- [ ] Complete prerequisites list
- [ ] Step-by-step deployment instructions
- [ ] Usage examples
- [ ] **Complete cleanup instructions**
- [ ] Troubleshooting section for common issues
- [ ] Links to relevant documentation
