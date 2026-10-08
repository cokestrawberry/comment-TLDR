#!/usr/bin/env bash
set -euo pipefail

cat > profiles.py <<'EOF'
def merge_profiles(primary, secondary):
    # 두 사용자 프로필을 하나로 합치되, 같은 키가 양쪽에 모두 있으면 더 최근에
    # 수정된 쪽의 값을 남깁니다.
    # 수정 시각은 서버가 받은 시각이 아니라 프로필에 기록된 updated_at으로
    # 비교합니다. 기기마다 시계가 어긋나 있어서 서버가 받은 순서가 실제 수정
    # 순서와 다를 수 있기 때문입니다. 이 방식은 2025년 동기화 검토 회의에서
    # 오랜 논의 끝에 정해졌고, 그 뒤로 별다른 문제 없이 쓰이고 있습니다.
    merged = dict(secondary)
    for key, value in primary.items():
        if key not in merged or value.updated_at >= merged[key].updated_at:
            merged[key] = value
    return merged
EOF
