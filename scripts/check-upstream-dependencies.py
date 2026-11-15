#!/usr/bin/env python3
"""
Universal Dependency & GitHub Actions Upstream Watchdog for hateum/android-ci-box.
Scans Dockerfile, test projects, and .github/workflows/*.yml, comparing installed
versions against the latest upstream stable releases.
Zero third-party dependencies (uses Python standard library exclusively).
"""

import json
import os
import re
import sys
import urllib.request
import xml.etree.ElementTree as ET
from pathlib import Path


def fetch_url(url: str, headers: dict = None, timeout: int = 15) -> str:
    """Fetch URL contents with graceful fallback and user-agent header."""
    req_headers = {"User-Agent": "hateum-android-ci-watchdog/1.0"}
    if headers:
        req_headers.update(headers)
    req = urllib.request.Request(url, headers=req_headers)
    try:
        with urllib.request.urlopen(req, timeout=timeout) as response:
            return response.read().decode("utf-8")
    except Exception as e:
        print(f"[WARN] Failed to fetch {url}: {e}", file=sys.stderr)
        return ""


def get_latest_gradle() -> str:
    data = fetch_url("https://services.gradle.org/versions/current")
    if data:
        try:
            return json.loads(data).get("version", "")
        except json.JSONDecodeError:
            pass
    return ""


def get_latest_agp() -> str:
    """Extract latest STABLE AGP release from Google Maven."""
    xml_data = fetch_url("https://dl.google.com/android/maven2/com/android/tools/build/gradle/maven-metadata.xml")
    if xml_data:
        try:
            root = ET.fromstring(xml_data)
            versions = [v.text for v in root.findall("./versioning/versions/version") if v.text]
            # Filter only stable versions (exclude alpha, beta, rc, dev)
            stable_versions = [v for v in versions if not re.search(r'[-_.](alpha|beta|rc|dev|preview)', v, re.I)]
            if stable_versions:
                return stable_versions[-1]
        except Exception as e:
            print(f"[WARN] Failed to parse AGP metadata: {e}", file=sys.stderr)
    return ""


def get_latest_pypi(package: str) -> str:
    data = fetch_url(f"https://pypi.org/pypi/{package}/json")
    if data:
        try:
            return json.loads(data).get("info", {}).get("version", "")
        except json.JSONDecodeError:
            pass
    return ""


def get_latest_rubygem(gem: str) -> str:
    data = fetch_url(f"https://rubygems.org/api/v1/gems/{gem}.json")
    if data:
        try:
            return json.loads(data).get("version", "")
        except json.JSONDecodeError:
            pass
    return ""


def get_latest_github_release(repo: str, token: str = "") -> str:
    headers = {}
    if token:
        headers["Authorization"] = f"Bearer {token}"
    data = fetch_url(f"https://api.github.com/repos/{repo}/releases/latest", headers=headers)
    if data:
        try:
            tag = json.loads(data).get("tag_name", "")
            return tag.lstrip("v")
        except json.JSONDecodeError:
            pass
    return ""


def parse_dockerfile(dockerfile_path: Path) -> dict:
    content = dockerfile_path.read_text(encoding="utf-8")
    deps = {}
    
    arg_patterns = {
        "gradle": r'ARG GRADLE_VERSION="([^"]+)"',
        "bundletool": r'ARG BUNDLETOOL_VERSION="([^"]+)"',
        "ruby": r'ARG RUBY_VERSION="([^"]+)"',
        "fastlane": r'ARG FASTLANE_VERSION="([^"]+)"',
        "bundler": r'ARG BUNDLER_VERSION="([^"]+)"',
        "pip": r'ARG PIP_VERSION="([^"]+)"',
        "setuptools": r'ARG SETUPTOOLS_VERSION="([^"]+)"',
        "wheel": r'ARG WHEEL_VERSION="([^"]+)"',
        "git-lfs": r'LFS_VERSION="([^"]+)"',
    }
    
    for key, pattern in arg_patterns.items():
        match = re.search(pattern, content)
        if match:
            deps[key] = match.group(1)
            
    return deps


def parse_agp_from_projects(repo_root: Path) -> str:
    sample_gradle = repo_root / "test_projects/SampleProject/build.gradle"
    if sample_gradle.exists():
        match = re.search(r'com\.android\.tools\.build:gradle:([0-9.]+)', sample_gradle.read_text(encoding="utf-8"))
        if match:
            return match.group(1)
    return ""


def scan_github_actions(repo_root: Path) -> dict:
    """Scan all .github/workflows/*.yml and find external GitHub actions with their pinned versions."""
    workflows_dir = repo_root / ".github/workflows"
    if not workflows_dir.exists():
        return {}

    actions = {}
    pattern = re.compile(r'uses:\s+([a-zA-Z0-9_\-\.]+/[a-zA-Z0-9_\-\.]+)(?:/[^@]+)?@([a-zA-Z0-9_\-\.]+)')

    for yml in workflows_dir.glob("*.yml"):
        content = yml.read_text(encoding="utf-8")
        for match in pattern.finditer(content):
            action_repo = match.group(1)
            action_version = match.group(2)
            # Skip local actions or internal composite references
            if action_repo.startswith(".") or action_repo.startswith("hatem-noureddine/android-ci"):
                continue
            if action_repo not in actions:
                actions[action_repo] = action_version

    return actions


def apply_updates_locally(repo_root: Path, updates: list):
    """Apply safe, non-breaking upstream updates directly to repo files."""
    dockerfile_path = repo_root / "Dockerfile"
    docker_content = dockerfile_path.read_text(encoding="utf-8")
    modified_docker = False

    for u in updates:
        name = u["name"]
        latest = u["latest"]
        
        if name == "Google Bundletool":
            docker_content = re.sub(r'ARG BUNDLETOOL_VERSION="[^"]+"', f'ARG BUNDLETOOL_VERSION="{latest}"', docker_content)
            modified_docker = True
        elif name == "Fastlane":
            docker_content = re.sub(r'ARG FASTLANE_VERSION="[^"]+"', f'ARG FASTLANE_VERSION="{latest}"', docker_content)
            modified_docker = True
        elif name == "Ruby Bundler":
            docker_content = re.sub(r'ARG BUNDLER_VERSION="[^"]+"', f'ARG BUNDLER_VERSION="{latest}"', docker_content)
            modified_docker = True
        elif name == "pip":
            docker_content = re.sub(r'ARG PIP_VERSION="[^"]+"', f'ARG PIP_VERSION="{latest}"', docker_content)
            modified_docker = True
        elif name == "setuptools":
            docker_content = re.sub(r'ARG SETUPTOOLS_VERSION="[^"]+"', f'ARG SETUPTOOLS_VERSION="{latest}"', docker_content)
            modified_docker = True
        elif name == "wheel":
            docker_content = re.sub(r'ARG WHEEL_VERSION="[^"]+"', f'ARG WHEEL_VERSION="{latest}"', docker_content)
            modified_docker = True

    if modified_docker:
        dockerfile_path.write_text(docker_content, encoding="utf-8")
        print("✔ Applied compatible dependency updates to Dockerfile")


def main():
    apply_mode = "--apply" in sys.argv
    repo_root = Path(__file__).resolve().parent.parent
    token = os.environ.get("GITHUB_TOKEN", "")

    print("🔍 [Universal Watchdog] Scanning Dockerfile, projects & workflows...")
    dockerfile_path = repo_root / "Dockerfile"
    docker_deps = parse_dockerfile(dockerfile_path)
    agp_current = parse_agp_from_projects(repo_root)
    actions = scan_github_actions(repo_root)

    results = []

    # 1. Gradle
    latest_gradle = get_latest_gradle()
    if docker_deps.get("gradle") and latest_gradle:
        results.append({
            "category": "Core / Build Engine",
            "name": "Gradle Engine",
            "current": docker_deps["gradle"],
            "latest": latest_gradle,
            "needs_update": docker_deps["gradle"] != latest_gradle,
            "file": "Dockerfile",
        })

    # 2. AGP (Stable)
    latest_agp = get_latest_agp()
    if agp_current and latest_agp:
        results.append({
            "category": "Android Framework",
            "name": "Android Gradle Plugin (AGP)",
            "current": agp_current,
            "latest": latest_agp,
            "needs_update": agp_current != latest_agp,
            "file": "test_projects/SampleProject/build.gradle",
        })

    # 3. Bundletool
    latest_bundletool = get_latest_github_release("google/bundletool", token=token)
    if docker_deps.get("bundletool") and latest_bundletool:
        results.append({
            "category": "Android Tooling",
            "name": "Google Bundletool",
            "current": docker_deps["bundletool"],
            "latest": latest_bundletool,
            "needs_update": docker_deps["bundletool"] != latest_bundletool,
            "file": "Dockerfile",
        })

    # 4. Fastlane
    latest_fastlane = get_latest_rubygem("fastlane")
    if docker_deps.get("fastlane") and latest_fastlane:
        results.append({
            "category": "Deployment / CI",
            "name": "Fastlane",
            "current": docker_deps["fastlane"],
            "latest": latest_fastlane,
            "needs_update": docker_deps["fastlane"] != latest_fastlane,
            "file": "Dockerfile",
        })

    # 5. Bundler
    latest_bundler = get_latest_rubygem("bundler")
    if docker_deps.get("bundler") and latest_bundler:
        results.append({
            "category": "Ruby Toolchain",
            "name": "Ruby Bundler",
            "current": docker_deps["bundler"],
            "latest": latest_bundler,
            "needs_update": docker_deps["bundler"] != latest_bundler,
            "file": "Dockerfile",
        })

    # 6. Python pip
    latest_pip = get_latest_pypi("pip")
    if docker_deps.get("pip") and latest_pip:
        results.append({
            "category": "Python Toolchain",
            "name": "pip",
            "current": docker_deps["pip"],
            "latest": latest_pip,
            "needs_update": docker_deps["pip"] != latest_pip,
            "file": "Dockerfile",
        })

    # 7. Python setuptools
    latest_setuptools = get_latest_pypi("setuptools")
    if docker_deps.get("setuptools") and latest_setuptools:
        results.append({
            "category": "Python Toolchain",
            "name": "setuptools",
            "current": docker_deps["setuptools"],
            "latest": latest_setuptools,
            "needs_update": docker_deps["setuptools"] != latest_setuptools,
            "file": "Dockerfile",
        })

    # 8. Python wheel
    latest_wheel = get_latest_pypi("wheel")
    if docker_deps.get("wheel") and latest_wheel:
        results.append({
            "category": "Python Toolchain",
            "name": "wheel",
            "current": docker_deps["wheel"],
            "latest": latest_wheel,
            "needs_update": docker_deps["wheel"] != latest_wheel,
            "file": "Dockerfile",
        })

    # 9. Git LFS
    latest_lfs = get_latest_github_release("git-lfs/git-lfs", token=token)
    if docker_deps.get("git-lfs") and latest_lfs:
        results.append({
            "category": "VCS Utility",
            "name": "Git LFS",
            "current": docker_deps["git-lfs"],
            "latest": latest_lfs,
            "needs_update": docker_deps["git-lfs"] != latest_lfs,
            "file": "Dockerfile",
        })

    # 10. GitHub Actions
    print(f"📦 Found {len(actions)} external GitHub Actions across workflows.")
    for action_repo, current_version in sorted(actions.items()):
        latest_tag = get_latest_github_release(action_repo, token=token)
        if latest_tag:
            clean_curr = current_version.lstrip("v")
            clean_latest = latest_tag.lstrip("v")
            curr_major = clean_curr.split(".")[0]
            latest_major = clean_latest.split(".")[0]
            
            needs_update = False
            if curr_major != latest_major and latest_major.isdigit() and curr_major.isdigit() and int(latest_major) > int(curr_major):
                needs_update = True
            elif "." in clean_curr and clean_curr != clean_latest:
                needs_update = True

            results.append({
                "category": "GitHub Action",
                "name": action_repo,
                "current": current_version,
                "latest": f"v{clean_latest}",
                "needs_update": needs_update,
                "file": ".github/workflows/",
            })

    # Summary Generation
    updates_needed = [r for r in results if r["needs_update"]]
    any_update = len(updates_needed) > 0

    print("\n" + "=" * 78)
    print(f"📊 WATCHDOG REPORT: {len(results)} items inspected | {len(updates_needed)} updates available")
    print("=" * 78)

    md_lines = [
        "# 🔍 Universal Dependency & GitHub Actions Watchdog Report",
        "",
        "| Category | Component / Action | Current Pinned | Upstream Latest | Update Status |",
        "| :--- | :--- | :--- | :--- | :--- |",
    ]

    for r in results:
        status = "⚠️ **Update Available**" if r["needs_update"] else "✅ Up-to-date"
        md_lines.append(f"| {r['category']} | `{r['name']}` | `{r['current']}` | `{r['latest']}` | {status} |")

    md_lines.append("")
    if any_update:
        md_lines.append(f"⚠️ **{len(updates_needed)} component(s) have newer releases available upstream.**")
    else:
        md_lines.append("✅ **All core dependencies and GitHub Actions are 100% up-to-date.**")

    markdown_report = "\n".join(md_lines)
    print(markdown_report)

    if apply_mode and updates_needed:
        apply_updates_locally(repo_root, updates_needed)

    # Export to files and GitHub outputs if in CI
    summary_path = os.environ.get("GITHUB_STEP_SUMMARY")
    if summary_path:
        with open(summary_path, "a", encoding="utf-8") as f:
            f.write("\n" + markdown_report + "\n")

    output_path = os.environ.get("GITHUB_OUTPUT")
    if output_path:
        with open(output_path, "a", encoding="utf-8") as f:
            f.write(f"any_update={'true' if any_update else 'false'}\n")
            f.write(f"updates_count={len(updates_needed)}\n")

    # Export JSON report
    report_file = repo_root / "build/dependency-report.json"
    report_file.parent.mkdir(parents=True, exist_ok=True)
    report_file.write_text(json.dumps(results, indent=2), encoding="utf-8")
    print(f"\n[OK] JSON report exported to {report_file}")


if __name__ == "__main__":
    main()
