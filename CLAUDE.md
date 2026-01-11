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
├── docs/
│   └── index.html                      # GitHub Pages portfolio site
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

## GitHub Pages Documentation Site

The repository includes a portfolio site hosted on GitHub Pages that provides a searchable, filterable catalog of all samples.

### How It Works

```
┌─────────────────────┐
│   catalog.yaml      │  ← Single source of truth
└─────────┬───────────┘
          │ fetched at runtime
          ▼
┌─────────────────────┐
│   docs/index.html   │  ← Static HTML + JavaScript
│   - Parses YAML     │
│   - Renders cards   │
│   - Filters/search  │
└─────────┬───────────┘
          │
          ▼
┌─────────────────────┐
│   GitHub Pages      │  ← Hosted at github.io
└─────────────────────┘
```

**Key design decisions:**
- **No build step**: The site is a single HTML file with vanilla JavaScript
- **No duplication**: Fetches `catalog.yaml` from `raw.githubusercontent.com` at runtime
- **Auto-updates**: Adding a sample to `catalog.yaml` automatically appears on the site

### File Location

```
docs/
└── index.html    # The complete site (HTML, CSS, JS in one file)
```

### Configuration

The site has configuration variables at the top of the `<script>` section in `docs/index.html`:

```javascript
const GITHUB_USER = 'greg-h-k';      // GitHub username
const GITHUB_REPO = 'data-and-ai-samples';  // Repository name
const GITHUB_BRANCH = 'main';        // Branch to fetch catalog from
```

Update these if the repository is forked or renamed.

### Local Development

To test the site locally:

```bash
# From repository root
python3 -m http.server 8000

# Then open http://localhost:8000/docs/
```

The site detects local development vs GitHub Pages and adjusts the catalog fetch path accordingly.

### Features

The site provides:

| Feature | Description |
|---------|-------------|
| **Search** | Filters across title, description, tags, and services |
| **Category filter** | Filter by top-level category (auto-populated from catalog) |
| **Complexity filter** | Filter by beginner/intermediate/advanced |
| **Service filter** | Filter by AWS service (auto-populated from catalog) |
| **Sample cards** | Display title, description, badges, services, and tags |
| **Direct links** | Cards link to sample folders in the GitHub repository |

### Extending the Site

#### Adding new filters

To add a new filter (e.g., by programming language):

1. Add a new `<select>` element in the `.filter-groups` div
2. Populate options in the `populateFilters()` function
3. Add filter logic in `getFilteredSamples()`
4. Add event listener for the new select

Example:
```javascript
// In populateFilters()
const languages = [...new Set(allSamples.flatMap(s => s.languages || []))].sort();
const langSelect = document.getElementById('filter-language');
languages.forEach(lang => {
    const option = document.createElement('option');
    option.value = lang;
    option.textContent = lang;
    langSelect.appendChild(option);
});

// In getFilteredSamples()
const language = document.getElementById('filter-language').value;
if (language && !(sample.languages || []).includes(language)) return false;
```

#### Styling changes

All CSS is in the `<style>` section at the top of `index.html`. Key classes:

| Class | Purpose |
|-------|---------|
| `.sample-card` | Individual sample card container |
| `.badge` | Tag/label styling |
| `.badge-complexity` | Complexity level badges (has `.beginner`, `.intermediate`, `.advanced` variants) |
| `.service-tag` | AWS service tags |
| `.tag` | General tags |
| `.filters` | Filter container |
| `.search-box` | Search input styling |

#### Adding new card fields

To display additional metadata from `catalog.yaml`:

1. Add the field to samples in `catalog.yaml`
2. Update the card template in `renderSamples()`:

```javascript
grid.innerHTML = filtered.map(sample => `
    <div class="sample-card">
        ...
        <div class="new-field">${sample.new_field || 'Default'}</div>
        ...
    </div>
`).join('');
```

### GitHub Pages Setup

The site is configured to deploy from the `/docs` folder on the `main` branch:

1. Go to repository Settings → Pages
2. Source: "Deploy from a branch"
3. Branch: `main`, folder: `/docs`
4. Save

The site will be available at `https://<username>.github.io/data-and-ai-samples/`

### Maintenance Checklist

When updating the docs site:

- [ ] Test locally before pushing (`python3 -m http.server 8000`)
- [ ] Verify catalog.yaml is valid YAML (site will fail silently on parse errors)
- [ ] Check that new samples appear correctly after push
- [ ] Test all filters work with new data
- [ ] Verify links to samples work correctly
