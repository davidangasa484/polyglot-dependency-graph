# Polyglot Dependency Graph Analyzer

Build a CLI tool that analyzes a polyglot codebase (Node.js, Python, Go) to generate dependency graphs with bounded context clustering.

## Task Overview

You must create a dependency analysis tool that:
1. Scans a multi-language repository
2. Identifies import/dependency relationships
3. Calculates coupling metrics (fan-in, fan-out)
4. Clusters modules by bounded contexts
5. Generates both Graphviz .dot and Markdown reports

## Input

The repository to analyze is located at: `/workspace/data/sample-repo/`

A bounded context configuration file is provided at: `/workspace/data/contexts.json`

## Requirements

### 1. Language Support

Your analyzer must support:
- **Node.js/TypeScript**: Parse `import`, `require`, `from` statements in `.js`, `.ts`, `.jsx`, `.tsx` files
- **Python**: Parse `import` and `from ... import` statements in `.py` files  
- **Go**: Parse `import` statements in `.go` files

### 2. Dependency Analysis

For each module, calculate:
- **Fan-in**: Number of modules that depend on this module
- **Fan-out**: Number of modules this module depends on
- **Critical status**: Module is critical if fan-in > 3 OR fan-out > 5

### 3. Bounded Context Clustering

Read the context configuration from `/workspace/data/contexts.json` and group modules accordingly.

Format:
```json
{
  "authentication": ["auth", "identity", "user"],
  "payment": ["payment", "billing", "checkout"],
  "inventory": ["inventory", "product", "stock"]
}