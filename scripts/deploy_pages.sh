#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Missing required command: $1" >&2
    exit 1
  fi
}

require_cmd git
require_cmd flutter

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "This script must be run inside a git repository." >&2
  exit 1
fi

REMOTE_URL="$(git remote get-url origin)"
REPO_NAME="$(basename -s .git "$REMOTE_URL")"
BASE_HREF="/${REPO_NAME}/"
PUBLISH_BRANCH="${PUBLISH_BRANCH:-gh-pages}"

echo "Building Flutter web app with base href: ${BASE_HREF}"
flutter pub get
flutter build web --release --base-href "${BASE_HREF}"

# GitHub Pages serves 404.html on unknown paths; using the app entrypoint helps
# preserve SPA deep links when users refresh a route.
cp build/web/index.html build/web/404.html
touch build/web/.nojekyll

WORKTREE_DIR="$(mktemp -d "${TMPDIR:-/tmp}/gh-pages-worktree.XXXXXX")"
cleanup() {
  git worktree remove --force "$WORKTREE_DIR" >/dev/null 2>&1 || true
  rm -rf "$WORKTREE_DIR" >/dev/null 2>&1 || true
}
trap cleanup EXIT

if git show-ref --verify --quiet "refs/heads/${PUBLISH_BRANCH}"; then
  git worktree add "$WORKTREE_DIR" "$PUBLISH_BRANCH" >/dev/null
else
  echo "Local branch '${PUBLISH_BRANCH}' not found. Creating orphan branch locally."
  git worktree add --detach "$WORKTREE_DIR" >/dev/null
  (
    cd "$WORKTREE_DIR"
    git switch --orphan "$PUBLISH_BRANCH" >/dev/null
    git rm -rf . >/dev/null 2>&1 || true
    printf '%s\n' 'GitHub Pages deployment branch for built web assets.' > README.md
    touch .nojekyll
    git add README.md .nojekyll
    git commit -m "Initialize ${PUBLISH_BRANCH} branch" >/dev/null
  )
  git worktree remove --force "$WORKTREE_DIR" >/dev/null
  mkdir -p "$WORKTREE_DIR"
  git worktree add "$WORKTREE_DIR" "$PUBLISH_BRANCH" >/dev/null
fi

echo "Publishing build/web to ${PUBLISH_BRANCH}"
find "$WORKTREE_DIR" -mindepth 1 -maxdepth 1 \
  ! -name ".git" \
  -exec rm -rf {} +
cp -R build/web/. "$WORKTREE_DIR"/

(
  cd "$WORKTREE_DIR"
  git add -A
  if git diff --cached --quiet; then
    echo "No changes to deploy."
  else
    git commit -m "Deploy Flutter web to GitHub Pages" >/dev/null
    git push origin "$PUBLISH_BRANCH"
    echo "Deployed to branch '${PUBLISH_BRANCH}'."
  fi
)

echo "GitHub Pages URL should be: https://$(git remote get-url origin | sed -E 's#.*github.com[:/]([^/]+)/([^/.]+)(\\.git)?#\\1.github.io/\\2#')/"
