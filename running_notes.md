# Local Development Notes

## ✅ Working Development Workflow

### Step-by-Step (Manual)
1. Build the MFEs first:
   ```bash
   npm run build:mfes
   ```

2. Start MFEs in preview mode:
   ```bash
   npm run preview:mfes
   ```

3. In another terminal, start the host:
   ```bash
   npm run dev:host
   ```

### One-Command (Automatic)
```bash
npm run dev
```

### Quick Restart (if MFEs already built)
```bash
npm run dev:quick
```

## 🚫 What Doesn't Work

- ~~`dev:mfes`~~ - Removed! Running MFEs in development mode doesn't work with module federation
- Individual `npm run dev:mfe1` or `npm run dev:mfe2` for federation (they work standalone)

## ✅ What Works Great

- `build:mfes` → `preview:mfes` → `dev:host` (this is the proven workflow)
- All build and preview scripts work perfectly
- Host development mode with hot reload works when MFEs are running in preview

## 🔧 Useful Commands

```bash
# Check if services are running
npm run check:services

# Clean everything and start fresh
npm run clean && npm install && npm run dev
```
