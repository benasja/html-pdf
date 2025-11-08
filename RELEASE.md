# Release Guide

This guide explains how to create and publish releases for the HTML-to-PDF Converter.

## Automated Releases (Recommended)

### Using GitHub Actions

1. **Update the version** in `VERSION` file (e.g., `1.0.0`)

2. **Create a git tag**:
   ```bash
   git tag v1.0.0
   git push origin v1.0.0
   ```

3. **GitHub Actions will automatically**:
   - Build the app on macOS
   - Package it into `.zip` and `.dmg` files
   - Create a GitHub release with the packages attached

### Manual Workflow Dispatch

1. Go to **Actions** → **Build and Release** → **Run workflow**
2. Enter the version tag (e.g., `v1.0.0`)
3. Click **Run workflow**

## Manual Releases

If you prefer to build and package manually:

1. **Build the app**:
   ```bash
   chmod +x build_app.sh
   ./build_app.sh
   ```

2. **Package for release**:
   ```bash
   chmod +x build_release.sh
   ./build_release.sh
   ```

3. **Create a GitHub release**:
   - Go to your repository's **Releases** page
   - Click **Draft a new release**
   - Enter the tag (e.g., `v1.0.0`)
   - Upload the `.zip` and `.dmg` files from the `dist/` directory
   - Add release notes
   - Publish the release

## Version Management

- Update the `VERSION` file with the new version number (e.g., `1.0.0`)
- The build scripts will use this version for naming release packages
- Git tags should follow the format `v1.0.0` (with the `v` prefix)

## Release Package Contents

- **ZIP file**: Contains the `.app` bundle - users can extract and drag to Applications
- **DMG file**: macOS disk image with drag-to-install interface (requires `create-dmg`)

Both packages are created automatically by the GitHub Actions workflow.

