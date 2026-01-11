# Claude Instructions for Data and AI Samples Repository

This file provides guidance for maintaining consistency when adding new samples, updating documentation, or making changes to this portfolio repository.

## Repository Purpose

This is a portfolio of AWS samples, demos, and proof-of-concepts covering data engineering, analytics, machine learning, and AI services. Each sample should be self-contained, well-documented, and easy for others to understand and deploy.

## Directory Structure

```
data-and-ai-samples/
├── README.md                           # Portfolio landing page with catalog
├── CLAUDE.md                           # This file - AI assistant instructions
├── SAMPLE_TEMPLATE.md                  # Template for sample READMEs
├── catalog.yaml                        # Machine-readable sample metadata
├── data-engineering-and-analytics/
│   ├── streaming/                      # Real-time: Kinesis, MSK, Flink
│   ├── batch/                          # Batch ETL: Glue, EMR
│   ├── orchestration/                  # Workflows: MWAA, Step Functions
│   ├── storage/                        # Data lakes, S3, Lake Formation
│   └── warehousing/                    # Redshift patterns
├── machine-learning-and-ai/
│   ├── generative-ai/                  # Bedrock, LLMs, RAG, agents
│   ├── sagemaker/                      # Training, deployment, MLOps
│   ├── computer-vision/                # Rekognition, custom models
│   └── nlp/                            # Comprehend, Transcribe, Translate
└── serverless/
    ├── api-patterns/                   # API Gateway, Lambda, AppSync
    ├── event-driven/                   # EventBridge, SQS, SNS
    └── containers/                     # ECS, Fargate serverless patterns
```

## Naming Conventions

### Directory and File Names
- Use **lowercase with hyphens** for all directories and files
- Be descriptive but concise
- Avoid version numbers, dates, or ambiguous abbreviations

**Good examples:**
- `bedrock-knowledge-base-aurora`
- `lambda-s3-event-processor`
- `sagemaker-realtime-inference`

**Bad examples:**
- `kb_demo_v2` (underscores, abbreviation, version)
- `BedrockKB` (camel case)
- `my-test-project` (not descriptive)

### Sample Placement
Place samples in the most specific applicable subcategory:
- A Bedrock RAG sample → `machine-learning-and-ai/generative-ai/`
- A Kinesis to Redshift pipeline → `data-engineering-and-analytics/streaming/`
- A Lambda API pattern → `serverless/api-patterns/`

## Documentation Standards

Every sample MUST have a `README.md` following this structure:

### Required Sections

```markdown
# [Sample Title]

> **Services:** Service1, Service2, Service3
> **Complexity:** Beginner | Intermediate | Advanced
> **Tags:** `tag1` `tag2` `tag3`

One-paragraph description of what this sample does and the problem it solves.

## Overview

### What This Sample Does
- Bullet points explaining capabilities

### Why This Approach?
Explain the value proposition, optionally with before/after comparison diagrams.

### Use Cases
- Applicable scenarios

## Architecture

Include a diagram (ASCII art is acceptable):

```
┌─────────────┐     ┌─────────────┐
│ Component A │────▶│ Component B │
└─────────────┘     └─────────────┘
```

## Prerequisites

### AWS Resources
List required AWS resources and permissions.

### Local Environment
List required tools and versions.

## Deployment

Step-by-step instructions with code blocks.

## Usage

How to use/test the deployed sample.

## Configuration Reference

Table of configurable parameters.

## File Descriptions

Table explaining each file in the sample.

## Cleanup

**CRITICAL: Every sample MUST include cleanup instructions.**

Step-by-step resource deletion to avoid ongoing charges.

## Troubleshooting

Common issues and solutions.

## Best Practices

Recommendations for production use.

## Further Reading

Links to official documentation.
```

### Complexity Levels

| Level | Criteria |
|-------|----------|
| **Beginner** | Single service, minimal config, <30 min to deploy |
| **Intermediate** | 2-4 services, some integration, 30-60 min to deploy |
| **Advanced** | 5+ services, complex architecture, >60 min to deploy |

### Tag Guidelines

Use consistent, lowercase tags. Common tags include:

**Technology tags:**
- `streaming`, `batch`, `real-time`, `etl`
- `serverless`, `containers`, `event-driven`
- `machine-learning`, `generative-ai`, `rag`, `agents`
- `api`, `rest`, `graphql`, `websocket`

**Use case tags:**
- `iot`, `analytics`, `data-lake`, `data-warehouse`
- `chatbot`, `document-processing`, `image-analysis`
- `cost-optimization`, `security`, `monitoring`

**Data format tags:**
- `json`, `parquet`, `csv`, `binary`

## Catalog Metadata (catalog.yaml)

When adding a new sample, add an entry to `catalog.yaml`:

```yaml
- name: sample-name                    # Matches directory name
  title: Human Readable Title          # Display title
  description: One-line description    # Brief summary
  path: category/subcategory/sample    # Relative path from root
  category: data-engineering-and-analytics | machine-learning-and-ai | serverless
  subcategory: streaming | batch | generative-ai | etc.
  services:                            # AWS services used
    - Amazon Service Name
    - Another Service
  tags:                                # Searchable keywords
    - tag1
    - tag2
  complexity: beginner | intermediate | advanced
  languages:                           # Programming languages
    - python
    - typescript
    - sql
  last_updated: YYYY-MM-DD            # Date of last significant update
```

## Root README Updates

When adding a new sample, update the catalog table in the root `README.md`:

```markdown
| [sample-name](./path/to/sample/) | Brief description | Services | Complexity |
```

Group samples under the appropriate category heading.

## Checklist for Adding New Samples

When creating a new sample, verify:

- [ ] Directory name follows lowercase-with-hyphens convention
- [ ] Placed in correct category/subcategory
- [ ] README.md includes all required sections
- [ ] Service and complexity tags at top of README
- [ ] Architecture diagram included (even ASCII is fine)
- [ ] Prerequisites clearly listed
- [ ] Step-by-step deployment instructions
- [ ] Usage examples provided
- [ ] **Cleanup instructions are complete and tested**
- [ ] Troubleshooting section for common issues
- [ ] Entry added to `catalog.yaml`
- [ ] Entry added to root `README.md` catalog table
- [ ] All code files have appropriate comments
- [ ] No hardcoded account IDs, regions, or credentials
- [ ] Placeholder values clearly marked (e.g., `YOUR_ACCOUNT_ID`)

## Style Guidelines

### Code Blocks
- Always specify the language for syntax highlighting
- Use comments to explain non-obvious steps
- Show expected output where helpful

```bash
# Create the S3 bucket
aws s3 mb s3://my-bucket-name --region us-east-1

# Expected output:
# make_bucket: my-bucket-name
```

### Architecture Diagrams

ASCII diagrams are preferred for simplicity and version control:

```
┌─────────────────┐
│   Component     │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│   Next Step     │
└─────────────────┘
```

Box-drawing characters to use:
- Corners: `┌ ┐ └ ┘`
- Lines: `─ │`
- Arrows: `▲ ▼ ◀ ▶ → ← ↑ ↓`
- Connectors: `┬ ┴ ├ ┤ ┼`

For complex architectures, image files are acceptable. Place in a `docs/` subdirectory.

### Tables

Use tables for:
- Configuration parameters
- File descriptions
- Feature comparisons
- Cost estimates

```markdown
| Parameter | Default | Description |
|-----------|---------|-------------|
| `PARAM_1` | `value` | What it does |
```

## Common Mistakes to Avoid

1. **Missing cleanup instructions** - Every sample must explain how to delete resources
2. **Hardcoded values** - Use placeholders like `YOUR_ACCOUNT_ID`, `YOUR_REGION`
3. **Missing prerequisites** - List ALL required tools, permissions, and resources
4. **Vague descriptions** - Be specific about what the sample does and why
5. **No architecture diagram** - Even a simple diagram dramatically improves understanding
6. **Inconsistent naming** - Follow the lowercase-with-hyphens convention
7. **Forgetting catalog updates** - Update both `catalog.yaml` and root `README.md`

## Updating Existing Samples

When modifying an existing sample:

1. Update the `last_updated` field in `catalog.yaml`
2. If services change, update tags in README and `catalog.yaml`
3. Ensure cleanup instructions still match the current architecture
4. Test deployment instructions still work
