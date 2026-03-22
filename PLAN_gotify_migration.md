# Gotify Docker → NixOS Migration Plan

## Overview
Migrate Gotify push notification server from Docker container to native NixOS service on christiansandberg.fi.

## Current State

**Docker Setup:**
- Container: `gotify` (gotify/server image)
- Internal port: 80 (exposed, routed via Traefik)
- Data: `/opt/appdata/gotify/` (gotify.db ~10MB, images/, plugins/)
- Users: admin/DiplomGotify, snusket/arbetare
- Routing: Traefik Docker labels on `traefik` network
- Domain: gotify.christiansandberg.fi

## Migration Steps

### Phase 1: Backup (Safety First)

1. **SSH to christiansandberg**:
   ```bash
   ssh llego@christiansandberg.fi
   ```

2. **Create backup**:
   ```bash
   sudo mkdir -p /opt/backups
   sudo tar czf /opt/backups/gotify-docker-$(date +%Y%m%d).tar.gz -C /opt/appdata gotify
   ls -lh /opt/backups/gotify-docker-*.tar.gz
   ```

3. **Verify backup integrity**:
   ```bash
   sudo tar tzf /opt/backups/gotify-docker-$(date +%Y%m%d).tar.gz
   ```

### Phase 2: Stop Docker Gotify

1. **Stop and disable container**:
   ```bash
   cd /opt/stacks/gotify
   docker compose down
   docker compose rm
   ```

2. **Verify container is gone**:
   ```bash
   docker ps | grep gotify  # Should return nothing
   ```

### Phase 3: Configure NixOS Gotify Service

Add to `/home/llego/nixconfig/hosts/christiansandberg.nix`:

```nix
  # Gotify push notification server
  services.gotify = {
    enable = true;
    environment = {
      GOTIFY_SERVER_PORT = 8080;
      GOTIFY_SERVER_LISTENADDR = "127.0.0.1";  # Only localhost, Traefik will proxy
      GOTIFY_DATABASE_DIALECT = "sqlite3";
      GOTIFY_DATABASE_CONNECTION = "data/gotify.db";
      GOTIFY_DEFAULTUSER_NAME = "admin";
      GOTIFY_DEFAULTUSER_PASS = "DiplomGotify";  # Same as current
      GOTIFY_UPLOADEDIMAGESDIR = "data/images";
      GOTIFY_PLUGINSDIR = "data/plugins";
    };
  };
```

**Note**: No firewall rule needed since Traefik (in Docker) connects via localhost.

### Phase 4: Deploy Configuration

1. **Build and deploy** (from laptop):
   ```bash
   cd ~/nixconfig
   nixos-rebuild switch --flake .#christiansandberg \
     --build-host llego@crisuflix.home \
     --target-host "llego@christiansandberg.fi" --sudo
   ```

2. **Verify service is running**:
   ```bash
   ssh llego@christiansandberg.fi
   sudo systemctl status gotify-server
   sudo ss -tlnp | grep 8080  # Should show gotify listening on 127.0.0.1:8080
   ```

### Phase 5: Migrate Data

The NixOS service stores data in `/var/lib/gotify-server/`. We need to copy the existing data:

1. **Copy data from Docker volume**:
   ```bash
   ssh llego@christiansandberg.fi
   sudo mkdir -p /var/lib/gotify-server/data
   sudo cp -r /opt/appdata/gotify/* /var/lib/gotify-server/data/
   sudo chown -R gotify-server:gotify-server /var/lib/gotify-server/
   sudo ls -la /var/lib/gotify-server/data/
   ```

2. **Restart gotify service to pick up data**:
   ```bash
   sudo systemctl restart gotify-server
   sudo systemctl status gotify-server
   ```

3. **Verify data loaded**:
   ```bash
   curl -s http://127.0.0.1:8080/version  # Should return version info
   # Or check logs
   sudo journalctl -u gotify-server -n 50
   ```

### Phase 6: Update Traefik Routing

Since we're moving from Docker container to host service, Traefik needs a new route.

1. **Edit Traefik static config**:
   ```bash
   ssh llego@christiansandberg.fi
   sudo nano /opt/appdata/traefik/config.yml
   ```

2. **Add gotify router and service**:
   ```yaml
   http:
     routers:
       # ... existing routers ...
       
       gotify:
         rule: "Host(`gotify.christiansandberg.fi`)"
         service: gotify
         entryPoints:
           - websecure
         tls:
           certResolver: myresolver
     
     services:
       # ... existing services ...
       
       gotify:
         loadBalancer:
           servers:
             - url: "http://127.0.0.1:8080"
   ```

3. **Restart Traefik**:
   ```bash
   cd /opt/stacks/traefik
   docker compose restart
   docker logs traefik --tail 50
   ```

### Phase 7: Testing

1. **Verify HTTPS access**:
   - Visit https://gotify.christiansandberg.fi
   - Login with admin/DiplomGotify
   - Verify all apps, messages, and images are present

2. **Test push notifications**:
   - Use existing apps to send test messages
   - Verify Android/iOS apps receive notifications

3. **Check logs for errors**:
   ```bash
   ssh llego@christiansandberg.fi
   sudo journalctl -u gotify-server -f  # Follow logs
   docker logs traefik --tail 20  # Check Traefik routing
   ```

### Phase 8: Cleanup (After 24-48 hours of successful operation)

1. **Remove Docker compose and data**:
   ```bash
   ssh llego@christiansandberg.fi
   sudo rm -rf /opt/stacks/gotify
   sudo rm -rf /opt/appdata/gotify
   ```

2. **Remove gotify from backup rotation** if using docker-volume-backup.

## Rollback Plan

If something goes wrong:

1. **Stop NixOS gotify**:
   ```bash
   ssh llego@christiansandberg.fi
   sudo systemctl stop gotify-server
   sudo systemctl disable gotify-server
   ```

2. **Restore Docker container**:
   ```bash
   mkdir -p /opt/stacks/gotify
   # Recreate compose.yaml from backup or memory
   cd /opt/stacks/gotify
   docker compose up -d
   ```

3. **Restore data** (if needed):
   ```bash
   sudo rm -rf /opt/appdata/gotify
   sudo tar xzf /opt/backups/gotify-docker-YYYYMMDD.tar.gz -C /opt/appdata
   docker compose restart
   ```

## Configuration Summary

| Setting | Docker | NixOS |
|---------|--------|-------|
| Port | 80 (internal) | 8080 (localhost only) |
| Data path | /opt/appdata/gotify | /var/lib/gotify-server/data |
| User | root in container | DynamicUser (gotify-server) |
| Process | Docker container | systemd service |
| Config | Environment vars | services.gotify.environment |

## Post-Migration Benefits

- **Simpler**: No Docker container management
- **Integrated**: Native NixOS service with systemd
- **Secure**: Runs as unprivileged DynamicUser
- **Standard**: Follows NixOS conventions for data in /var/lib
- **Maintainable**: Updated with nixos-rebuild like rest of system

## Questions to Resolve

1. **Should we move the password to an environment file or agenix secret?**
   - Current: Plaintext in Nix config
   - Better: Use `environmentFiles` with agenix-encrypted file
   
2. **Do we want to change the port?**
   - Current plan: 8080 on localhost
   - Alternative: Use Unix socket for even better security

3. **Should we migrate other services too?**
   - This migration pattern can be used for other simple services
   - Complex services (Traefik, Authelia) might stay in Docker
