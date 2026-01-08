# Nexus CMDB Documentation

[![Documentation CI](https://github.com/example-org/nexus-cmdb-docs/actions/workflows/docs-ci.yml/badge.svg)](https://github.com/example-org/nexus-cmdb-docs/actions/workflows/docs-ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

Production-quality documentation site for **Nexus CMDB**, a fictional enterprise Configuration Management Database solution. This repository demonstrates best practices for technical documentation using [MkDocs](https://www.mkdocs.org/) with [Material for MkDocs](https://squidfunk.github.io/mkdocs-material/) theme, strictly following the [Diátaxis framework](https://diataxis.fr/).

## 📚 Documentation Structure

The documentation is organized into four pillars:

- **Tutorials** – Learning-oriented guides to get started with Nexus CMDB
- **How-To Guides** – Task-oriented recipes for solving specific problems
- **Discussions** – Understanding-oriented explanations of concepts and architecture
- **Reference** – Information-oriented technical specifications and API documentation

## 🚀 Quick Start

### Prerequisites

- Python 3.8 or higher
- pip package manager

### Local Development

1. Clone the repository:

   ```bash
   git clone https://github.com/example-org/nexus-cmdb-docs.git
   cd nexus-cmdb-docs
   ```

2. Create a virtual environment:

   ```bash
   python3 -m venv venv
   source venv/bin/activate  # On Windows: venv\Scripts\activate
   ```

3. Install dependencies:

   ```bash
   pip install -r requirements-dev.txt
   ```

4. Set up pre-commit hooks:

   ```bash
   pre-commit install
   pre-commit install --hook-type pre-push
   ```

5. Serve the documentation locally:

   ```bash
   mkdocs serve
   ```

6. Open your browser at `http://127.0.0.1:8000`

### Building for Production

```bash
mkdocs build --strict
```

The static site will be generated in the `site/` directory.

## 🔧 Development Workflow

### Making Changes

1. Create a feature branch from `develop`:

   ```bash
   git checkout -b feature/your-feature-name develop
   ```

2. Make your changes following the [Diátaxis framework](https://diataxis.fr/)

3. Run local checks (pre-commit hooks run automatically on commit/push):

   ```bash
   # Run all pre-commit hooks manually
   pre-commit run --all-files

   # Preview locally
   mkdocs serve
   ```

4. Commit and push:

   ```bash
   git add .
   git commit -m "Add: Brief description of changes"
   git push origin feature/your-feature-name
   ```

5. Open a Pull Request to `develop`

### CI/CD Pipeline

The GitHub Actions workflow automatically:

- ✅ Lints all markdown files
- ✅ Builds the documentation site with strict error checking
- ✅ Checks for broken links
- ✅ Deploys to GitHub Pages (on merge to `main`)

## 📝 Contributing

We welcome contributions! Please see our [Contributing Guidelines](CONTRIBUTING.md) for details.

### Documentation Guidelines

- Follow the [Diátaxis framework](https://diataxis.fr/) strictly
- Place content in the correct pillar based on its purpose
- Use clear, concise language appropriate for the audience
- Include code examples with proper syntax highlighting
- Add diagrams using Mermaid where helpful
- Keep line length under 120 characters
- End files with a newline character

### Markdown Standards

This project uses [markdownlint](https://github.com/DavidAnson/markdownlint) to enforce consistent Markdown style. Configuration is in `.markdownlint.json`.

Key rules:

- Use ATX-style headers (`#` prefix)
- Use dashes (`-`) for unordered lists
- Maximum line length: 120 characters
- Indent lists by 2 spaces
- One blank line around code blocks

## 🛠️ Tech Stack

- **[MkDocs](https://www.mkdocs.org/)** – Static site generator
- **[Material for MkDocs](https://squidfunk.github.io/mkdocs-material/)** – Beautiful, feature-rich theme
- **[PyMdown Extensions](https://facelessuser.github.io/pymdown-extensions/)** – Enhanced markdown features
- **[GitHub Actions](https://github.com/features/actions)** – CI/CD automation
- **[markdownlint](https://github.com/DavidAnson/markdownlint)** – Markdown linting
- **[Lychee](https://github.com/lycheeverse/lychee)** – Fast link checker

## 📦 Dependencies

### Production Dependencies

```txt
mkdocs>=1.5.0
mkdocs-material>=9.4.0
mkdocs-minify-plugin>=0.7.0
mkdocs-redirects>=1.2.0
pymdown-extensions>=10.0
```

### Development Dependencies

```txt
pre-commit>=3.6.0
```

Note: markdownlint-cli2 is installed automatically by pre-commit (Node.js-based tool).

Install all dependencies:

```bash
pip install -r requirements-dev.txt
```

## 🗂️ Repository Structure

```
nexus-cmdb-docs/
├── .github/
│   ├── workflows/
│   │   └── docs-ci.yml          # CI/CD pipeline
│   └── pull_request_template.md # PR template
├── docs/                         # Documentation source
│   ├── index.md                  # Landing page
│   ├── tutorials/                # Learning-oriented guides
│   ├── how-to/                   # Task-oriented recipes
│   ├── discussions/              # Conceptual explanations
│   └── reference/                # Technical specifications
├── .editorconfig                 # Editor configuration
├── .gitignore                    # Git ignore rules
├── .markdownlint.json            # Markdown linting config
├── .pre-commit-config.yaml       # Git hooks configuration
├── mkdocs.yml                    # MkDocs configuration
├── README.md                     # This file
├── requirements.txt              # Python dependencies
└── requirements-dev.txt          # Development dependencies
```

## 🌐 Deployment

The documentation is automatically deployed to GitHub Pages when changes are merged to `main`. The site is available at:

**https://example-org.github.io/nexus-cmdb-docs/**

### Manual Deployment

```bash
mkdocs gh-deploy --force
```

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🤝 Support

- **Issues**: [GitHub Issues](https://github.com/example-org/nexus-cmdb-docs/issues)
- **Discussions**: [GitHub Discussions](https://github.com/example-org/nexus-cmdb-docs/discussions)
- **Email**: docs@nexus-cmdb.example.com

## 🙏 Acknowledgments

- Documentation structure follows the [Diátaxis framework](https://diataxis.fr/) by Daniele Procida
- Theme by [squidfunk/mkdocs-material](https://github.com/squidfunk/mkdocs-material)
- Inspired by best-in-class technical documentation from Stripe, Twilio, and AWS

---

**Note**: Nexus CMDB is a fictional product created for demonstration purposes. This repository serves as an example of production-quality technical documentation.
