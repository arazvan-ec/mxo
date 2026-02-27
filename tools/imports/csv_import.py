#!/usr/bin/env python3
"""
Import shipments from a CSV file for a customer.

Usage:
    python3 tools/imports/csv_import.py --customer_id=<cid> --file=<csv_path> [--service_type=entrega] [--dry_run]

CSV columns (required): reference, recipient_name, address, lat, lng
CSV columns (optional): phone, notes, weight_kg, volume_m3, ean, description,
                        delivery_window_start, delivery_window_end

Output: JSON import run summary
"""

import csv
import json
import os
import subprocess
import sys
import argparse
from datetime import datetime, timezone


def get_project_root():
    return os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..'))


def run_tool(tool_path, *args):
    """Run a bash tool and return its stdout."""
    result = subprocess.run(
        ['bash', tool_path] + list(args),
        capture_output=True, text=True,
        cwd=get_project_root()
    )
    if result.returncode != 0:
        return None, result.stderr.strip()
    try:
        return json.loads(result.stdout), None
    except json.JSONDecodeError:
        return result.stdout.strip(), None


def shipment_exists(project_root, customer_id, reference):
    """Check if a shipment with this reference already exists for the customer."""
    shipments_dir = os.path.join(project_root, 'shipments')
    if not os.path.isdir(shipments_dir):
        return False
    for sid in os.listdir(shipments_dir):
        spath = os.path.join(shipments_dir, sid, 'shipment.json')
        if not os.path.isfile(spath):
            continue
        with open(spath) as f:
            s = json.load(f)
        if s.get('customer_id') == customer_id and s.get('reference') == reference:
            return True
    return False


def validate_row(row, row_num):
    """Validate a CSV row. Returns list of errors."""
    errors = []
    required = ['reference', 'recipient_name', 'address', 'lat', 'lng']
    for field in required:
        if not row.get(field, '').strip():
            errors.append({'row': row_num, 'field': field, 'message': f'{field} is required'})

    for coord in ['lat', 'lng']:
        val = row.get(coord, '').strip()
        if val:
            try:
                f = float(val)
                if coord == 'lat' and not (-90 <= f <= 90):
                    errors.append({'row': row_num, 'field': coord, 'message': f'lat must be between -90 and 90'})
                if coord == 'lng' and not (-180 <= f <= 180):
                    errors.append({'row': row_num, 'field': coord, 'message': f'lng must be between -180 and 180'})
            except ValueError:
                errors.append({'row': row_num, 'field': coord, 'message': f'{coord} must be a number'})

    for num_field in ['weight_kg', 'volume_m3']:
        val = row.get(num_field, '').strip()
        if val:
            try:
                f = float(val)
                if f < 0:
                    errors.append({'row': row_num, 'field': num_field, 'message': f'{num_field} must be >= 0'})
            except ValueError:
                errors.append({'row': row_num, 'field': num_field, 'message': f'{num_field} must be a number'})

    return errors


def main():
    parser = argparse.ArgumentParser(description='Import shipments from CSV')
    parser.add_argument('--customer_id', required=True, help='Customer ID')
    parser.add_argument('--file', required=True, help='Path to CSV file')
    parser.add_argument('--service_type', default='entrega', help='Service type (default: entrega)')
    parser.add_argument('--dry_run', action='store_true', help='Validate only, do not create shipments')
    args = parser.parse_args()

    project_root = get_project_root()
    tools_dir = os.path.join(project_root, 'tools')

    # Read CSV
    csv_path = os.path.abspath(args.file)
    if not os.path.isfile(csv_path):
        print(json.dumps({'error': f'File not found: {csv_path}'}), file=sys.stderr)
        sys.exit(1)

    rows = []
    with open(csv_path, newline='', encoding='utf-8') as f:
        reader = csv.DictReader(f)
        for row in reader:
            rows.append(row)

    # Create import run record
    now = datetime.now(timezone.utc).strftime('%Y-%m-%dT%H:%M:%SZ')
    import_id = None
    if not args.dry_run:
        result, err = run_tool(
            os.path.join(tools_dir, 'imports', 'create.sh'),
            f'customer_id={args.customer_id}',
            f'filename={os.path.basename(csv_path)}'
        )
        if err:
            print(json.dumps({'error': f'Failed to create import run: {err}'}), file=sys.stderr)
            sys.exit(1)
        import_id = result.get('id')

    total_rows = len(rows)
    created_count = 0
    skipped_count = 0
    error_count = 0
    all_errors = []
    shipment_ids = []

    for i, row in enumerate(rows, start=1):
        # Validate
        row_errors = validate_row(row, i)
        if row_errors:
            all_errors.extend(row_errors)
            error_count += 1
            continue

        reference = row['reference'].strip()

        # Check duplicate
        if shipment_exists(project_root, args.customer_id, reference):
            skipped_count += 1
            continue

        if args.dry_run:
            created_count += 1
            continue

        # Create shipment
        create_args = [
            f'reference={reference}',
            f'customer_id={args.customer_id}',
            f'recipient_name={row["recipient_name"].strip()}',
            f'address={row["address"].strip()}',
            f'lat={row["lat"].strip()}',
            f'lng={row["lng"].strip()}',
            f'service_type={args.service_type}',
        ]
        for opt in ['phone', 'notes', 'delivery_window_start', 'delivery_window_end']:
            val = row.get(opt, '').strip()
            if val:
                create_args.append(f'{opt}={val}')

        result, err = run_tool(os.path.join(tools_dir, 'shipments', 'create.sh'), *create_args)
        if err:
            all_errors.append({'row': i, 'field': '', 'message': err})
            error_count += 1
            continue

        sid = result.get('id', '')
        shipment_ids.append(sid)

        # Add package if weight/volume provided
        weight = row.get('weight_kg', '').strip()
        volume = row.get('volume_m3', '').strip()
        if weight and volume:
            pkg_args = [sid, f'weight_kg={weight}', f'volume_m3={volume}']
            ean = row.get('ean', '').strip()
            desc = row.get('description', '').strip()
            if ean:
                pkg_args.append(f'ean={ean}')
            if desc:
                pkg_args.append(f'description={desc}')
            run_tool(os.path.join(tools_dir, 'shipments', 'packages', 'add.sh'), *pkg_args)

        created_count += 1

    # Update import run
    summary = {
        'import_id': import_id,
        'customer_id': args.customer_id,
        'filename': os.path.basename(csv_path),
        'dry_run': args.dry_run,
        'total_rows': total_rows,
        'created_count': created_count,
        'skipped_count': skipped_count,
        'error_count': error_count,
        'errors': all_errors,
        'shipment_ids': shipment_ids
    }

    if not args.dry_run and import_id:
        import_file = os.path.join(project_root, 'imports', import_id, 'import.json')
        if os.path.isfile(import_file):
            with open(import_file) as f:
                imp = json.load(f)
            imp.update({
                'status': 'completed',
                'total_rows': total_rows,
                'created_count': created_count,
                'skipped_count': skipped_count,
                'error_count': error_count,
                'errors': all_errors,
                'shipment_ids': shipment_ids,
                'completed_at': now
            })
            with open(import_file, 'w') as f:
                json.dump(imp, f, indent=2)

        # Copy source CSV
        import shutil
        dest = os.path.join(project_root, 'imports', import_id, 'source.csv')
        shutil.copy2(csv_path, dest)

    print(json.dumps(summary, indent=2))


if __name__ == '__main__':
    main()
