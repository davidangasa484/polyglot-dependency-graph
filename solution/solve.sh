#!/bin/bash
# CANARY_STRING: polyglot_dep_graph_2025_v1

set -e

cd /workspace

# Create the analyzer script
cat > analyzer.py << 'ANALYZER_EOF'
#!/usr/bin/env python3
import os
import re
import json
from pathlib import Path
from collections import defaultdict
from datetime import datetime

class DependencyAnalyzer:
    def __init__(self, repo_path, contexts_path):
        self.repo_path = Path(repo_path)
        self.contexts = self.load_contexts(contexts_path)
        self.modules = {}
        self.dependencies = []
        self.exclude_dirs = ['node_modules', '__pycache__', '.git', 'dist']
        
    def load_contexts(self, path):
        with open(path, 'r') as f:
            return json.load(f)
    
    def analyze(self):
        self.scan_directory(self.repo_path)
        self.calculate_metrics()
        
    def scan_directory(self, path):
        for root, dirs, files in os.walk(path):
            dirs[:] = [d for d in dirs if d not in self.exclude_dirs]
            
            for file in files:
                filepath = Path(root) / file
                if file.endswith(('.js', '.ts', '.jsx', '.tsx')):
                    self.analyze_js_file(filepath)
                elif file.endswith('.py'):
                    self.analyze_py_file(filepath)
                elif file.endswith('.go'):
                    self.analyze_go_file(filepath)
    
    def analyze_js_file(self, filepath):
        content = filepath.read_text()
        module_name = self.get_module_name(filepath)
        
        imports = []
        # Match require and import statements
        for match in re.finditer(r"(?:require|import)\s*\(?['\"]([^'\"]+)['\"]", content):
            imports.append(match.group(1))
        for match in re.finditer(r"from\s+['\"]([^'\"]+)['\"]", content):
            imports.append(match.group(1))
        
        self.modules[module_name] = {
            'language': 'javascript',
            'path': str(filepath.relative_to(self.repo_path)),
            'lines': len(content.split('\n')),
            'imports': imports,
            'type': self.infer_type(filepath.name),
            'fan_in': 0,
            'fan_out': 0
        }
        
        for imp in imports:
            if not imp.startswith('.') and not imp.startswith('@'):
                continue
            self.dependencies.append((module_name, imp))
    
    def analyze_py_file(self, filepath):
        content = filepath.read_text()
        module_name = self.get_module_name(filepath)
        
        imports = []
        for match in re.finditer(r"^import\s+([^\s#]+)", content, re.MULTILINE):
            imports.append(match.group(1))
        for match in re.finditer(r"^from\s+([^\s]+)\s+import", content, re.MULTILINE):
            imports.append(match.group(1))
        
        self.modules[module_name] = {
            'language': 'python',
            'path': str(filepath.relative_to(self.repo_path)),
            'lines': len(content.split('\n')),
            'imports': imports,
            'type': self.infer_type(filepath.name),
            'fan_in': 0,
            'fan_out': 0
        }
        
        for imp in imports:
            self.dependencies.append((module_name, imp))
    
    def analyze_go_file(self, filepath):
        content = filepath.read_text()
        module_name = self.get_module_name(filepath)
        
        imports = []
        for match in re.finditer(r'import\s+"([^"]+)"', content):
            imports.append(match.group(1))
        
        # Handle multi-line imports
        for match in re.finditer(r'import\s+\(([\s\S]*?)\)', content):
            for imp in re.finditer(r'"([^"]+)"', match.group(1)):
                imports.append(imp.group(1))
        
        self.modules[module_name] = {
            'language': 'go',
            'path': str(filepath.relative_to(self.repo_path)),
            'lines': len(content.split('\n')),
            'imports': imports,
            'type': self.infer_type(filepath.name),
            'fan_in': 0,
            'fan_out': 0
        }
        
        for imp in imports:
            self.dependencies.append((module_name, imp))
    
    def get_module_name(self, filepath):
        rel_path = filepath.relative_to(self.repo_path)
        return str(rel_path.with_suffix('')).replace(os.sep, '/')
    
    def infer_type(self, filename):
        name = filename.lower()
        if 'controller' in name or 'handler' in name or 'route' in name:
            return 'api'
        if 'service' in name:
            return 'service'
        if 'repository' in name or 'model' in name:
            return 'data'
        if 'util' in name or 'helper' in name:
            return 'utility'
        return 'component'
    
    def calculate_metrics(self):
        # Calculate fan-out
        for module in self.modules:
            internal_deps = 0
            for from_mod, to_mod in self.dependencies:
                if from_mod == module:
                    # Check if it's internal
                    if any(to_mod in mod for mod in self.modules):
                        internal_deps += 1
            self.modules[module]['fan_out'] = internal_deps
        
        # Calculate fan-in
        for module in self.modules:
            fan_in = 0
            for from_mod, to_mod in self.dependencies:
                if to_mod in module or module in to_mod:
                    if from_mod != module:
                        fan_in += 1
            self.modules[module]['fan_in'] = fan_in
    
    def assign_contexts(self):
        result = defaultdict(list)
        for module in self.modules:
            assigned = False
            for context, patterns in self.contexts.items():
                if any(pattern in module for pattern in patterns):
                    result[context].append(module)
                    assigned = True
                    break
            if not assigned:
                result['uncategorized'].append(module)
        return result
    
    def generate_dot(self, output_path):
        contexts = self.assign_contexts()
        
        with open(output_path, 'w') as f:
            f.write('digraph Dependencies {\n')
            f.write('  rankdir=LR;\n')
            f.write('  node [shape=box, style="rounded,filled"];\n\n')
            
            # Create clusters
            for idx, (context, modules) in enumerate(contexts.items()):
                f.write(f'  subgraph cluster_{idx} {{\n')
                f.write(f'    label="{context}";\n')
                f.write('    style=filled;\n')
                f.write('    color=lightgrey;\n\n')
                
                for mod in modules:
                    module = self.modules[mod]
                    is_critical = module['fan_in'] > 3 or module['fan_out'] > 5
                    
                    color = '#FF9999' if is_critical else {
                        'api': '#FFE5CC',
                        'service': '#CCE5FF',
                        'data': '#E5CCFF',
                        'utility': '#E5E5E5',
                        'component': '#CCFFCC'
                    }.get(module['type'], '#FFFFFF')
                    
                    shape = 'diamond' if is_critical else 'box'
                    label = f"{mod}\\n({module['language']})\\n{module['lines']}L"
                    
                    f.write(f'    "{mod}" [fillcolor="{color}", shape={shape}, label="{label}"];\n')
                
                f.write('  }\n\n')
            
            # Add edges
            f.write('  // Dependencies\n')
            for from_mod, to_mod in self.dependencies:
                # Only show internal dependencies
                matching = [m for m in self.modules if to_mod in m or m in to_mod]
                if matching and from_mod in self.modules:
                    f.write(f'  "{from_mod}" -> "{matching[0]}";\n')
            
            f.write('}\n')
    
    def generate_markdown(self, output_path):
        contexts = self.assign_contexts()
        
        with open(output_path, 'w') as f:
            f.write('# Dependency Analysis Report\n\n')
            f.write(f'**Analysis Date:** {datetime.now().isoformat()}\n')
            f.write(f'**Total Modules:** {len(self.modules)}\n')
            f.write(f'**Total Dependencies:** {len(self.dependencies)}\n\n')
            
            # Language summary
            f.write('## Summary by Language\n\n')
            f.write('| Language | Modules | Lines of Code |\n')
            f.write('|----------|---------|---------------|\n')
            
            lang_stats = defaultdict(lambda: {'count': 0, 'lines': 0})
            for module in self.modules.values():
                lang_stats[module['language']]['count'] += 1
                lang_stats[module['language']]['lines'] += module['lines']
            
            for lang, stats in sorted(lang_stats.items()):
                f.write(f"| {lang} | {stats['count']} | {stats['lines']} |\n")
            f.write('\n')
            
            # Bounded contexts
            f.write('## Bounded Contexts\n\n')
            for context, modules in contexts.items():
                f.write(f'### {context}\n\n')
                f.write(f'Contains {len(modules)} modules:\n\n')
                for mod in modules[:5]:
                    module = self.modules[mod]
                    f.write(f"- **{mod}** ({module['language']}, {module['type']})\n")
                if len(modules) > 5:
                    f.write(f'\n*...and {len(modules) - 5} more modules*\n')
                f.write('\n')
            
            # Critical modules
            f.write('## Critical Modules\n\n')
            critical = [(name, mod) for name, mod in self.modules.items() 
                       if mod['fan_in'] > 3 or mod['fan_out'] > 5]
            
            if critical:
                f.write('| Module | Language | Type | Fan-in | Fan-out | Lines |\n')
                f.write('|--------|----------|------|--------|---------|-------|\n')
                for name, mod in critical:
                    f.write(f"| {name} | {mod['language']} | {mod['type']} | ")
                    f.write(f"{mod['fan_in']} | {mod['fan_out']} | {mod['lines']} |\n")
            else:
                f.write('*No critical modules detected.*\n')
            f.write('\n')
            
            # Recommendations
            f.write('## Recommendations\n\n')
            if len(critical) > 3:
                f.write('- ⚠️ Multiple critical modules detected. Consider refactoring to reduce coupling.\n')
            else:
                f.write('- ✅ Architecture looks healthy with minimal critical modules.\n')
            
            avg_fan_out = sum(m['fan_out'] for m in self.modules.values()) / len(self.modules)
            if avg_fan_out > 5:
                f.write('- ⚠️ High average fan-out suggests potential God objects.\n')
            else:
                f.write('- ✅ Good separation of concerns with low average fan-out.\n')

if __name__ == '__main__':
    analyzer = DependencyAnalyzer('/workspace/data/sample-repo', '/workspace/data/contexts.json')
    analyzer.analyze()
    analyzer.generate_dot('/workspace/output/dependencies.dot')
    analyzer.generate_markdown('/workspace/output/report.md')
    print("Analysis complete!")
ANALYZER_EOF

# Make executable
chmod +x analyzer.py

# Run the analyzer
python3 analyzer.py

# Verify outputs exist
if [ ! -f /workspace/output/dependencies.dot ]; then
    echo "Error: dependencies.dot not generated"
    exit 1
fi

if [ ! -f /workspace/output/report.md ]; then
    echo "Error: report.md not generated"
    exit 1
fi

echo "✅ Dependency analysis completed successfully"