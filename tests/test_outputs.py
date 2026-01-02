
import pytest
import os
import re

DOT_FILE = '/workspace/output/dependencies.dot'
MD_FILE = '/workspace/output/report.md'

def test_dot_file_exists():
    """Verify that the dependencies.dot file was created."""
    assert os.path.exists(DOT_FILE), \
        f"Output file {DOT_FILE} not found"

def test_markdown_file_exists():
    """Verify that the report.md file was created."""
    assert os.path.exists(MD_FILE), \
        f"Output file {MD_FILE} not found"

def test_dot_file_valid_syntax():
    """Verify the .dot file has valid Graphviz syntax."""
    with open(DOT_FILE, 'r') as f:
        content = f.read()
    
    assert content.startswith('digraph Dependencies'), \
        "DOT file must start with 'digraph Dependencies'"
    assert content.strip().endswith('}'), \
        "DOT file must end with closing brace"
    assert 'rankdir' in content, \
        "DOT file must specify rankdir"

def test_dot_has_clusters():
    """Verify the .dot file contains subgraph clusters for bounded contexts."""
    with open(DOT_FILE, 'r') as f:
        content = f.read()
    
    clusters = re.findall(r'subgraph cluster_\d+', content)
    assert len(clusters) >= 3, \
        f"Expected at least 3 bounded context clusters, found {len(clusters)}"

def test_dot_has_nodes():
    """Verify the .dot file contains node definitions."""
    with open(DOT_FILE, 'r') as f:
        content = f.read()
    
    # Check for node attributes
    assert 'fillcolor=' in content, \
        "Nodes must have fillcolor attribute"
    assert 'shape=' in content, \
        "Nodes must have shape attribute"
    assert 'label=' in content, \
        "Nodes must have label attribute"


def test_markdown_has_required_sections():
    """Verify the Markdown report contains all required sections."""
    with open(MD_FILE, 'r') as f:
        content = f.read()
    
    required_sections = [
        '# Dependency Analysis Report',
        '## Summary by Language',
        '## Bounded Contexts',
        '## Critical Modules',
        '## Recommendations'
    ]
    
    for section in required_sections:
        assert section in content, \
            f"Markdown report missing required section: {section}"

def test_markdown_has_language_table():
    """Verify the language summary table exists and is properly formatted."""
    with open(MD_FILE, 'r') as f:
        content = f.read()
    
    # Check for table header
    assert '| Language | Modules | Lines of Code |' in content, \
        "Language summary table header missing"
    
    # Check for at least one language entry
    languages = ['javascript', 'python', 'go']
    found_language = any(lang in content.lower() for lang in languages)
    assert found_language, \
        "Language summary must include at least one language"

def test_markdown_has_bounded_contexts():
    """Verify bounded context sections exist."""
    with open(MD_FILE, 'r') as f:
        content = f.read()
    
    # Check for expected contexts
    expected_contexts = ['authentication', 'payment', 'inventory']
    found_contexts = sum(1 for ctx in expected_contexts if ctx in content.lower())
    
    assert found_contexts >= 2, \
        f"Expected at least 2 bounded contexts, found {found_contexts}"

def test_markdown_has_critical_modules_table():
    """Verify critical modules table format."""
    with open(MD_FILE, 'r') as f:
        content = f.read()
    
    # Look for table structure
    critical_section = content.split('## Critical Modules')[1].split('##')[0]
    
    # Should have either a table or "No critical modules" message
    has_table = '| Module | Language | Type | Fan-in | Fan-out | Lines |' in critical_section
    has_no_critical = 'No critical modules' in critical_section
    
    assert has_table or has_no_critical, \
        "Critical modules section must have table or no-critical message"

def test_markdown_has_metrics():
    """Verify the report includes total modules and dependencies."""
    with open(MD_FILE, 'r') as f:
        content = f.read()
    
    assert 'Total Modules:' in content, \
        "Report must include total module count"
    assert 'Total Dependencies:' in content, \
        "Report must include total dependency count"

def test_markdown_has_recommendations():
    """Verify recommendations section has actionable content."""
    with open(MD_FILE, 'r') as f:
        content = f.read()
    
    rec_section = content.split('## Recommendations')[1] if '## Recommendations' in content else ''
    
    # Should have at least 2 bullet points
    bullets = rec_section.count('\n-')
    assert bullets >= 2, \
        f"Recommendations should have at least 2 points, found {bullets}"

def test_fan_in_calculated():
    """Verify fan-in metrics are present in critical modules table."""
    with open(MD_FILE, 'r') as f:
        content = f.read()
    
    # If there are critical modules, they should have fan-in values
    if '| Module | Language | Type | Fan-in | Fan-out | Lines |' in content:
        # Check for numeric fan-in values in table
        lines = content.split('\n')
        table_lines = [l for l in lines if l.startswith('|') and 'Module' not in l and '---' not in l]
        
        if table_lines:  # If critical modules exist
            # At least one should have fan-in > 3 or fan-out > 5
            found_critical = False
            for line in table_lines:
                parts = [p.strip() for p in line.split('|')]
                if len(parts) >= 6:
                    try:
                        fan_in = int(parts[4])
                        fan_out = int(parts[5])
                        if fan_in > 3 or fan_out > 5:
                            found_critical = True
                            break
                    except (ValueError, IndexError):
                        pass
            
            assert found_critical, \
                "Critical modules must have fan-in > 3 OR fan-out > 5"

def test_multiple_languages_detected():
    """Verify analyzer detected multiple programming languages."""
    with open(MD_FILE, 'r') as f:
        content = f.read()
    
    language_count = sum([
        'javascript' in content.lower(),
        'python' in content.lower(),
        'go' in content.lower()
    ])
    
    assert language_count >= 2, \
        f"Expected at least 2 languages detected, found {language_count}"

def test_no_solution_cheating():
    """Verify solution didn't cheat by copying test files."""
    assert not os.path.exists('/workspace/tests/test_outputs.py.bak'), \
        "Solution should not access test files"
    
    # Verify output files were generated, not copied
    with open(DOT_FILE, 'r') as f:
        dot_content = f.read()
    
    # Should contain actual module names from sample repo
    assert 'auth' in dot_content or 'payment' in dot_content or 'inventory' in dot_content, \
        "DOT file should contain actual analyzed modules"