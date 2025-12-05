/**
 * Theme Management System
 * Forced Dark Theme Only
 */

class ThemeManager {
    constructor() {
        this.DARK_THEME = 'dark';
        this.init();
    }

    /**
     * Initialize theme manager - always use dark theme
     */
    init() {
        this.setTheme(this.DARK_THEME);
    }

    /**
     * Set the dark theme (only option)
     */
    setTheme(theme) {
        document.documentElement.setAttribute('data-theme', this.DARK_THEME);
    }
}

// Initialize theme on page load
if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', () => {
        new ThemeManager();
    });
} else {
    new ThemeManager();
}
