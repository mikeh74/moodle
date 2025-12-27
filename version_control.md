# Moodle Version Control Strategy

## Overview

This document outlines the process for managing a customized Moodle installation forked from the upstream Moodle repository, allowing us to maintain custom modifications while staying synchronized with upstream updates.

## Repository Structure

- **Upstream**: `https://github.com/moodle/moodle` (Official Moodle repository)
- **Origin**: `https://github.com/YOUR-ORG/moodle` (Your forked repository)
- **Production**: Current production server with customizations

## Initial Setup Process

### Phase 1: Capture Current Customizations

1. **On the production server**, ensure you're on the correct branch:

   ```bash
   cd /path/to/production/moodle
   git status
   git branch
   ```

2. **Review and stage all customizations**:

   ```bash
   # Check what files have been modified or added
   git status

   # Review changes
   git diff

   # Add custom files and modifications
   git add .

   # Or selectively add files
   git add path/to/custom/file.php
   ```

3. **Commit customizations with descriptive message**:

   ```bash
   git commit -m "feat: Add custom modifications and local plugins

   - Custom theme modifications
   - Local plugins: [list plugins]
   - Configuration changes
   - Custom integrations

   This commit captures all production customizations as of $(date +%Y-%m-%d)"
   ```

### Phase 2: Fork and Set Up Remote Repository

1. **Fork the Moodle repository** on GitHub:

   - Go to https://github.com/moodle/moodle
   - Click "Fork" button
   - Create fork in your organization/account

2. **Add your fork as a remote** on production server:

   ```bash
   # Check current remotes
   git remote -v

   # Add your fork as 'origin' (or another name if origin exists)
   git remote add origin https://github.com/YOUR-ORG/moodle.git

   # If origin already exists and points to upstream, rename it
   git remote rename origin upstream
   git remote add origin https://github.com/YOUR-ORG/moodle.git
   ```

3. **Verify remote configuration**:
   ```bash
   git remote -v
   # Should show:
   # origin    https://github.com/YOUR-ORG/moodle.git (fetch)
   # origin    https://github.com/YOUR-ORG/moodle.git (push)
   # upstream  https://github.com/moodle/moodle.git (fetch)
   # upstream  https://github.com/moodle/moodle.git (push)
   ```

### Phase 3: Push Customizations to Fork

1. **Determine your current Moodle version branch**:

   ```bash
   # Check current branch
   git branch

   # View Moodle version
   php -r "require('version.php'); echo \$release . PHP_EOL;"
   ```

2. **Create a custom branch for your modifications**:

   ```bash
   # Example: if on MOODLE_404_STABLE
   git checkout -b custom-404-stable

   # Or use a naming convention like:
   git checkout -b lte-moodle-404-stable
   ```

3. **Push to your fork**:

   ```bash
   # Push custom branch to your fork
   git push -u origin custom-404-stable

   # Also push the base Moodle branch if needed
   git push origin MOODLE_404_STABLE
   ```

## Ongoing Development Workflow

### Branch Strategy

- **Upstream branches**: `MOODLE_XXX_STABLE` (e.g., `MOODLE_404_STABLE`)
- **Custom branches**: `custom-XXX-stable` or `lte-moodle-XXX-stable`
- **Feature branches**: `feature/description` or `fix/issue-description`
- **Development branch**: `develop` (for integration testing)

### Workflow for New Features/Fixes

1. **Create feature branch from custom branch**:

   ```bash
   git checkout custom-404-stable
   git pull origin custom-404-stable
   git checkout -b feature/new-integration
   ```

2. **Develop and commit**:

   ```bash
   # Make changes
   git add .
   git commit -m "feat: Add new integration feature"
   ```

3. **Push and create pull request**:

   ```bash
   git push origin feature/new-integration
   # Create PR on GitHub: feature/new-integration -> custom-404-stable
   ```

4. **Merge via pull request** (allows for code review and CI/CD)

### Syncing with Upstream Moodle

Regularly sync your custom branch with upstream Moodle updates:

1. **Fetch upstream changes**:

   ```bash
   git fetch upstream
   git fetch upstream --tags
   ```

2. **Review what's new**:

   ```bash
   # See commits in upstream that you don't have
   git log custom-404-stable..upstream/MOODLE_404_STABLE --oneline
   ```

3. **Merge upstream changes into custom branch**:

   ```bash
   # Checkout your custom branch
   git checkout custom-404-stable

   # Merge upstream changes
   git merge upstream/MOODLE_404_STABLE

   # Resolve any conflicts
   # Test thoroughly!
   ```

4. **Push updated custom branch**:
   ```bash
   git push origin custom-404-stable
   ```

### Handling Merge Conflicts

When conflicts occur during upstream sync:

1. **Identify conflicting files**:

   ```bash
   git status
   ```

2. **Resolve conflicts**:

   - Edit conflicting files
   - Keep your customizations where appropriate
   - Accept upstream changes for core functionality
   - Test thoroughly

3. **Complete merge**:

   ```bash
   git add .
   git commit -m "merge: Sync with upstream MOODLE_404_STABLE

   Resolved conflicts in:
   - path/to/file1.php
   - path/to/file2.php"
   ```

## Version Upgrade Strategy

When upgrading to a new Moodle major version:

1. **Create new custom branch from new upstream version**:

   ```bash
   git fetch upstream
   git checkout upstream/MOODLE_405_STABLE
   git checkout -b custom-405-stable
   ```

2. **Cherry-pick or merge your customizations**:

   ```bash
   # Option A: Cherry-pick specific commits
   git cherry-pick <commit-hash>

   # Option B: Merge from old custom branch (may have more conflicts)
   git merge custom-404-stable
   ```

3. **Test extensively** in development environment

4. **Push new custom branch**:
   ```bash
   git push origin custom-405-stable
   ```

## CI/CD Integration

### Deployment Strategy

1. **Development Environment**:

   - Pull from: `origin/develop` or feature branches
   - Auto-deploy on merge to develop branch

2. **Staging Environment**:

   - Pull from: `origin/custom-XXX-stable`
   - Deploy on PR approval or manual trigger

3. **Production Environment**:
   - Pull from: `origin/custom-XXX-stable` (specific tagged releases)
   - Manual deployment with approval gates

### Recommended CI/CD Pipeline

```yaml
# Example GitHub Actions workflow structure
on:
  push:
    branches: [custom-*-stable, develop]
  pull_request:
    branches: [custom-*-stable]

jobs:
  test:
    - Checkout code
    - Setup PHP and dependencies
    - Run PHPUnit tests
    - Run Behat tests
    - Code quality checks

  deploy-dev:
    if: branch == 'develop'
    - Deploy to development server

  deploy-staging:
    if: branch == 'custom-*-stable' && type == 'pull_request'
    - Deploy to staging server

  deploy-production:
    if: tagged-release
    - Manual approval required
    - Deploy to production server
    - Create rollback point
```

## File Organization Best Practices

### Where to Place Customizations

1. **Custom plugins**: `/local/pluginname/`
2. **Custom themes**: `/theme/customtheme/`
3. **Custom blocks**: `/blocks/customblock/`
4. **Custom authentication**: `/auth/customplugin/`
5. **Custom enrolment**: `/enrol/customplugin/`

### Files to Keep in Version Control

- All custom plugins and themes
- `config.php` (create `config-dist.php` template instead)
- Custom documentation
- CI/CD configuration files
- Deployment scripts

### Files to Exclude (in .gitignore)

- `config.php` (actual file with credentials)
- `moodledata/` directory
- Uploaded files and user data
- Cache directories
- Local development environment files

## Maintenance Schedule

- **Weekly**: Check for upstream security updates
- **Monthly**: Sync minor upstream changes
- **Quarterly**: Review and update custom code for compatibility
- **Annually**: Plan major version upgrades

## Rollback Strategy

1. **Tag all production releases**:

   ```bash
   git tag -a v404.2023.12.25 -m "Production release 2023-12-25"
   git push origin v404.2023.12.25
   ```

2. **Maintain rollback procedure**:
   ```bash
   # Rollback to previous version
   git checkout v404.2023.11.20
   # Deploy previous version
   ```

## Documentation Requirements

For each customization, document:

- Purpose and business justification
- Files modified
- Moodle version compatibility
- Dependencies
- Testing procedures
- Upgrade considerations

## Emergency Hotfix Process

1. Create hotfix branch from production tag:

   ```bash
   git checkout v404.2023.12.25
   git checkout -b hotfix/critical-issue
   ```

2. Apply fix, test, and commit

3. Merge to custom stable branch:

   ```bash
   git checkout custom-404-stable
   git merge hotfix/critical-issue
   ```

4. Tag and deploy:
   ```bash
   git tag -a v404.2023.12.25-hotfix1 -m "Hotfix: Critical issue"
   git push origin custom-404-stable --tags
   ```

## Resources

- Moodle Development Documentation: https://moodledev.io/
- Moodle Git Repository: https://github.com/moodle/moodle
- Moodle Upgrade Documentation: https://docs.moodle.org/en/Upgrading
- Git Best Practices: https://git-scm.com/book/en/v2

## Notes

- Always test upstream merges in a non-production environment first
- Keep customizations minimal and well-documented
- Consider contributing generic improvements back to upstream Moodle
- Maintain a separate testing instance that mirrors production
- Document all customization decisions and technical debt
