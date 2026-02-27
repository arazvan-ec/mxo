#!/usr/bin/env python3
"""
Validate a CSV file without creating shipments (dry-run wrapper).

Usage:
    python3 tools/imports/csv_validate.py --customer_id=<cid> --file=<csv_path>
"""
import os
import subprocess
import sys

script_dir = os.path.dirname(os.path.abspath(__file__))
import_script = os.path.join(script_dir, 'csv_import.py')

# Forward all args + add --dry_run
args = sys.argv[1:] + ['--dry_run']
result = subprocess.run(['python3', import_script] + args, capture_output=False)
sys.exit(result.returncode)
