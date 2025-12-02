#!/usr/bin/env python3
"""
AI-Native Development System - Schema Validation Script (Python)

Full JSON Schema validation using Python's jsonschema library (if available)
or basic structural validation as fallback.

Usage:
    python scripts/validate.py <artifact> [schema]
    python scripts/validate.py --all
    python scripts/validate.py --check-deps

Examples:
    python scripts/validate.py ARTIFACTS/system/stage-completion-signal.json
    python scripts/validate.py --all
"""

import json
import sys
import os
from pathlib import Path
from datetime import datetime
from typing import Dict, List, Optional, Tuple, Any

# Try to import jsonschema, but don't fail if not available
try:
    import jsonschema
    HAS_JSONSCHEMA = True
except ImportError:
    HAS_JSONSCHEMA = False

# =============================================================================
# Configuration
# =============================================================================

SCRIPT_DIR = Path(__file__).parent
ROOT_DIR = SCRIPT_DIR.parent
CONTRACTS_DIR = ROOT_DIR / "L3 - Workflows & Contracts" / "contracts"
ARTIFACTS_DIR = ROOT_DIR / "ARTIFACTS"

# Artifact to schema mapping
ARTIFACT_SCHEMA_MAP = {
    "product-requirements-packet.json": "pm-output-schema.json",
    "architecture-handover-packet.json": "architect-output-schema.json",
    "architecture-assessment.json": "architecture-assessment-schema.json",
    "frontend-implementation-report.json": "frontend-output-schema.json",
    "backend-implementation-report.json": "backend-output-schema.json",
    "ai-implementation-report.json": "ai-engineer-output-schema.json",
    "qa-test-report.json": "qa-output-schema.json",
    "deployment-report.json": "devops-output-schema.json",
    "stage-completion-signal.json": "stage-completion-signal-schema.json",
    "workflow-state.json": "workflow-state-schema.json",
    "safety-review-report.json": "safety-output-schema.json",
    "governance-review-report.json": "governance-output-schema.json",
    "code-health-report.json": "code-health-output-schema.json",
    "orchestrator-log.json": "controller-output-schema.json",
    "project-config.json": "project-config-schema.json",
}

# Valid enum values for stage-completion-signal
VALID_AGENTS = [
    "product_manager", "system_architect", "frontend_engineer",
    "backend_engineer", "ai_engineer", "qa_engineer", "devops_engineer",
    "safety_agent", "governance_agent", "code_health_agent"
]

VALID_STAGES = [
    "requirements", "architecture", "frontend_implementation",
    "backend_implementation", "ai_implementation", "qa_testing",
    "deployment", "safety_review", "governance_review", "code_health_assessment"
]

VALID_STATUSES = [
    "completed", "completed_with_warnings", "failed",
    "blocked", "requires_human_intervention"
]

# =============================================================================
# Colors
# =============================================================================

class Colors:
    RED = "\033[0;31m"
    GREEN = "\033[0;32m"
    YELLOW = "\033[1;33m"
    NC = "\033[0m"  # No Color

    @classmethod
    def disable(cls):
        cls.RED = cls.GREEN = cls.YELLOW = cls.NC = ""

# Disable colors if not a terminal
if not sys.stdout.isatty():
    Colors.disable()

# =============================================================================
# Validation Functions
# =============================================================================

def load_json(filepath: Path) -> Tuple[Optional[Dict], Optional[str]]:
    """Load and parse JSON file."""
    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            return json.load(f), None
    except json.JSONDecodeError as e:
        return None, f"Invalid JSON syntax: {e}"
    except FileNotFoundError:
        return None, f"File not found: {filepath}"
    except Exception as e:
        return None, f"Error reading file: {e}"


def get_schema_path(artifact_path: Path) -> Optional[Path]:
    """Get schema path for an artifact."""
    artifact_name = artifact_path.name
    schema_name = ARTIFACT_SCHEMA_MAP.get(artifact_name)
    if schema_name:
        return CONTRACTS_DIR / schema_name
    return None


def validate_with_jsonschema(data: Dict, schema: Dict) -> List[str]:
    """Validate using jsonschema library."""
    errors = []
    try:
        jsonschema.validate(instance=data, schema=schema)
    except jsonschema.ValidationError as e:
        errors.append(f"{e.json_path}: {e.message}")
    except jsonschema.SchemaError as e:
        errors.append(f"Schema error: {e.message}")
    return errors


def validate_required_fields(data: Dict, schema: Dict) -> List[str]:
    """Basic validation of required fields."""
    errors = []
    required = schema.get("required", [])
    for field in required:
        if field not in data:
            errors.append(f"Missing required field: {field}")
    return errors


def validate_enum(value: Any, valid_values: List[str], field_name: str) -> Optional[str]:
    """Validate enum value."""
    if value is not None and value not in valid_values:
        return f"Invalid {field_name}: '{value}' (valid: {', '.join(valid_values)})"
    return None


def validate_timestamp(value: str) -> Optional[str]:
    """Validate ISO 8601 timestamp."""
    if not value:
        return "Empty timestamp"
    try:
        # Try parsing ISO 8601 format
        if value.endswith('Z'):
            datetime.fromisoformat(value[:-1])
        else:
            datetime.fromisoformat(value)
        return None
    except ValueError:
        return f"Invalid timestamp format: '{value}' (expected ISO 8601)"


def validate_stage_completion_signal(data: Dict) -> List[str]:
    """Validate stage-completion-signal structure."""
    errors = []

    # Required fields
    required = ["agent", "stage", "status", "timestamp"]
    for field in required:
        if field not in data:
            errors.append(f"Missing required field: {field}")

    # Validate enums
    if err := validate_enum(data.get("agent"), VALID_AGENTS, "agent"):
        errors.append(err)
    if err := validate_enum(data.get("stage"), VALID_STAGES, "stage"):
        errors.append(err)
    if err := validate_enum(data.get("status"), VALID_STATUSES, "status"):
        errors.append(err)

    # Validate timestamp
    if "timestamp" in data:
        if err := validate_timestamp(data["timestamp"]):
            errors.append(err)

    # If blocked, should have blocking_issues
    if data.get("status") == "blocked" and not data.get("blocking_issues"):
        errors.append("Status is 'blocked' but no blocking_issues provided (warning)")

    return errors


def validate_workflow_state(data: Dict) -> List[str]:
    """Validate workflow-state structure."""
    errors = []

    # Required fields
    required = ["workflow_id", "execution_mode", "current_stage", "stages", "created_at", "updated_at"]
    for field in required:
        if field not in data:
            errors.append(f"Missing required field: {field}")

    # Validate execution_mode
    mode = data.get("execution_mode")
    if mode and mode not in ["full_system", "fast_feature"]:
        errors.append(f"Invalid execution_mode: '{mode}'")

    return errors


# =============================================================================
# Main Validation
# =============================================================================

def validate_artifact(artifact_path: Path, schema_path: Optional[Path] = None) -> Tuple[bool, List[str]]:
    """
    Validate an artifact against its schema.

    Returns:
        Tuple of (success, error_messages)
    """
    errors = []

    # Load artifact
    data, err = load_json(artifact_path)
    if err:
        return False, [err]

    print(f"  {Colors.GREEN}JSON syntax: OK{Colors.NC}")

    # Get schema path if not provided
    if schema_path is None:
        schema_path = get_schema_path(artifact_path)

    if schema_path is None:
        print(f"  {Colors.YELLOW}WARNING: No schema mapping for this artifact{Colors.NC}")
        return True, []

    if not schema_path.exists():
        print(f"  {Colors.YELLOW}WARNING: Schema not found: {schema_path}{Colors.NC}")
        return True, []

    print(f"  Schema: {schema_path.name}")

    # Load schema
    schema, err = load_json(schema_path)
    if err:
        return False, [f"Schema error: {err}"]

    # Use jsonschema if available
    if HAS_JSONSCHEMA:
        errors = validate_with_jsonschema(data, schema)
    else:
        # Fallback to basic validation
        errors = validate_required_fields(data, schema)

        # Run specific validators
        artifact_name = artifact_path.name
        if artifact_name == "stage-completion-signal.json":
            errors.extend(validate_stage_completion_signal(data))
        elif artifact_name == "workflow-state.json":
            errors.extend(validate_workflow_state(data))

    return len(errors) == 0, errors


def validate_file(artifact_path: str, schema_path: Optional[str] = None) -> bool:
    """Validate a single file and print results."""
    artifact = Path(artifact_path)

    print()
    print(f"Validating: {artifact}")
    print("-" * 40)

    schema = Path(schema_path) if schema_path else None
    success, errors = validate_artifact(artifact, schema)

    if success:
        print(f"  {Colors.GREEN}PASSED{Colors.NC}")
    else:
        for err in errors:
            print(f"  {Colors.RED}ERROR: {err}{Colors.NC}")
        print(f"  {Colors.RED}FAILED with {len(errors)} error(s){Colors.NC}")

    return success


def validate_all() -> bool:
    """Validate all artifacts in ARTIFACTS directory."""
    print("Validating all artifacts...")
    print("=" * 40)

    if not ARTIFACTS_DIR.exists():
        print(f"{Colors.RED}ERROR: ARTIFACTS directory not found{Colors.NC}")
        return False

    total = 0
    passed = 0
    failed = 0

    for artifact in ARTIFACTS_DIR.rglob("*.json"):
        total += 1
        if validate_file(str(artifact)):
            passed += 1
        else:
            failed += 1

    print()
    print("=" * 40)
    print(f"Summary: {passed}/{total} passed")

    if failed > 0:
        print(f"{Colors.RED}{failed} artifact(s) failed validation{Colors.NC}")
        return False
    else:
        print(f"{Colors.GREEN}All artifacts passed validation{Colors.NC}")
        return True


def check_dependencies():
    """Check available validation dependencies."""
    print("Checking validation dependencies...")
    print()

    print(f"  Python: {sys.version.split()[0]}")

    if HAS_JSONSCHEMA:
        print(f"  {Colors.GREEN}✓{Colors.NC} jsonschema: available (full validation)")
    else:
        print(f"  {Colors.YELLOW}✗{Colors.NC} jsonschema: not installed (basic validation only)")
        print()
        print("  To enable full JSON Schema validation, install jsonschema:")
        print("    pip install jsonschema")

    print()
    print(f"  Contracts directory: {CONTRACTS_DIR}")
    if CONTRACTS_DIR.exists():
        schemas = list(CONTRACTS_DIR.glob("*.json"))
        print(f"  {Colors.GREEN}✓{Colors.NC} Found {len(schemas)} schema files")
    else:
        print(f"  {Colors.RED}✗{Colors.NC} Contracts directory not found")


def show_usage():
    """Show usage information."""
    print(__doc__)
    print("Supported artifacts:")
    for artifact in sorted(ARTIFACT_SCHEMA_MAP.keys()):
        print(f"  - {artifact}")


# =============================================================================
# Entry Point
# =============================================================================

def main():
    if len(sys.argv) < 2:
        show_usage()
        sys.exit(1)

    arg = sys.argv[1]

    if arg in ("--help", "-h"):
        show_usage()
        sys.exit(0)
    elif arg == "--check-deps":
        check_dependencies()
        sys.exit(0)
    elif arg == "--all":
        success = validate_all()
        sys.exit(0 if success else 1)
    else:
        schema = sys.argv[2] if len(sys.argv) > 2 else None
        success = validate_file(arg, schema)
        sys.exit(0 if success else 1)


if __name__ == "__main__":
    main()
