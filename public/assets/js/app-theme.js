/**
 * Theme Management System
 * Handles switching between light and dark themes with localStorage persistence
 */

class ThemeManager {
    constructor() {
        this.THEME_KEY = 'bbpm-theme';
        this.DARK_THEME = 'dark';
        this.LIGHT_THEME = 'light';
        this.init();
    }

    /**
     * Initialize theme manager
     */
    init() {
        // Check system preference and stored preference
        const storedTheme = this.getStoredTheme();
        const systemPreference = this.getSystemPreference();
        const theme = storedTheme || systemPreference;

        this.setTheme(theme);
        this.attachToggleListener();
        this.watchSystemPreference();
    }

    /**
     * Get theme from localStorage
     */
    getStoredTheme() {
        return localStorage.getItem(this.THEME_KEY);
    }

    /**
     * Get system preference (from prefers-color-scheme)
     */
    getSystemPreference() {
        if (window.matchMedia && window.matchMedia('(prefers-color-scheme: dark)').matches) {
            return this.DARK_THEME;
        }
        return this.LIGHT_THEME;
    }

    /**
     * Set the current theme
     */
    setTheme(theme) {
        if (theme === this.DARK_THEME) {
            document.documentElement.setAttribute('data-theme', this.DARK_THEME);
            localStorage.setItem(this.THEME_KEY, this.DARK_THEME);
            this.updateToggleButton(this.DARK_THEME);
        } else {
            document.documentElement.removeAttribute('data-theme');
            localStorage.setItem(this.THEME_KEY, this.LIGHT_THEME);
            this.updateToggleButton(this.LIGHT_THEME);
        }
    }

    /**
     * Toggle between themes
     */
    toggle() {
        const currentTheme = document.documentElement.getAttribute('data-theme') || this.LIGHT_THEME;
        const newTheme = currentTheme === this.DARK_THEME ? this.LIGHT_THEME : this.DARK_THEME;
        this.setTheme(newTheme);
    }

    /**
     * Attach toggle button listener
     */
    attachToggleListener() {
        const toggleBtn = document.getElementById('theme-toggle-btn');
        if (toggleBtn) {
            toggleBtn.addEventListener('click', () => this.toggle());
        }
    }

    /**
     * Update toggle button icon
     */
    updateToggleButton(theme) {
        const toggleBtn = document.getElementById('theme-toggle-btn');
        if (!toggleBtn) return;

        // Get current icon
        const icon = toggleBtn.querySelector('i');
        if (!icon) return;

        // Update icon based on current theme
        if (theme === this.DARK_THEME) {
            // Show moon icon (indicating light mode is available)
            icon.className = 'bi bi-sun-fill';
            toggleBtn.setAttribute('aria-label', 'Switch to light theme');
            toggleBtn.setAttribute('title', 'Switch to light theme');
        } else {
            // Show sun icon (indicating dark mode is available)
            icon.className = 'bi bi-moon-stars-fill';
            toggleBtn.setAttribute('aria-label', 'Switch to dark theme');
            toggleBtn.setAttribute('title', 'Switch to dark theme');
        }
    }

    /**
     * Watch for system preference changes
     */
    watchSystemPreference() {
        if (!window.matchMedia) return;

        const darkModeQuery = window.matchMedia('(prefers-color-scheme: dark)');
        darkModeQuery.addEventListener('change', (e) => {
            const storedTheme = this.getStoredTheme();
            // Only apply system preference if user hasn't manually set a theme
            if (!storedTheme) {
                this.setTheme(e.matches ? this.DARK_THEME : this.LIGHT_THEME);
            }
        });
    }

    /**
     * Get current theme
     */
    getCurrentTheme() {
        return document.documentElement.getAttribute('data-theme') || this.LIGHT_THEME;
    }

    /**
     * Check if dark theme is active
     */
    isDarkTheme() {
        return this.getCurrentTheme() === this.DARK_THEME;
    }
}

// Initialize theme manager when DOM is ready
if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', () => {
        window.themeManager = new ThemeManager();
    });
} else {
    window.themeManager = new ThemeManager();
}
