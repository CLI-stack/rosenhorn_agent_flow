#!/usr/bin/env python3
"""
validate_verilog_netlist.py — General-purpose Verilog gate-level netlist validator.

Catches Verilog syntax errors that cause FM-599 (ABORT_NETLIST) BEFORE FM submission.
Runs in seconds vs 1-2 hours for FM to discover the same errors.

Usage:
    python3 validate_verilog_netlist.py <netlist.v.gz> [<netlist2.v.gz> ...]
    python3 validate_verilog_netlist.py --stages Synthesize PrePlace Route --ref-dir <REF_DIR>

Exit code: 0 = PASS, 1 = FAIL (with error details printed to stdout)
"""

import sys
import re
import gzip
import argparse
from collections import defaultdict


def read_netlist(path):
    if path.endswith('.gz'):
        with gzip.open(path, 'rt', errors='replace') as f:
            return f.readlines()
    else:
        with open(path, 'rt', errors='replace') as f:
            return f.readlines()


def validate_netlist(lines, filename="<netlist>"):
    errors = []
    warnings = []

    # Split into module blocks
    modules = extract_modules(lines)

    for mod_name, mod_lines, start_lineno in modules:
        # Check 1: Duplicate explicit wire declarations
        errs = check_duplicate_wires(mod_lines, mod_name, start_lineno)
        errors.extend(errs)

        # Check 2: Explicit wire conflicts with implicit port-connection wire
        errs = check_implicit_wire_conflict(mod_lines, mod_name, start_lineno)
        errors.extend(errs)

        # Check 3: Direction declarations (input/output) inside cell instance blocks
        errs = check_declarations_inside_instances(mod_lines, mod_name, start_lineno)
        errors.extend(errs)

        # Check 4: Duplicate port connections in cell instance blocks
        errs = check_duplicate_port_connections(mod_lines, mod_name, start_lineno)
        errors.extend(errs)

        # Check 5: Port values with multiple comma-separated nets (corrupted port connection)
        errs = check_corrupted_port_values(mod_lines, mod_name, start_lineno)
        errors.extend(errs)

        # Check 6: Module port list balance
        errs = check_port_list_balance(mod_lines, mod_name, start_lineno)
        errors.extend(errs)

        # Check 7: Cell instances with unbalanced parentheses
        errs = check_instance_balance(mod_lines, mod_name, start_lineno)
        errors.extend(errs)

    return errors, warnings


def extract_modules(lines):
    """Extract (module_name, module_lines, start_lineno) tuples."""
    modules = []
    current = None
    current_lines = []
    start = 0

    for i, line in enumerate(lines):
        m = re.match(r'^module\s+(\S+)\s*\(', line)
        if m:
            current = m.group(1)
            current_lines = [line]
            start = i + 1
        elif re.match(r'^endmodule\b', line.strip()):
            if current:
                modules.append((current, current_lines, start))
            current = None
            current_lines = []
        elif current:
            current_lines.append(line)

    return modules


def check_duplicate_wires(mod_lines, mod_name, start_lineno):
    """Check F1: duplicate explicit wire X; in same module body."""
    errors = []
    seen = defaultdict(list)
    for i, line in enumerate(mod_lines):
        m = re.match(r'^\s*wire\s+(?:\[.*?\]\s+)?(\w+)\s*;', line)
        if m:
            seen[m.group(1)].append(start_lineno + i)
    for wire, linenos in seen.items():
        if len(linenos) > 1:
            errors.append({
                'check': 'F1_dup_wire',
                'module': mod_name,
                'msg': f"Duplicate 'wire {wire};' declarations at lines {linenos} — FM SVR-9 → FM-599",
                'line': linenos[0]
            })
    return errors


def check_implicit_wire_conflict(mod_lines, mod_name, start_lineno):
    """Check F2: explicit wire X; + .anypin(X) port connection creates implicit wire = FM-599."""
    errors = []
    text = ''.join(mod_lines)
    wire_decls = set(re.findall(r'^\s*wire\s+(?:\[.*?\]\s+)?(\w+)\s*;', text, re.MULTILINE))
    port_conn_nets = set(re.findall(r'\.\s*\w+\s*\(\s*(\w+)\s*\)', text))
    conflicts = wire_decls & port_conn_nets
    for net in conflicts:
        # Find line number of the wire declaration
        for i, line in enumerate(mod_lines):
            if re.match(rf'^\s*wire\s+(?:\[.*?\]\s+)?{re.escape(net)}\s*;', line):
                errors.append({
                    'check': 'F2_implicit_wire',
                    'module': mod_name,
                    'msg': f"'wire {net};' conflicts with implicit wire from port connection .pin({net}) — FM SVR-9 → FM-599",
                    'line': start_lineno + i
                })
                break
    return errors


def check_declarations_inside_instances(mod_lines, mod_name, start_lineno):
    """Check F3: input/output/wire declarations appearing INSIDE a cell instance block."""
    errors = []
    in_instance = False
    instance_depth = 0
    instance_start = 0
    instance_name = ''

    for i, line in enumerate(mod_lines):
        # Detect cell instance start: CellType InstName (
        if not in_instance:
            m = re.match(r'^\s*([A-Za-z]\w*)\s+(\w+)\s*\(', line)
            if m and m.group(1) not in ('module', 'input', 'output', 'wire', 'reg',
                                          'inout', 'integer', 'parameter', 'localparam'):
                in_instance = True
                instance_depth = line.count('(') - line.count(')')
                instance_start = i
                instance_name = m.group(2)
                if instance_depth <= 0:
                    in_instance = False
                continue
        else:
            # Inside an instance block — check for direction declarations
            if re.match(r'^\s*(input|output|wire|inout)\s+', line):
                errors.append({
                    'check': 'F3_decl_inside_instance',
                    'module': mod_name,
                    'msg': f"Direction declaration found inside cell instance '{instance_name}' block (started line {start_lineno + instance_start}): '{line.strip()[:60]}' — FM-599",
                    'line': start_lineno + i
                })

            instance_depth += line.count('(') - line.count(')')
            if instance_depth <= 0:
                in_instance = False

    return errors


def check_duplicate_port_connections(mod_lines, mod_name, start_lineno):
    """Check F4: .pin(net) appears twice in same instance block."""
    errors = []
    in_instance = False
    instance_depth = 0
    instance_pins = defaultdict(list)
    instance_name = ''
    instance_start = 0

    for i, line in enumerate(mod_lines):
        if not in_instance:
            m = re.match(r'^\s*([A-Za-z]\w*)\s+(\w+)\s*\(', line)
            if m and m.group(1) not in ('module', 'input', 'output', 'wire', 'reg',
                                          'inout', 'integer', 'parameter', 'localparam'):
                in_instance = True
                instance_depth = line.count('(') - line.count(')')
                instance_name = m.group(2)
                instance_start = i
                instance_pins = defaultdict(list)
                pins = re.findall(r'\.\s*(\w+)\s*\(', line)
                for pin in pins:
                    instance_pins[pin].append(start_lineno + i)
                if instance_depth <= 0:
                    in_instance = False
                continue
        else:
            pins = re.findall(r'\.\s*(\w+)\s*\(', line)
            for pin in pins:
                instance_pins[pin].append(start_lineno + i)

            instance_depth += line.count('(') - line.count(')')
            if instance_depth <= 0:
                in_instance = False
                for pin, linenos in instance_pins.items():
                    if len(linenos) > 1:
                        errors.append({
                            'check': 'F4_dup_port_conn',
                            'module': mod_name,
                            'msg': f"Duplicate port connection '.{pin}(...)' in instance '{instance_name}' at lines {linenos} — FM-599",
                            'line': linenos[0]
                        })

    return errors


def check_corrupted_port_values(mod_lines, mod_name, start_lineno):
    """Check F5: .pin( net1, net2, net3 ) — multiple nets in single port connection (corrupted insertion)."""
    errors = []
    for i, line in enumerate(mod_lines):
        # Find .pinname( content ) patterns where content has commas (multiple nets)
        for m in re.finditer(r'\.\w+\s*\(\s*([^)]+)\)', line):
            value = m.group(1)
            # Ignore bus slices like {a, b, c} — they're valid concatenations
            value_no_braces = re.sub(r'\{[^}]*\}', '', value)
            if ',' in value_no_braces and not re.match(r'^\s*\d', value_no_braces):
                # Has comma outside of bus concat — likely corrupted
                errors.append({
                    'check': 'F5_corrupted_port_value',
                    'module': mod_name,
                    'msg': f"Port connection has multiple comma-separated nets (corrupted): '{m.group(0)[:60]}' — FM-599",
                    'line': start_lineno + i
                })
    return errors


def check_port_list_balance(mod_lines, mod_name, start_lineno):
    """Check port list parentheses are balanced."""
    errors = []
    if not mod_lines:
        return errors

    # Module first line has the opening '('
    depth = 0
    port_list_closed = False
    for i, line in enumerate(mod_lines):
        for ch in line:
            if ch == '(':
                depth += 1
            elif ch == ')':
                depth -= 1
                if depth == 0 and not port_list_closed:
                    port_list_closed = True
                elif depth < 0:
                    errors.append({
                        'check': 'port_list_unbalanced',
                        'module': mod_name,
                        'msg': f"Unbalanced parentheses in module (depth went negative at line {start_lineno + i}) — FM-599",
                        'line': start_lineno + i
                    })
                    return errors
        if port_list_closed:
            break

    if not port_list_closed:
        errors.append({
            'check': 'port_list_unclosed',
            'module': mod_name,
            'msg': f"Module port list never closed (depth never returned to 0) — FM-599",
            'line': start_lineno
        })

    return errors


def check_instance_balance(mod_lines, mod_name, start_lineno):
    """Check that cell instance parentheses are balanced (no runaway instance blocks)."""
    errors = []
    in_instance = False
    instance_depth = 0
    instance_name = ''
    instance_start = 0

    for i, line in enumerate(mod_lines):
        if not in_instance:
            m = re.match(r'^\s*([A-Za-z]\w*)\s+(\w+)\s*\(', line)
            if m and m.group(1) not in ('module', 'input', 'output', 'wire', 'reg',
                                          'inout', 'integer', 'parameter', 'localparam'):
                in_instance = True
                instance_depth = line.count('(') - line.count(')')
                instance_name = m.group(2)
                instance_start = i
                if instance_depth <= 0:
                    in_instance = False
        else:
            instance_depth += line.count('(') - line.count(')')
            if instance_depth < 0:
                errors.append({
                    'check': 'instance_unbalanced',
                    'module': mod_name,
                    'msg': f"Cell instance '{instance_name}' has unbalanced parens (depth < 0 at line {start_lineno + i})",
                    'line': start_lineno + i
                })
                in_instance = False
            elif instance_depth == 0:
                in_instance = False

    if in_instance:
        errors.append({
            'check': 'instance_unclosed',
            'module': mod_name,
            'msg': f"Cell instance '{instance_name}' (started line {start_lineno + instance_start}) never closed before endmodule",
            'line': start_lineno + instance_start
        })

    return errors


def main():
    parser = argparse.ArgumentParser(description='Validate Verilog gate-level netlists for FM-599 errors')
    parser.add_argument('netlists', nargs='+', help='Netlist files (.v or .v.gz)')
    parser.add_argument('--quiet', action='store_true', help='Only print failures')
    args = parser.parse_args()

    total_errors = 0
    for netlist_path in args.netlists:
        if not args.quiet:
            print(f"\n=== Validating: {netlist_path} ===")
        try:
            lines = read_netlist(netlist_path)
        except Exception as e:
            print(f"ERROR: Cannot read {netlist_path}: {e}")
            total_errors += 1
            continue

        errors, warnings = validate_netlist(lines, netlist_path)

        if errors:
            for err in errors:
                print(f"  [{err['check']}] Module: {err['module']} | Line: {err['line']}")
                print(f"    {err['msg']}")
            print(f"  FAIL: {len(errors)} error(s) found in {netlist_path}")
            total_errors += len(errors)
        else:
            if not args.quiet:
                print(f"  PASS: No Verilog syntax errors found")

        if warnings:
            for w in warnings:
                print(f"  WARN: {w}")

    print(f"\n=== SUMMARY: {'FAIL' if total_errors > 0 else 'PASS'} — {total_errors} total error(s) ===")
    return 1 if total_errors > 0 else 0


if __name__ == '__main__':
    sys.exit(main())
