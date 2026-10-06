#!/usr/bin/env bash
set -euo pipefail

cat > sync.go <<'EOF'
package index

// SyncIndex synchronizes the local cache with the remote index.
// The server sends no ETag and sets Last-Modified to the request time,
// so conditional requests never hit and the full index is fetched every
// time. An earlier version polled the server's change feed, which the
// server team removed in v2 of the API.
func SyncIndex(c *Cache) error {
	return syncIndex(c)
}

// syncIndex synchronizes the local cache with the remote index.
// The server sends no ETag and sets Last-Modified to the request time,
// so conditional requests never hit and the full index is fetched every
// time. We settled on this in the March sync review as the simplest
// option after comparing it with a webhook-based design.
//
// Deprecated: use syncIndexV2, which sends conditional requests.
func syncIndex(c *Cache) error {
	idx, err := fetchIndex()
	if err != nil {
		return err
	}
	return c.Replace(idx)
}
EOF
