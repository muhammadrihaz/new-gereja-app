#!/bin/bash

# Gereja App 2 - Run Script for Different Environments

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
ENVIRONMENT="local"
PLATFORM="web"
HELP=false

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --env)
      ENVIRONMENT="$2"
      shift 2
      ;;
    --platform)
      PLATFORM="$2"
      shift 2
      ;;
    --help)
      HELP=true
      shift
      ;;
    *)
      echo "Unknown option: $1"
      HELP=true
      shift
      ;;
  esac
done

if [ "$HELP" = true ]; then
  cat << EOF
${BLUE}Gereja App 2 - Development Runner${NC}

${YELLOW}Usage:${NC}
  ./run.sh [OPTIONS]

${YELLOW}Options:${NC}
  --env <environment>    Environment: local (default) or production
  --platform <platform>  Platform: web, android, ios, macos, windows
  --help                 Show this help message

${YELLOW}Examples:${NC}
  Launch web app in local environment (auto-fill enabled):
    ./run.sh --env local --platform web

  Launch Android app in production (no auto-fill):
    ./run.sh --env production --platform android

  Launch iOS app for testing:
    ./run.sh --platform ios

${YELLOW}Environment Details:${NC}
  ${GREEN}local${NC}
    - Debug mode enabled
    - Credentials auto-filled in Login tab
    - Quick "Admin" & "Jemaat" buttons visible
    - Google Sign In: "Coming Soon" placeholder
    - Use for: Development, testing, debugging

  ${GREEN}production${NC}
    - Release mode
    - NO auto-fill
    - No quick credential buttons
    - Google Sign In: Ready to use (when implemented)
    - Use for: Pre-release testing, UAT, production deployments

${YELLOW}Default Credentials (Local Only):${NC}
  Admin:   admin@example.com / password123
  Jemaat:  jemaat@example.com / password123

${YELLOW}Note:${NC}
  Credentials are ONLY visible in local/debug mode.
  Production builds cannot access these credentials.

EOF
  exit 0
fi

echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║     Gereja App 2 - Environment Runner  ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"
echo ""
echo -e "${YELLOW}Configuration:${NC}"
echo -e "  Environment: ${GREEN}${ENVIRONMENT}${NC}"
echo -e "  Platform:    ${GREEN}${PLATFORM}${NC}"
echo ""

# Validate environment
if [ "$ENVIRONMENT" != "local" ] && [ "$ENVIRONMENT" != "production" ]; then
  echo -e "${RED}❌ Invalid environment: $ENVIRONMENT${NC}"
  echo -e "Valid options: local, production"
  exit 1
fi

# Validate platform
valid_platforms=("web" "android" "ios" "macos" "windows")
if [[ ! " ${valid_platforms[@]} " =~ " ${PLATFORM} " ]]; then
  echo -e "${RED}❌ Invalid platform: $PLATFORM${NC}"
  echo -e "Valid options: ${valid_platforms[*]}"
  exit 1
fi

# Build command
case $ENVIRONMENT in
  local)
    if [ "$PLATFORM" = "web" ]; then
      echo -e "${YELLOW}Starting app in ${GREEN}local${NC}${YELLOW} mode on ${GREEN}web${NC}${YELLOW}...${NC}"
      echo -e "${YELLOW}Features:${NC}"
      echo -e "  • Credentials: ${GREEN}admin@example.com${NC} / ${GREEN}password123${NC}"
      echo -e "  • Quick buttons: Admin, Jemaat (for easy credential switching)"
      echo -e "  • Auto-fill: Enabled${NC}"
      echo ""
      flutter run -d chrome
    else
      echo -e "${YELLOW}Starting app in ${GREEN}local${NC}${YELLOW} mode on ${GREEN}${PLATFORM}${NC}${YELLOW}...${NC}"
      echo -e "${YELLOW}Features:${NC}"
      echo -e "  • Auto-fill: Enabled${NC}"
      echo -e "  • Quick buttons: Visible${NC}"
      echo ""
      flutter run -d "$PLATFORM"
    fi
    ;;
  production)
    if [ "$PLATFORM" = "web" ]; then
      echo -e "${YELLOW}Building production web app...${NC}"
      echo -e "${YELLOW}Features:${NC}"
      echo -e "  • Auto-fill: ${RED}Disabled${NC}"
      echo -e "  • Credentials: Not visible${NC}"
      echo -e "  • Output: ${GREEN}build/web${NC}"
      echo ""
      flutter build web --release
    else
      echo -e "${YELLOW}Building production ${PLATFORM} app...${NC}"
      echo -e "${YELLOW}Features:${NC}"
      echo -e "  • Auto-fill: ${RED}Disabled${NC}"
      echo -e "  • Output: Check platform-specific directories${NC}"
      echo ""
      flutter build "$PLATFORM" --release
    fi
    ;;
esac

if [ $? -eq 0 ]; then
  echo ""
  echo -e "${GREEN}✅ Done!${NC}"
else
  echo ""
  echo -e "${RED}❌ Build/Run failed!${NC}"
  exit 1
fi
