#!/bin/bash
# =============================================================================
# AI-Native Development System - Schema Validation Script
# =============================================================================
#
# Validates JSON artifacts against their schemas without external dependencies.
# Uses jq for JSON parsing (commonly available) with fallback to Python.
#
# Usage:
#   ./scripts/validate.sh <artifact> [schema]
#   ./scripts/validate.sh --all
#   ./scripts/validate.sh --check-tools
#
# Examples:
#   ./scripts/validate.sh ARTIFACTS/system/stage-completion-signal.json
#   ./scripts/validate.sh ARTIFACTS/product-manager/product-requirements-packet.json
#   ./scripts/validate.sh --all
#
# =============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
CONTRACTS_DIR="$ROOT_DIR/L3 - Workflows & Contracts/contracts"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# =============================================================================
# Artifact to Schema Mapping
# =============================================================================

get_schema_for_artifact() {
    local artifact="$1"
    local basename=$(basename "$artifact")

    case "$basename" in
        product-requirements-packet.json)
            echo "$CONTRACTS_DIR/pm-output-schema.json"
            ;;
        architecture-handover-packet.json)
            echo "$CONTRACTS_DIR/architect-output-schema.json"
            ;;
        architecture-assessment.json)
            echo "$CONTRACTS_DIR/architecture-assessment-schema.json"
            ;;
        frontend-implementation-report.json)
            echo "$CONTRACTS_DIR/frontend-output-schema.json"
            ;;
        backend-implementation-report.json)
            echo "$CONTRACTS_DIR/backend-output-schema.json"
            ;;
        ai-implementation-report.json)
            echo "$CONTRACTS_DIR/ai-engineer-output-schema.json"
            ;;
        qa-test-report.json)
            echo "$CONTRACTS_DIR/qa-output-schema.json"
            ;;
        deployment-report.json)
            echo "$CONTRACTS_DIR/devops-output-schema.json"
            ;;
        stage-completion-signal.json)
            echo "$CONTRACTS_DIR/stage-completion-signal-schema.json"
            ;;
        workflow-state.json)
            echo "$CONTRACTS_DIR/workflow-state-schema.json"
            ;;
        safety-review-report.json)
            echo "$CONTRACTS_DIR/safety-output-schema.json"
            ;;
        governance-review-report.json)
            echo "$CONTRACTS_DIR/governance-output-schema.json"
            ;;
        code-health-report.json)
            echo "$CONTRACTS_DIR/code-health-output-schema.json"
            ;;
        orchestrator-log.json)
            echo "$CONTRACTS_DIR/controller-output-schema.json"
            ;;
        project-config.json)
            echo "$CONTRACTS_DIR/project-config-schema.json"
            ;;
        *)
            echo ""
            ;;
    esac
}

# =============================================================================
# Validation Functions
# =============================================================================

# Check if a tool is available
has_tool() {
    command -v "$1" &> /dev/null
}

# Validate JSON syntax
validate_json_syntax() {
    local file="$1"

    if has_tool jq; then
        jq empty "$file" 2>/dev/null
        return $?
    elif has_tool python3; then
        python3 -c "import json; json.load(open('$file'))" 2>/dev/null
        return $?
    elif has_tool python; then
        python -c "import json; json.load(open('$file'))" 2>/dev/null
        return $?
    elif has_tool node; then
        node -e "JSON.parse(require('fs').readFileSync('$file'))" 2>/dev/null
        return $?
    else
        echo "Warning: No JSON parser available (jq, python, or node)"
        return 1
    fi
}

# Get JSON value using available tool
get_json_value() {
    local file="$1"
    local path="$2"

    if has_tool jq; then
        jq -r "$path // empty" "$file" 2>/dev/null
    elif has_tool python3; then
        python3 -c "
import json, sys
try:
    data = json.load(open('$file'))
    path = '$path'.lstrip('.')
    for key in path.split('.'):
        if key:
            data = data.get(key, '')
    print(data if data else '')
except:
    print('')
" 2>/dev/null
    elif has_tool python; then
        python -c "
import json, sys
try:
    data = json.load(open('$file'))
    path = '$path'.lstrip('.')
    for key in path.split('.'):
        if key:
            data = data.get(key, '')
    print(data if data else '')
except:
    print('')
" 2>/dev/null
    fi
}

# Check if JSON has a field
has_json_field() {
    local file="$1"
    local field="$2"

    if has_tool jq; then
        jq -e "has(\"$field\")" "$file" &>/dev/null
        return $?
    elif has_tool python3 || has_tool python; then
        local py_cmd="python3"
        has_tool python3 || py_cmd="python"
        $py_cmd -c "
import json, sys
data = json.load(open('$file'))
sys.exit(0 if '$field' in data else 1)
" 2>/dev/null
        return $?
    fi
    return 1
}

# Check if value is in enum
check_enum() {
    local value="$1"
    shift
    local valid_values=("$@")

    for v in "${valid_values[@]}"; do
        if [ "$value" = "$v" ]; then
            return 0
        fi
    done
    return 1
}

# =============================================================================
# Schema-Specific Validators
# =============================================================================

validate_stage_completion_signal() {
    local file="$1"
    local errors=0

    echo "  Validating stage-completion-signal structure..."

    # Required fields
    local required_fields=("agent" "stage" "status" "timestamp")
    for field in "${required_fields[@]}"; do
        if ! has_json_field "$file" "$field"; then
            echo -e "    ${RED}ERROR: Missing required field: $field${NC}"
            errors=$((errors + 1))
        fi
    done

    # Validate agent enum
    local agent=$(get_json_value "$file" ".agent")
    local valid_agents=("product_manager" "system_architect" "frontend_engineer" "backend_engineer" "ai_engineer" "qa_engineer" "devops_engineer" "safety_agent" "governance_agent" "code_health_agent")
    if [ -n "$agent" ] && ! check_enum "$agent" "${valid_agents[@]}"; then
        echo -e "    ${RED}ERROR: Invalid agent value: $agent${NC}"
        errors=$((errors + 1))
    fi

    # Validate stage enum
    local stage=$(get_json_value "$file" ".stage")
    local valid_stages=("requirements" "architecture" "frontend_implementation" "backend_implementation" "ai_implementation" "qa_testing" "deployment" "safety_review" "governance_review" "code_health_assessment")
    if [ -n "$stage" ] && ! check_enum "$stage" "${valid_stages[@]}"; then
        echo -e "    ${RED}ERROR: Invalid stage value: $stage${NC}"
        errors=$((errors + 1))
    fi

    # Validate status enum
    local status=$(get_json_value "$file" ".status")
    local valid_statuses=("completed" "completed_with_warnings" "failed" "blocked" "requires_human_intervention")
    if [ -n "$status" ] && ! check_enum "$status" "${valid_statuses[@]}"; then
        echo -e "    ${RED}ERROR: Invalid status value: $status${NC}"
        errors=$((errors + 1))
    fi

    # Validate timestamp format (basic check)
    local timestamp=$(get_json_value "$file" ".timestamp")
    if [ -n "$timestamp" ]; then
        if ! [[ "$timestamp" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2} ]]; then
            echo -e "    ${RED}ERROR: Invalid timestamp format (expected ISO 8601): $timestamp${NC}"
            errors=$((errors + 1))
        fi
    fi

    # If status is blocked, must have blocking_issues
    if [ "$status" = "blocked" ]; then
        if ! has_json_field "$file" "blocking_issues"; then
            echo -e "    ${YELLOW}WARNING: Status is 'blocked' but no blocking_issues provided${NC}"
        fi
    fi

    return $errors
}

validate_workflow_state() {
    local file="$1"
    local errors=0

    echo "  Validating workflow-state structure..."

    # Required fields
    local required_fields=("workflow_id" "execution_mode" "current_stage" "stages" "created_at" "updated_at")
    for field in "${required_fields[@]}"; do
        if ! has_json_field "$file" "$field"; then
            echo -e "    ${RED}ERROR: Missing required field: $field${NC}"
            errors=$((errors + 1))
        fi
    done

    # Validate execution_mode
    local mode=$(get_json_value "$file" ".execution_mode")
    if [ -n "$mode" ] && ! check_enum "$mode" "full_system" "fast_feature"; then
        echo -e "    ${RED}ERROR: Invalid execution_mode: $mode${NC}"
        errors=$((errors + 1))
    fi

    return $errors
}

validate_generic_required_fields() {
    local file="$1"
    local schema="$2"
    local errors=0

    echo "  Checking required fields..."

    # Extract required fields from schema if possible
    if has_tool jq && [ -f "$schema" ]; then
        local required=$(jq -r '.required[]? // empty' "$schema" 2>/dev/null)
        if [ -n "$required" ]; then
            while IFS= read -r field; do
                if ! has_json_field "$file" "$field"; then
                    echo -e "    ${RED}ERROR: Missing required field: $field${NC}"
                    errors=$((errors + 1))
                fi
            done <<< "$required"
        fi
    fi

    return $errors
}

# =============================================================================
# Main Validation Function
# =============================================================================

validate_artifact() {
    local artifact="$1"
    local schema="$2"
    local errors=0

    echo ""
    echo "Validating: $artifact"
    echo "----------------------------------------"

    # Check file exists
    if [ ! -f "$artifact" ]; then
        echo -e "${RED}ERROR: File not found: $artifact${NC}"
        return 1
    fi

    # Validate JSON syntax
    echo "  Checking JSON syntax..."
    if ! validate_json_syntax "$artifact"; then
        echo -e "  ${RED}ERROR: Invalid JSON syntax${NC}"
        return 1
    fi
    echo -e "  ${GREEN}JSON syntax: OK${NC}"

    # Auto-detect schema if not provided
    if [ -z "$schema" ]; then
        schema=$(get_schema_for_artifact "$artifact")
        if [ -z "$schema" ]; then
            echo -e "  ${YELLOW}WARNING: No schema mapping for this artifact${NC}"
            echo -e "  ${GREEN}PASSED (syntax only)${NC}"
            return 0
        fi
    fi

    # Check schema exists
    if [ ! -f "$schema" ]; then
        echo -e "  ${YELLOW}WARNING: Schema not found: $schema${NC}"
        echo -e "  ${GREEN}PASSED (syntax only)${NC}"
        return 0
    fi

    echo "  Schema: $(basename "$schema")"

    # Run specific validator based on artifact type
    local basename=$(basename "$artifact")
    case "$basename" in
        stage-completion-signal.json)
            validate_stage_completion_signal "$artifact"
            errors=$?
            ;;
        workflow-state.json)
            validate_workflow_state "$artifact"
            errors=$?
            ;;
        *)
            validate_generic_required_fields "$artifact" "$schema"
            errors=$?
            ;;
    esac

    if [ $errors -eq 0 ]; then
        echo -e "  ${GREEN}PASSED${NC}"
        return 0
    else
        echo -e "  ${RED}FAILED with $errors error(s)${NC}"
        return 1
    fi
}

# =============================================================================
# Commands
# =============================================================================

check_tools() {
    echo "Checking available tools..."
    echo ""

    local tools=("jq" "python3" "python" "node")
    local found=0

    for tool in "${tools[@]}"; do
        if has_tool "$tool"; then
            echo -e "  ${GREEN}✓${NC} $tool: $(which $tool)"
            found=$((found + 1))
        else
            echo -e "  ${RED}✗${NC} $tool: not found"
        fi
    done

    echo ""
    if [ $found -eq 0 ]; then
        echo -e "${RED}ERROR: No JSON processing tools found!${NC}"
        echo "Please install one of: jq, python3, python, or node"
        return 1
    else
        echo -e "${GREEN}Validation tools available.${NC}"
        return 0
    fi
}

validate_all() {
    echo "Validating all artifacts..."
    echo "========================================"

    local total=0
    local passed=0
    local failed=0

    # Find all JSON files in ARTIFACTS directory
    if [ -d "$ROOT_DIR/ARTIFACTS" ]; then
        while IFS= read -r -d '' artifact; do
            total=$((total + 1))
            if validate_artifact "$artifact"; then
                passed=$((passed + 1))
            else
                failed=$((failed + 1))
            fi
        done < <(find "$ROOT_DIR/ARTIFACTS" -name "*.json" -type f -print0 2>/dev/null)
    fi

    echo ""
    echo "========================================"
    echo "Summary: $passed/$total passed"

    if [ $failed -gt 0 ]; then
        echo -e "${RED}$failed artifact(s) failed validation${NC}"
        return 1
    else
        echo -e "${GREEN}All artifacts passed validation${NC}"
        return 0
    fi
}

show_usage() {
    echo "AI-Native Development System - Schema Validation"
    echo ""
    echo "Usage:"
    echo "  $0 <artifact.json> [schema.json]   Validate specific artifact"
    echo "  $0 --all                           Validate all artifacts in ARTIFACTS/"
    echo "  $0 --check-tools                   Check available validation tools"
    echo "  $0 --help                          Show this help"
    echo ""
    echo "Examples:"
    echo "  $0 ARTIFACTS/system/stage-completion-signal.json"
    echo "  $0 ARTIFACTS/product-manager/product-requirements-packet.json"
    echo "  $0 --all"
    echo ""
    echo "Supported artifacts:"
    echo "  - product-requirements-packet.json"
    echo "  - architecture-handover-packet.json"
    echo "  - architecture-assessment.json"
    echo "  - frontend-implementation-report.json"
    echo "  - backend-implementation-report.json"
    echo "  - ai-implementation-report.json"
    echo "  - qa-test-report.json"
    echo "  - deployment-report.json"
    echo "  - stage-completion-signal.json"
    echo "  - workflow-state.json"
    echo "  - safety-review-report.json"
    echo "  - governance-review-report.json"
    echo "  - code-health-report.json"
    echo "  - project-config.json"
}

# =============================================================================
# Entry Point
# =============================================================================

main() {
    case "${1:-}" in
        --help|-h)
            show_usage
            exit 0
            ;;
        --check-tools)
            check_tools
            exit $?
            ;;
        --all)
            validate_all
            exit $?
            ;;
        "")
            show_usage
            exit 1
            ;;
        *)
            validate_artifact "$1" "${2:-}"
            exit $?
            ;;
    esac
}

main "$@"
