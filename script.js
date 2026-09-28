// ============================================
// SOLARO - INTERACTIVE FEATURES
// ============================================

document.addEventListener('DOMContentLoaded', function() {
    initializeNavigation();
    initializeButtons();
    initializeTooltips();
    initializeScrollEffects();
});

// ============================================
// NAVIGATION
// ============================================

function initializeNavigation() {
    const navItems = document.querySelectorAll('.nav-item');
    
    navItems.forEach(item => {
        item.addEventListener('click', function(e) {
            e.preventDefault();
            
            // Remove active class from all items
            navItems.forEach(nav => nav.classList.remove('active'));
            
            // Add active class to clicked item
            this.classList.add('active');
        });
    });
}

// ============================================
// BUTTONS AND CTAs
// ============================================

function initializeButtons() {
    const allButtons = document.querySelectorAll('button, a[href="#"]');
    
    allButtons.forEach(button => {
        button.addEventListener('click', function(e) {
            if (this.href === '#') {
                e.preventDefault();
            }
            
            // Add ripple effect
            addRippleEffect(this, e);
        });
        
        // Add keyboard support
        if (this.tagName === 'BUTTON') {
            this.addEventListener('keydown', function(e) {
                if (e.key === ' ' || e.key === 'Enter') {
                    e.preventDefault();
                    this.click();
                }
            });
        }
    });
}

function addRippleEffect(element, event) {
    const ripple = document.createElement('span');
    
    const rect = element.getBoundingClientRect();
    const size = Math.max(rect.width, rect.height);
    const x = event.clientX - rect.left - size / 2;
    const y = event.clientY - rect.top - size / 2;
    
    ripple.style.width = ripple.style.height = size + 'px';
    ripple.style.left = x + 'px';
    ripple.style.top = y + 'px';
    ripple.classList.add('ripple');
    
    // Add ripple styles if not already in CSS
    if (!document.getElementById('ripple-styles')) {
        const style = document.createElement('style');
        style.id = 'ripple-styles';
        style.textContent = `
            .ripple {
                position: absolute;
                border-radius: 50%;
                background: rgba(255, 255, 255, 0.5);
                transform: scale(0);
                animation: ripple-animation 0.6s ease-out;
                pointer-events: none;
            }
            
            @keyframes ripple-animation {
                to {
                    transform: scale(4);
                    opacity: 0;
                }
            }
        `;
        document.head.appendChild(style);
    }
    
    element.style.position = 'relative';
    element.style.overflow = 'hidden';
    element.appendChild(ripple);
    
    setTimeout(() => ripple.remove(), 600);
}

// ============================================
// TOOLTIPS
// ============================================

function initializeTooltips() {
    const tooltipTriggers = document.querySelectorAll('[data-tooltip]');
    
    tooltipTriggers.forEach(trigger => {
        trigger.addEventListener('mouseenter', function() {
            showTooltip(this);
        });
        
        trigger.addEventListener('mouseleave', function() {
            hideTooltip(this);
        });
    });
}

function showTooltip(element) {
    const tooltip = document.createElement('div');
    tooltip.className = 'tooltip';
    tooltip.textContent = element.getAttribute('data-tooltip');
    
    // Add tooltip styles if not already in CSS
    if (!document.getElementById('tooltip-styles')) {
        const style = document.createElement('style');
        style.id = 'tooltip-styles';
        style.textContent = `
            .tooltip {
                position: absolute;
                background-color: rgba(0, 0, 0, 0.8);
                color: white;
                padding: 8px 12px;
                border-radius: 4px;
                font-size: 12px;
                white-space: nowrap;
                z-index: 1000;
                pointer-events: none;
                bottom: 100%;
                left: 50%;
                transform: translateX(-50%) translateY(-8px);
                animation: tooltip-fade 0.3s ease-in-out;
            }
            
            @keyframes tooltip-fade {
                from {
                    opacity: 0;
                    transform: translateX(-50%) translateY(0);
                }
                to {
                    opacity: 1;
                    transform: translateX(-50%) translateY(-8px);
                }
            }
        `;
        document.head.appendChild(style);
    }
    
    element.style.position = 'relative';
    element.appendChild(tooltip);
    element._tooltip = tooltip;
}

function hideTooltip(element) {
    if (element._tooltip) {
        element._tooltip.remove();
        delete element._tooltip;
    }
}

// ============================================
// SCROLL EFFECTS
// ============================================

function initializeScrollEffects() {
    const sections = document.querySelectorAll('section');
    
    const observer = new IntersectionObserver((entries) => {
        entries.forEach(entry => {
            if (entry.isIntersecting) {
                entry.target.style.opacity = '1';
                entry.target.style.transform = 'translateY(0)';
            }
        });
    }, {
        threshold: 0.1
    });
    
    sections.forEach(section => {
        section.style.opacity = '0';
        section.style.transform = 'translateY(20px)';
        section.style.transition = 'all 0.6s ease-in-out';
        observer.observe(section);
    });
}

// ============================================
// CHART INTERACTIVITY
// ============================================

document.addEventListener('DOMContentLoaded', function() {
    const barChart = document.querySelector('.bar-chart');
    if (barChart) {
        initializeChartInteractivity(barChart);
    }
});

function initializeChartInteractivity(chart) {
    const bars = chart.querySelectorAll('rect[fill="#FFC107"]');
    
    bars.forEach((bar, index) => {
        const originalHeight = bar.getAttribute('height');
        const originalY = bar.getAttribute('y');
        const months = ['Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio', 'Julio'];
        
        bar.style.cursor = 'pointer';
        bar.style.transition = 'all 0.3s ease';
        
        bar.addEventListener('mouseenter', function() {
            bar.setAttribute('fill', '#FFA500');
            bar.style.filter = 'drop-shadow(0 4px 8px rgba(255, 193, 7, 0.3))';
            
            // Show tooltip with month data
            showChartTooltip(bar, months[index]);
        });
        
        bar.addEventListener('mouseleave', function() {
            bar.setAttribute('fill', '#FFC107');
            bar.style.filter = 'none';
            hideChartTooltip();
        });
    });
}

function showChartTooltip(bar, monthName) {
    const existingTooltip = document.getElementById('chart-tooltip');
    if (existingTooltip) existingTooltip.remove();
    
    const tooltip = document.createElement('div');
    tooltip.id = 'chart-tooltip';
    tooltip.textContent = monthName;
    tooltip.style.cssText = `
        position: fixed;
        background-color: rgba(0, 0, 0, 0.9);
        color: white;
        padding: 8px 12px;
        border-radius: 4px;
        font-size: 12px;
        pointer-events: none;
        z-index: 1000;
    `;
    
    document.body.appendChild(tooltip);
}

function hideChartTooltip() {
    const tooltip = document.getElementById('chart-tooltip');
    if (tooltip) tooltip.remove();
}

// ============================================
// APPLIANCE CARDS ANIMATION
// ============================================

document.addEventListener('DOMContentLoaded', function() {
    const applianceCards = document.querySelectorAll('.appliance-card');
    
    applianceCards.forEach((card, index) => {
        card.addEventListener('mouseenter', function() {
            this.style.animation = `float 0.6s ease-in-out`;
        });
    });
});

// Add animation to CSS
(function() {
    if (!document.getElementById('appliance-animations')) {
        const style = document.createElement('style');
        style.id = 'appliance-animations';
        style.textContent = `
            @keyframes float {
                0%, 100% {
                    transform: translateY(0px);
                }
                50% {
                    transform: translateY(-8px);
                }
            }
        `;
        document.head.appendChild(style);
    }
})();

// ============================================
// RESPONSIVE SIDEBAR
// ============================================

document.addEventListener('DOMContentLoaded', function() {
    handleResponsiveSidebar();
    window.addEventListener('resize', handleResponsiveSidebar);
});

function handleResponsiveSidebar() {
    const sidebar = document.querySelector('.sidebar');
    const navMenu = document.querySelector('.nav-menu');
    
    if (window.innerWidth <= 768 && sidebar) {
        sidebar.classList.add('mobile-sidebar');
    } else if (sidebar) {
        sidebar.classList.remove('mobile-sidebar');
    }
}

// ============================================
// ACCESSIBILITY
// ============================================

// Add keyboard navigation support
document.addEventListener('DOMContentLoaded', function() {
    const focusableElements = document.querySelectorAll(
        'button, [href], input, select, textarea'
    );
    
    focusableElements.forEach(element => {
        element.addEventListener('focus', function() {
            this.style.outline = '3px solid #FFC107';
            this.style.outlineOffset = '2px';
        });
        
        element.addEventListener('blur', function() {
            this.style.outline = 'none';
        });
    });
});

// Reduce motion support
function respectReducedMotion() {
    if (window.matchMedia('(prefers-reduced-motion: reduce)').matches) {
        const style = document.createElement('style');
        style.textContent = `
            * {
                animation-duration: 0.01ms !important !important;
                animation-iteration-count: 1 !important !important;
                transition-duration: 0.01ms !important !important;
            }
        `;
        document.head.appendChild(style);
    }
}

respectReducedMotion();

// ============================================
// PERFORMANCE OPTIMIZATION
// ============================================

// Lazy loading for images
if ('IntersectionObserver' in window) {
    const lazyImages = document.querySelectorAll('img[data-src]');
    
    lazyImages.forEach(img => {
        const observer = new IntersectionObserver((entries) => {
            entries.forEach(entry => {
                if (entry.isIntersecting) {
                    img.src = img.dataset.src;
                    img.removeAttribute('data-src');
                    observer.unobserve(img);
                }
            });
        });
        
        observer.observe(img);
    });
}

// Debounce function for resize events
function debounce(func, wait) {
    let timeout;
    return function executedFunction(...args) {
        const later = () => {
            clearTimeout(timeout);
            func(...args);
        };
        clearTimeout(timeout);
        timeout = setTimeout(later, wait);
    };
}

// ============================================
// ERROR HANDLING
// ============================================

window.addEventListener('error', function(event) {
    console.error('Error:', event.error);
    // Optionally send error to logging service
});

// ============================================
// PAGE VISIBILITY
// ============================================

document.addEventListener('visibilitychange', function() {
    if (document.hidden) {
        console.log('Página oculta');
    } else {
        console.log('Página visible');
    }
});
