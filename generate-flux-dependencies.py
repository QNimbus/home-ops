#!/usr/bin/env python3
"""
Flux Kustomization Dependency Visualizer

This script scans the ./kubernetes directory for Flux Kustomizations (ks.yaml files)
and generates a markdown document with a hierarchical dependency visualization.
"""

import sys
from collections import defaultdict
from pathlib import Path
from typing import Dict, List

import yaml


class KustomizationDependencyVisualizer:
    def __init__(self, kubernetes_dir: str = "./kubernetes"):
        self.kubernetes_dir = Path(kubernetes_dir)
        self.kustomizations: Dict[str, Dict] = {}
        self.dependencies: Dict[str, List[str]] = defaultdict(list)
        self.reverse_dependencies: Dict[str, List[str]] = defaultdict(list)

    def scan_kustomizations(self) -> None:
        """Scan for all ks.yaml files and parse their dependencies."""
        print("Scanning for Kustomizations...")

        # Find all ks.yaml files
        ks_files = list(self.kubernetes_dir.rglob("ks.yaml"))

        for ks_file in ks_files:
            try:
                with open(ks_file, 'r') as f:
                    # Handle multiple YAML documents in one file
                    docs = list(yaml.safe_load_all(f))

                for doc in docs:
                    if doc and doc.get('kind') == 'Kustomization' and \
                       doc.get('apiVersion', '').startswith('kustomize.toolkit.fluxcd.io'):

                        name = doc['metadata']['name']
                        namespace = doc['metadata']['namespace']
                        key = f"{namespace}/{name}"

                        # Store kustomization info
                        self.kustomizations[key] = {
                            'name': name,
                            'namespace': namespace,
                            'file': str(ks_file.relative_to(self.kubernetes_dir.parent)),
                            'path': doc['spec'].get('path', ''),
                            'dependencies': []
                        }

                        # Parse dependencies
                        depends_on = doc['spec'].get('dependsOn', [])
                        for dep in depends_on:
                            dep_name = dep['name']
                            dep_namespace = dep.get('namespace', namespace)  # Default to same namespace
                            dep_key = f"{dep_namespace}/{dep_name}"

                            self.dependencies[key].append(dep_key)
                            self.reverse_dependencies[dep_key].append(key)
                            self.kustomizations[key]['dependencies'].append(dep_key)

            except Exception as e:
                print(f"Error processing {ks_file}: {e}")

        print(f"Found {len(self.kustomizations)} Kustomizations")

    def get_dependency_levels(self) -> Dict[str, int]:
        """Calculate dependency levels for hierarchical visualization."""
        levels = {}
        visited = set()

        def calculate_level(key: str) -> int:
            if key in visited:
                return levels.get(key, 0)

            visited.add(key)

            if not self.dependencies[key]:
                # No dependencies, this is a root level
                levels[key] = 0
                return 0

            # Calculate level based on maximum dependency level + 1
            max_dep_level = -1
            for dep_key in self.dependencies[key]:
                if dep_key in self.kustomizations:
                    dep_level = calculate_level(dep_key)
                    max_dep_level = max(max_dep_level, dep_level)

            levels[key] = max_dep_level + 1
            return levels[key]

        # Calculate levels for all kustomizations
        for key in self.kustomizations:
            calculate_level(key)

        return levels

    def get_roots(self) -> List[str]:
        """Get root kustomizations (those with no dependencies)."""
        return [key for key in self.kustomizations if not self.dependencies[key]]

    def get_all_dependencies(self, key: str, visited: set = None) -> set:
        """Get all dependencies (direct and indirect) for a kustomization."""
        if visited is None:
            visited = set()

        if key in visited:
            return set()  # Avoid circular dependencies

        visited.add(key)
        all_deps = set()

        # Add direct dependencies
        for dep in self.dependencies.get(key, []):
            if dep in self.kustomizations:
                all_deps.add(dep)
                # Recursively add dependencies of dependencies
                all_deps.update(self.get_all_dependencies(dep, visited.copy()))

        return all_deps

    def get_dependency_chain(self, key: str) -> Dict[str, List[str]]:
        """Get the dependency chain showing levels of dependencies."""
        chain = {}
        seen_across_levels = set()

        def build_chain(current_keys: List[str], level: int):
            if not current_keys:
                return

            level_deps = []
            next_level_keys = []

            for current_key in current_keys:
                if current_key not in self.kustomizations:
                    continue

                direct_deps = self.dependencies.get(current_key, [])
                for dep in direct_deps:
                    if dep in self.kustomizations and dep not in seen_across_levels:
                        level_deps.append(dep)
                        seen_across_levels.add(dep)
                        next_level_keys.append(dep)

            if level_deps:
                chain[level] = level_deps
                build_chain(next_level_keys, level + 1)

        # Start with the direct dependencies of the target kustomization
        direct_deps = self.dependencies.get(key, [])
        valid_direct_deps = [dep for dep in direct_deps if dep in self.kustomizations]

        if valid_direct_deps:
            chain[0] = valid_direct_deps
            seen_across_levels.update(valid_direct_deps)
            build_chain(valid_direct_deps, 1)

        return chain

    def generate_markdown(self) -> str:
        """Generate markdown document with dependency visualization."""
        md_content = []

        # Header
        md_content.append("# Flux Kustomization Dependencies")
        md_content.append("")
        md_content.append("This document shows the dependency relationships between all Flux Kustomizations in the cluster.")
        md_content.append("")
        md_content.append(f"**Total Kustomizations:** {len(self.kustomizations)}")
        md_content.append("")

        # Table of Contents
        md_content.append("## Table of Contents")
        md_content.append("")
        md_content.append("1. [Summary by Namespace](#summary-by-namespace)")
        md_content.append("2. [Complete Dependency Overview](#complete-dependency-overview)")
        md_content.append("3. [Deployment Order (Dependency Hierarchy)](#deployment-order-dependency-hierarchy)")
        md_content.append("4. [Detailed Dependency Matrix](#detailed-dependency-matrix)")
        md_content.append("5. [File Locations](#file-locations)")
        md_content.append("")

        # Summary by namespace
        namespaces = defaultdict(list)
        for key, ks in self.kustomizations.items():
            namespaces[ks['namespace']].append(ks['name'])

        md_content.append("## Summary by Namespace")
        md_content.append("")
        md_content.append("| Namespace | Kustomizations | Count |")
        md_content.append("|-----------|----------------|-------|")

        for namespace in sorted(namespaces.keys()):
            kustomizations = sorted(namespaces[namespace])
            count = len(kustomizations)
            ks_list = ", ".join(kustomizations)
            md_content.append(f"| `{namespace}` | {ks_list} | {count} |")

        md_content.append("")

        # Complete dependency overview
        md_content.append("## Complete Dependency Overview")
        md_content.append("")
        md_content.append("This section shows all dependencies (direct and indirect) for each kustomization.")
        md_content.append("")

        # Sort by namespace, then by name for consistent output
        sorted_keys = sorted(self.kustomizations.keys(), key=lambda k: (
            self.kustomizations[k]['namespace'],
            self.kustomizations[k]['name']
        ))

        for key in sorted_keys:
            ks = self.kustomizations[key]
            all_deps = self.get_all_dependencies(key)

            md_content.append(f"### {ks['namespace']}/{ks['name']}")
            md_content.append("")

            if not all_deps:
                md_content.append("**Dependencies:** *None (root level)*")
                md_content.append("")
                continue

            # Get dependency chain
            dep_chain = self.get_dependency_chain(key)

            md_content.append(f"**Total Dependencies:** {len(all_deps)}")
            md_content.append("")

            if dep_chain:
                md_content.append("**Dependency Chain:**")
                md_content.append("")

                for level in sorted(dep_chain.keys()):
                    if dep_chain[level]:
                        level_name = "Direct" if level == 0 else f"Level {level + 1}"
                        deps_at_level = []
                        for dep_key in dep_chain[level]:
                            if dep_key in self.kustomizations:
                                dep_ks = self.kustomizations[dep_key]
                                deps_at_level.append(f"`{dep_ks['namespace']}/{dep_ks['name']}`")

                        if deps_at_level:
                            md_content.append(f"- **{level_name}:** {', '.join(deps_at_level)}")

                md_content.append("")

            # Show all dependencies in a flat list
            all_dep_names = []
            for dep_key in sorted(all_deps):
                if dep_key in self.kustomizations:
                    dep_ks = self.kustomizations[dep_key]
                    all_dep_names.append(f"`{dep_ks['namespace']}/{dep_ks['name']}`")

            if all_dep_names:
                md_content.append("**All Dependencies (flat list):**")
                md_content.append(", ".join(all_dep_names))
                md_content.append("")

            md_content.append("")

        # Dependency hierarchy
        md_content.append("## Deployment Order (Dependency Hierarchy)")
        md_content.append("")
        md_content.append("This shows the deployment order based on dependencies. Items at the top are deployed first.")
        md_content.append("")

        levels = self.get_dependency_levels()
        max_level = max(levels.values()) if levels else 0

        for level in range(max_level + 1):
            level_kustomizations = [key for key, level_num in levels.items() if level_num == level]
            if level_kustomizations:
                md_content.append(f"### Level {level}")
                if level == 0:
                    md_content.append("*Root level - no dependencies*")
                else:
                    md_content.append(f"*Depends on items from level {level-1} and below*")
                md_content.append("")

                # Sort by namespace, then by name
                level_kustomizations.sort(key=lambda k: (
                    self.kustomizations[k]['namespace'],
                    self.kustomizations[k]['name']
                ))

                for key in level_kustomizations:
                    ks = self.kustomizations[key]
                    deps = self.dependencies[key]

                    md_content.append(f"- **{ks['namespace']}/{ks['name']}**")
                    md_content.append(f"  - *File:* `{ks['file']}`")
                    md_content.append(f"  - *Path:* `{ks['path']}`")

                    if deps:
                        dep_names = []
                        for dep_key in deps:
                            if dep_key in self.kustomizations:
                                dep_ks = self.kustomizations[dep_key]
                                dep_names.append(f"`{dep_ks['namespace']}/{dep_ks['name']}`")
                            else:
                                dep_names.append(f"`{dep_key}` ⚠️ *not found*")
                        md_content.append(f"  - *Dependencies:* {', '.join(dep_names)}")

                md_content.append("")

        # Detailed dependency table
        md_content.append("## Detailed Dependency Matrix")
        md_content.append("")
        md_content.append("| Kustomization | Namespace | Dependencies | Dependents |")
        md_content.append("|---------------|-----------|--------------|------------|")

        # Sort by namespace, then by name
        sorted_keys = sorted(self.kustomizations.keys(), key=lambda k: (
            self.kustomizations[k]['namespace'],
            self.kustomizations[k]['name']
        ))

        for key in sorted_keys:
            ks = self.kustomizations[key]
            deps = self.dependencies[key]
            dependents = self.reverse_dependencies[key]

            # Format dependencies
            if deps:
                dep_list = []
                for dep_key in deps:
                    if dep_key in self.kustomizations:
                        dep_ks = self.kustomizations[dep_key]
                        dep_list.append(f"`{dep_ks['namespace']}/{dep_ks['name']}`")
                    else:
                        dep_list.append(f"`{dep_key}` ⚠️")
                deps_str = "<br>".join(dep_list)
            else:
                deps_str = "*None*"

            # Format dependents
            if dependents:
                dependent_list = []
                for dep_key in dependents:
                    if dep_key in self.kustomizations:
                        dep_ks = self.kustomizations[dep_key]
                        dependent_list.append(f"`{dep_ks['namespace']}/{dep_ks['name']}`")
                dependents_str = "<br>".join(dependent_list)
            else:
                dependents_str = "*None*"

            md_content.append(f"| `{ks['name']}` | `{ks['namespace']}` | {deps_str} | {dependents_str} |")

        md_content.append("")

        # Missing dependencies
        missing_deps = set()
        for key, deps in self.dependencies.items():
            for dep_key in deps:
                if dep_key not in self.kustomizations:
                    missing_deps.add(dep_key)

        if missing_deps:
            md_content.append("## ⚠️ Missing Dependencies")
            md_content.append("")
            md_content.append("The following dependencies are referenced but not found:")
            md_content.append("")
            for dep in sorted(missing_deps):
                md_content.append(f"- `{dep}`")
            md_content.append("")

        # File locations
        md_content.append("## File Locations")
        md_content.append("")
        md_content.append("| Kustomization | File Path |")
        md_content.append("|---------------|-----------|")

        for key in sorted_keys:
            ks = self.kustomizations[key]
            md_content.append(f"| `{ks['namespace']}/{ks['name']}` | `{ks['file']}` |")

        md_content.append("")
        md_content.append("---")
        md_content.append("*Generated automatically by the Flux Kustomization Dependency Visualizer*")

        return "\n".join(md_content)

def main():
    """Main function to generate the dependency visualization."""
    visualizer = KustomizationDependencyVisualizer()

    try:
        visualizer.scan_kustomizations()
        markdown_content = visualizer.generate_markdown()

        # Write to file
        output_file = "flux-kustomization-dependencies.md"
        with open(output_file, 'w') as f:
            f.write(markdown_content)

        print(f"✅ Dependency visualization generated: {output_file}")

    except Exception as e:
        print(f"❌ Error generating visualization: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()
