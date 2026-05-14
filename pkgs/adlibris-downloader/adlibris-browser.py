#!/usr/bin/env python3
"""
Adlibris Browser Downloader - Uses Playwright to bypass bot detection
Handles library scraping and EPUB downloading with a real browser
"""

import asyncio
import json
import os
import sqlite3
import subprocess
import sys
import tempfile
from pathlib import Path
from urllib.parse import urlparse, parse_qs
import re

from playwright.async_api import async_playwright

# Configuration constants
CONFIG_DIR = Path.home() / ".config/adlibris-downloader"
CONFIG_FILE = CONFIG_DIR / "config"
DOWNLOADED_FILE = CONFIG_DIR / "downloaded.txt"
TMP_DIR = Path("/tmp/adlibris-downloader")

# Colors
RED = "\033[31m"
GREEN = "\033[32m"
YELLOW = "\033[33m"
BLUE = "\033[34m"
CYAN = "\033[36m"
BOLD = "\033[1m"
DIM = "\033[2m"
RESET = "\033[0m"

# Default config values
DEFAULTS = {
    'CRISUFLIX_HOST': 'llego@192.168.1.101',
    'CRISUFLIX_BOOKDROP': '/mnt/illby/transient/sabnzbd-downloads/complete/books',
    'ADLIBRIS_BASE': 'https://www.adlibris.com/fi',
    'ZEN_PROFILE_PATH': '',
    'ADLIBRIS_AUTH': '',
    'ADLIBRIS_ADSS': '',
}

def log(level, message):
    """Enhanced logging with colors"""
    if level == "info":
        print(f"{CYAN}→ {message}{RESET}")
    elif level == "ok":
        print(f"{GREEN}✔ {message}{RESET}")
    elif level == "warn":
        print(f"{YELLOW}⚠ {message}{RESET}")
    elif level == "error":
        print(f"{RED}✖ {message}{RESET}")
    else:
        print(message)

def load_config():
    """Load configuration from file"""
    config = DEFAULTS.copy()
    
    if not CONFIG_FILE.exists():
        CONFIG_DIR.mkdir(exist_ok=True)
        with open(CONFIG_FILE, 'w') as f:
            f.write("""# Adlibris downloader config
# Phase 1: paste cookie values from browser DevTools

ADLIBRIS_AUTH=""
ADLIBRIS_ADSS=""

# rsync destination
CRISUFLIX_HOST="llego@192.168.1.101"
CRISUFLIX_BOOKDROP="/mnt/illby/transient/sabnzbd-downloads/complete/books"

# Phase 2 (laptop only): path to Zen browser cookies.sqlite
ZEN_PROFILE_PATH="~/.config/zen/4p40ltny.Default Profile/cookies.sqlite"
""")
    
    # Parse config file
    with open(CONFIG_FILE, 'r') as f:
        for line in f:
            line = line.strip()
            if not line or line.startswith('#'):
                continue
            if '=' in line:
                key, value = line.split('=', 1)
                key = key.strip()
                value = value.strip().strip('"')
                if key in config:
                    config[key] = value
    
    return config

def extract_zen_cookies(zen_profile_path):
    """Extract cookies from Zen browser SQLite database"""
    expanded_path = os.path.expanduser(zen_profile_path)
    
    if not os.path.exists(expanded_path):
        return None, None
    
    log("info", "Extracting cookies from Zen browser...")
    
    # Copy database to avoid locks
    with tempfile.NamedTemporaryFile(suffix='.sqlite', delete=False) as tmp:
        subprocess.run(['cp', expanded_path, tmp.name], check=True)
        
        try:
            conn = sqlite3.connect(tmp.name)
            cursor = conn.cursor()
            
            # Extract .adlibrisauth cookie
            cursor.execute("""
                SELECT value FROM moz_cookies 
                WHERE host LIKE '%adlibris.com' AND name = '.adlibrisauth' 
                LIMIT 1
            """)
            auth_result = cursor.fetchone()
            auth_cookie = auth_result[0] if auth_result else None
            
            # Extract adss cookie
            cursor.execute("""
                SELECT value FROM moz_cookies 
                WHERE host LIKE '%adlibris.com' AND name = 'adss' 
                LIMIT 1
            """)
            adss_result = cursor.fetchone()
            adss_cookie = adss_result[0] if adss_result else None
            
            conn.close()
            
        finally:
            os.unlink(tmp.name)
    
    return auth_cookie, adss_cookie

async def scrape_library_with_browser(config):
    """Scrape library using Playwright browser"""
    books = []
    
    async with async_playwright() as p:
        # Use Firefox to match our cookie extraction from Zen (Firefox-based)
        browser = await p.firefox.launch(
            headless=True,  # Set to False for debugging
            args=[
                '--disable-blink-features=AutomationControlled'
            ]
        )
        
        try:
            context = await browser.new_context(
                user_agent='Mozilla/5.0 (X11; Linux x86_64; rv:133.0) Gecko/20100101 Firefox/133.0',
                viewport={'width': 1920, 'height': 1080},
                locale='fi-FI',
                extra_http_headers={
                    'Accept-Language': 'fi,en-US;q=0.9,en;q=0.8',
                    'DNT': '1',
                }
            )
            
            # Add cookies to browser context
            await context.add_cookies([
                {
                    'name': '.adlibrisauth',
                    'value': config['ADLIBRIS_AUTH'],
                    'domain': '.adlibris.com',
                    'path': '/',
                    'httpOnly': True,
                    'secure': True,
                    'sameSite': 'Lax',
                },
                {
                    'name': 'adss',
                    'value': config['ADLIBRIS_ADSS'],
                    'domain': '.adlibris.com',
                    'path': '/',
                    'httpOnly': False,
                    'secure': True,
                    'sameSite': 'Lax',
                },
                {
                    'name': 'culture',
                    'value': 'fi-FI',
                    'domain': '.adlibris.com',
                    'path': '/',
                    'httpOnly': False,
                    'secure': True,
                    'sameSite': 'Lax',
                }
            ])
            
            page = await context.new_page()
            
            # Enable request/response logging for debugging
            async def handle_response(response):
                if 'vercel' in response.url.lower() or 'security' in response.url.lower():
                    log("warn", f"Possible security challenge detected: {response.url}")
                elif response.status >= 400:
                    log("warn", f"HTTP {response.status}: {response.url}")
            
            page.on('response', handle_response)
            
            log("info", "Navigating to Adlibris library...")
            
            # First, visit the main page to establish session
            await page.goto(f"{config['ADLIBRIS_BASE']}/", wait_until='networkidle')
            await asyncio.sleep(2)
            
            # Navigate to library
            library_url = f"{config['ADLIBRIS_BASE']}/asiakastili/library"
            response = await page.goto(library_url, wait_until='networkidle')
            
            if response.status != 200:
                log("error", f"Failed to access library: HTTP {response.status}")
                return books
            
            # Check if we're still on a security checkpoint
            title = await page.title()
            content = await page.content()
            
            if 'vercel' in title.lower() or 'security' in title.lower():
                log("error", "Still blocked by security checkpoint")
                return books
            
            if 'login' in content.lower() or 'sign in' in content.lower():
                log("error", "Authentication failed - cookies may be expired")
                return books
            
            log("info", "Successfully accessed library, parsing books...")
            
            # Wait for book list to load
            await page.wait_for_selector('.product-list-item, .book-item, [data-testid*="book"]', timeout=10000)
            
            page_num = 1
            while True:
                log("info", f"Processing page {page_num}...")
                
                # Extract books from current page
                books_on_page = await page.evaluate("""
                    () => {
                        const books = [];
                        // Try multiple selectors to find book items
                        const selectors = [
                            '.product-list-item',
                            '.book-item', 
                            '[data-testid*="book"]',
                            '.library-item'
                        ];
                        
                        let bookElements = [];
                        for (const selector of selectors) {
                            bookElements = document.querySelectorAll(selector);
                            if (bookElements.length > 0) break;
                        }
                        
                        bookElements.forEach(element => {
                            try {
                                // Extract variant ID from download links or data attributes
                                const downloadLink = element.querySelector('a[href*="download"]');
                                let variantId = null;
                                
                                if (downloadLink) {
                                    const href = downloadLink.href;
                                    const match = href.match(/variantId=([^&]+)/);
                                    if (match) variantId = match[1];
                                }
                                
                                // Extract title and author
                                const titleEl = element.querySelector('h3, .title, [data-testid*="title"]');
                                const authorEl = element.querySelector('.author, [data-testid*="author"]');
                                
                                const title = titleEl ? titleEl.textContent.trim() : 'Unknown Title';
                                const author = authorEl ? authorEl.textContent.trim() : 'Unknown Author';
                                
                                // Determine format type
                                const formatEl = element.querySelector('.format, .book-format');
                                let format = 'Unknown';
                                
                                if (formatEl) {
                                    const formatText = formatEl.textContent.toLowerCase();
                                    if (formatText.includes('epub')) format = 'EpubWatermark';
                                    else if (formatText.includes('drm')) format = 'DRM';
                                    else if (formatText.includes('pdf')) format = 'PDF';
                                }
                                
                                if (variantId) {
                                    books.push({
                                        variantId: variantId,
                                        type: format,
                                        title: title,
                                        author: author
                                    });
                                }
                            } catch (e) {
                                console.log('Error parsing book element:', e);
                            }
                        });
                        
                        return books;
                    }
                """)
                
                books.extend(books_on_page)
                log("info", f"Found {len(books_on_page)} books on page {page_num}")
                
                # Check for next page
                next_button = await page.query_selector('a[aria-label="Next page"], .next-page, .pagination-next')
                if not next_button or await next_button.is_disabled():
                    break
                
                await next_button.click()
                await page.wait_for_load_state('networkidle')
                page_num += 1
                
                # Safety limit
                if page_num > 50:
                    log("warn", "Reached page limit (50), stopping pagination")
                    break
            
        except Exception as e:
            log("error", f"Browser automation error: {str(e)}")
        
        finally:
            await browser.close()
    
    return books

async def download_with_browser(variant_id, title, author, config):
    """Download EPUB using browser"""
    safe_name = f"{author} - {title}".replace('"', '').replace('?', '').replace('\\', '').replace('/', '_').replace(':', '_').replace('*', '_').replace('<', '_').replace('>', '_').replace('|', '_')
    dest_path = TMP_DIR / f"{safe_name}.epub"
    
    TMP_DIR.mkdir(exist_ok=True)
    
    log("info", f"Downloading: {title} — {author}")
    
    async with async_playwright() as p:
        browser = await p.firefox.launch(headless=True)
        
        try:
            context = await browser.new_context(
                user_agent='Mozilla/5.0 (X11; Linux x86_64; rv:133.0) Gecko/20100101 Firefox/133.0',
                accept_downloads=True
            )
            
            # Add cookies
            await context.add_cookies([
                {
                    'name': '.adlibrisauth',
                    'value': config['ADLIBRIS_AUTH'],
                    'domain': '.adlibris.com',
                    'path': '/',
                    'httpOnly': True,
                    'secure': True,
                    'sameSite': 'Lax',
                },
                {
                    'name': 'adss',
                    'value': config['ADLIBRIS_ADSS'],
                    'domain': '.adlibris.com',
                    'path': '/',
                    'httpOnly': False,
                    'secure': True,
                    'sameSite': 'Lax',
                }
            ])
            
            page = await context.new_page()
            
            # Navigate to download URL
            download_url = f"{config['ADLIBRIS_BASE']}/tuote/download?variantId={variant_id}&selectedVersion=EpubWatermark"
            
            # Start waiting for download
            async with page.expect_download() as download_info:
                response = await page.goto(download_url)
                
                if response.status != 200:
                    log("warn", f"HTTP {response.status} for: {title}")
                    return False
            
            download = await download_info.value
            
            # Save download
            await download.save_as(dest_path)
            
            # Verify EPUB file
            if dest_path.exists() and dest_path.stat().st_size > 1000:  # At least 1KB
                log("ok", f"Downloaded: {dest_path.name}")
                return True
            else:
                log("warn", f"Download failed or file too small: {title}")
                dest_path.unlink(missing_ok=True)
                return False
            
        except Exception as e:
            log("error", f"Download error: {str(e)}")
            return False
        
        finally:
            await browser.close()

async def main():
    """Main function"""
    # Load configuration
    config = load_config()
    
    # Try to extract cookies from Zen if configured
    if config['ZEN_PROFILE_PATH'] and not (config['ADLIBRIS_AUTH'] and config['ADLIBRIS_ADSS']):
        auth, adss = extract_zen_cookies(config['ZEN_PROFILE_PATH'])
        if auth and adss:
            config['ADLIBRIS_AUTH'] = auth
            config['ADLIBRIS_ADSS'] = adss
            log("ok", "Extracted cookies from Zen browser")
        else:
            log("warn", "Failed to extract cookies from Zen browser")
    
    # Validate configuration
    if not config['ADLIBRIS_AUTH'] or not config['ADLIBRIS_ADSS']:
        log("error", "Missing authentication cookies. Please configure ADLIBRIS_AUTH and ADLIBRIS_ADSS in config file.")
        return 1
    
    # Create directories
    TMP_DIR.mkdir(exist_ok=True)
    DOWNLOADED_FILE.parent.mkdir(exist_ok=True)
    DOWNLOADED_FILE.touch()
    
    # Get downloaded books list
    downloaded_books = set()
    if DOWNLOADED_FILE.exists():
        with open(DOWNLOADED_FILE, 'r') as f:
            downloaded_books = {line.strip() for line in f if line.strip()}
    
    # Scrape library
    log("info", "Scraping library with browser automation...")
    books = await scrape_library_with_browser(config)
    
    if not books:
        log("error", "No books found — check your cookie values or authentication")
        return 1
    
    # Filter and display books
    total_books = len(books)
    epub_books = [b for b in books if b['type'] == 'EpubWatermark']
    drm_books = [b for b in books if b['type'] == 'DRM']
    new_books = [b for b in epub_books if b['variantId'] not in downloaded_books]
    
    print(f"\n{BOLD}Library:{RESET} {total_books} books total  |  {len(epub_books)} watermarked EPUB  |  {len(drm_books)} Adobe DRM (skipped)  |  {len(downloaded_books)} already downloaded\n")
    
    if not new_books:
        log("warn", "No new books found — all books already downloaded.")
        return 0
    
    # Simple download all new books for now (can be enhanced with fzf later)
    print(f"Downloading {len(new_books)} new books...\n")
    
    success = 0
    failed = 0
    
    for book in new_books:
        if await download_with_browser(book['variantId'], book['title'], book['author'], config):
            # Record as downloaded
            with open(DOWNLOADED_FILE, 'a') as f:
                f.write(f"{book['variantId']}\n")
            success += 1
        else:
            failed += 1
        
        # Small delay between downloads
        await asyncio.sleep(2)
    
    print(f"\n{BOLD}Done:{RESET} {GREEN}{success} downloaded{RESET}  |  {RED}{failed} failed{RESET}")
    
    # Rsync to crisuflix if any files were downloaded
    if success > 0:
        log("info", "Syncing files to crisuflix...")
        try:
            subprocess.run([
                'rsync', '-av', '--progress',
                str(TMP_DIR) + '/',
                f"{config['CRISUFLIX_HOST']}:{config['CRISUFLIX_BOOKDROP']}/"
            ], check=True)
            log("ok", f"Successfully synced {success} books to crisuflix")
        except subprocess.CalledProcessError as e:
            log("error", f"Rsync failed: {e}")
            return 1
    
    return 0

if __name__ == "__main__":
    try:
        exit_code = asyncio.run(main())
        sys.exit(exit_code)
    except KeyboardInterrupt:
        log("warn", "Interrupted by user")
        sys.exit(130)
    except Exception as e:
        log("error", f"Unexpected error: {str(e)}")
        sys.exit(1)