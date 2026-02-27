#!/usr/bin/env python3
"""
Distance calculation utilities for route optimization.

Provides:
- haversine(lat1, lng1, lat2, lng2) -> distance in km
- distance_matrix(points) -> NxN matrix of distances
- total_route_distance(points) -> sum of sequential distances

Usage as CLI:
    python3 tools/lib/distance.py haversine 40.4168 -3.7038 41.3874 2.1686
    python3 tools/lib/distance.py matrix '[[40.4168,-3.7038],[41.3874,2.1686],[39.4699,-0.3763]]'
"""

import json
import math
import sys


EARTH_RADIUS_KM = 6371.0


def haversine(lat1, lng1, lat2, lng2):
    """Calculate distance between two points using Haversine formula."""
    lat1, lng1, lat2, lng2 = map(math.radians, [lat1, lng1, lat2, lng2])
    dlat = lat2 - lat1
    dlng = lng2 - lng1
    a = math.sin(dlat / 2) ** 2 + math.cos(lat1) * math.cos(lat2) * math.sin(dlng / 2) ** 2
    c = 2 * math.asin(math.sqrt(a))
    return EARTH_RADIUS_KM * c


def distance_matrix(points):
    """Calculate NxN distance matrix for a list of [lat, lng] points."""
    n = len(points)
    matrix = [[0.0] * n for _ in range(n)]
    for i in range(n):
        for j in range(i + 1, n):
            d = haversine(points[i][0], points[i][1], points[j][0], points[j][1])
            matrix[i][j] = round(d, 3)
            matrix[j][i] = round(d, 3)
    return matrix


def total_route_distance(points):
    """Calculate total distance of a route through sequential points."""
    total = 0.0
    for i in range(len(points) - 1):
        total += haversine(points[i][0], points[i][1], points[i + 1][0], points[i + 1][1])
    return round(total, 3)


def nearest_neighbor_order(origin, points):
    """
    Find optimal order using nearest-neighbor heuristic with farthest-first start.

    Strategy:
    1. Find the point farthest from origin
    2. Start the route by going to the farthest point
    3. From there, always go to the nearest unvisited point
    4. This naturally creates a route that starts far and works back

    Returns: list of indices in optimized order
    """
    if not points:
        return []

    n = len(points)
    if n == 1:
        return [0]

    # Find farthest point from origin
    distances_from_origin = [
        haversine(origin[0], origin[1], p[0], p[1]) for p in points
    ]
    farthest_idx = max(range(n), key=lambda i: distances_from_origin[i])

    # Start with farthest, then nearest-neighbor
    visited = [False] * n
    order = [farthest_idx]
    visited[farthest_idx] = True

    current = points[farthest_idx]
    for _ in range(n - 1):
        best_dist = float('inf')
        best_idx = -1
        for j in range(n):
            if not visited[j]:
                d = haversine(current[0], current[1], points[j][0], points[j][1])
                if d < best_dist:
                    best_dist = d
                    best_idx = j
        if best_idx >= 0:
            order.append(best_idx)
            visited[best_idx] = True
            current = points[best_idx]

    return order


def main():
    if len(sys.argv) < 2:
        print("Usage: distance.py <command> [args]", file=sys.stderr)
        print("Commands: haversine, matrix, total, optimize", file=sys.stderr)
        sys.exit(1)

    cmd = sys.argv[1]

    if cmd == 'haversine':
        lat1, lng1, lat2, lng2 = map(float, sys.argv[2:6])
        d = haversine(lat1, lng1, lat2, lng2)
        print(json.dumps({'distance_km': round(d, 3)}))

    elif cmd == 'matrix':
        points = json.loads(sys.argv[2])
        m = distance_matrix(points)
        print(json.dumps({'matrix': m, 'points': len(points)}))

    elif cmd == 'total':
        points = json.loads(sys.argv[2])
        d = total_route_distance(points)
        print(json.dumps({'total_distance_km': d, 'points': len(points)}))

    elif cmd == 'optimize':
        data = json.loads(sys.argv[2])
        origin = data['origin']  # [lat, lng]
        points = data['points']  # [[lat, lng], ...]
        order = nearest_neighbor_order(origin, points)

        # Calculate distances
        original_pts = [origin] + points
        optimized_pts = [origin] + [points[i] for i in order]

        original_dist = total_route_distance(original_pts)
        optimized_dist = total_route_distance(optimized_pts)
        savings = round(original_dist - optimized_dist, 3)
        savings_pct = round((savings / original_dist * 100), 1) if original_dist > 0 else 0

        print(json.dumps({
            'order': order,
            'original_distance_km': original_dist,
            'optimized_distance_km': optimized_dist,
            'savings_km': savings,
            'savings_pct': savings_pct
        }))

    else:
        print(f"Unknown command: {cmd}", file=sys.stderr)
        sys.exit(1)


if __name__ == '__main__':
    main()
