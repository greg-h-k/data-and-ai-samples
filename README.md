# Data and AI Samples

A curated collection of AWS samples, demos, and proof-of-concepts covering data engineering, analytics, machine learning, and AI services.

## About

This repository contains hands-on examples developed through real-world customer engagements and technical explorations. Each sample is self-contained with documentation, deployment instructions, and cleanup steps to help you understand and implement various AWS services and patterns.

## Quick Navigation

| Category | Description |
|----------|-------------|
| [Data Engineering & Analytics](./data-engineering-and-analytics/) | ETL pipelines, streaming, data lakes, warehousing |
| [Machine Learning & AI](./machine-learning-and-ai/) | ML workflows, SageMaker, Bedrock, generative AI |
| [Platform Deployments](./platform-deployments/) | End-to-end platform and service deployments |

## Sample Catalog

### Data Engineering & Analytics

| Sample | Description | Services | Complexity |
|--------|-------------|----------|------------|
| [redshift-streaming](./data-engineering-and-analytics/streaming/redshift-streaming/) | Stream data from Kinesis directly into Redshift using native materialized views | Kinesis, Redshift | Intermediate |
| [msk-multi-region-active-active-demo](./data-engineering-and-analytics/streaming/msk-multi-region-active-active-demo/) | Bidirectional Kafka replication across regions using MSK Serverless and MSK Replicator | Amazon MSK | Intermediate |

### Platform Deployments

| Sample | Description | Services | Complexity |
|--------|-------------|----------|------------|
| [postit-demo-deployment](./platform-deployments/analytics-platforms/postit-demo-deployment/) | Deploy Posit RStudio Server, Shiny Server, and Posit Workbench for data science workloads | EC2, RStudio, Shiny, Posit Workbench | Intermediate |

<!--
### Machine Learning & AI

| Sample | Description | Services | Complexity |
|--------|-------------|----------|------------|
| Coming soon | | | |
-->

## How to Use This Repository

1. **Browse the catalog** above or explore the [catalog.yaml](./catalog.yaml) for machine-readable metadata
2. **Navigate to a sample** that matches your use case
3. **Read the README** in each sample directory for:
   - What the sample does and why it's useful
   - Architecture diagram
   - Prerequisites
   - Step-by-step deployment instructions
   - Cleanup instructions
4. **Deploy and experiment** in your own AWS account

## Common Prerequisites

Most samples in this repository require:

- **AWS Account** with appropriate permissions
- **AWS CLI** configured with credentials ([installation guide](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html))
- **Python 3.8+** for Python-based samples
- **Node.js 18+** for CDK or JavaScript-based samples

Sample-specific prerequisites are listed in each sample's README.

## Complexity Levels

| Level | Description |
|-------|-------------|
| **Beginner** | Single service, minimal configuration, great for learning |
| **Intermediate** | Multiple services, some integration complexity |
| **Advanced** | Complex architectures, production patterns, multiple components |

## Repository Structure

```
data-and-ai-samples/
├── README.md                           # This file
├── catalog.yaml                        # Machine-readable sample metadata
├── SAMPLE_TEMPLATE.md                  # Template for new samples
├── data-engineering-and-analytics/
│   ├── streaming/                      # Real-time data processing
│   ├── batch/                          # Batch ETL and processing
│   └── orchestration/                  # Workflow orchestration
├── machine-learning-and-ai/
│   ├── generative-ai/                  # Bedrock, LLMs, RAG patterns
│   ├── sagemaker/                      # ML training and deployment
│   └── computer-vision/                # Image and video analysis
└── platform-deployments/
    ├── data-platforms/                 # End-to-end data platform deployments
    ├── ml-platforms/                   # MLOps and ML platform infrastructure
    ├── analytics-platforms/            # Complete analytics solutions
    └── ai-platforms/                   # AI service and infrastructure deployments
```

## Contributing

When adding new samples, please:

1. Follow the [SAMPLE_TEMPLATE.md](./SAMPLE_TEMPLATE.md) documentation structure
2. Use lowercase-with-hyphens naming (e.g., `bedrock-knowledge-base-aurora`)
3. Update [catalog.yaml](./catalog.yaml) with sample metadata
4. Include architecture diagrams (even simple ASCII diagrams help)
5. Ensure cleanup instructions are complete

## License

This repository is provided for educational and demonstration purposes.
