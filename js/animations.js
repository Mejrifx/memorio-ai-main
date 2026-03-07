/**
 * GSAP scroll animations for Memorio main site.
 * Sections: Why we built Memorio (mission), Why Choose Memorio (features), How it Works.
 */
(function () {
  'use strict';

  function init() {
    if (typeof gsap === 'undefined' || typeof ScrollTrigger === 'undefined') return;
    gsap.registerPlugin(ScrollTrigger);

    var ease = 'power3.out';
    var startY = 'top 85%';

    // ----- Why we built Memorio (mission) -----
    var missionHeader = document.querySelector('.mission-header');
    if (missionHeader) {
      gsap.from(missionHeader, {
        opacity: 0,
        y: 28,
        duration: 0.8,
        ease: ease,
        scrollTrigger: { trigger: missionHeader, start: startY }
      });
    }

    var missionCards = gsap.utils.toArray('.mission-point-card');
    if (missionCards.length) {
      gsap.to(missionCards, {
        opacity: 1,
        y: 0,
        scale: 1,
        duration: 0.75,
        stagger: { amount: 0.4, from: 'start' },
        ease: ease,
        scrollTrigger: {
          trigger: '.mission-points-grid',
          start: startY
        }
      });
    }

    // ----- Why Choose Memorio (features) -----
    var featuresHeader = document.querySelector('.features .section-header');
    if (featuresHeader) {
      gsap.from(featuresHeader, {
        opacity: 0,
        y: 32,
        duration: 0.8,
        ease: ease,
        scrollTrigger: { trigger: featuresHeader, start: startY }
      });
    }

    var featureCards = gsap.utils.toArray('.feature-card');
    if (featureCards.length) {
      gsap.from(featureCards, {
        opacity: 0,
        y: 36,
        duration: 0.7,
        stagger: { amount: 0.5, from: 'start' },
        ease: ease,
        scrollTrigger: { trigger: '.features-grid', start: startY }
      });
    }

    // ----- How it Works -----
    var howHeader = document.querySelector('.how-it-works .section-header');
    if (howHeader) {
      gsap.from(howHeader, {
        opacity: 0,
        y: 32,
        duration: 0.8,
        ease: ease,
        scrollTrigger: { trigger: howHeader, start: startY }
      });
    }

    var steps = gsap.utils.toArray('.how-it-works .step');
    if (steps.length) {
      gsap.to(steps, {
        opacity: 1,
        y: 0,
        duration: 0.75,
        stagger: { amount: 0.45, from: 'start' },
        ease: ease,
        scrollTrigger: { trigger: '.steps-container', start: startY }
      });
    }
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', init);
  } else {
    init();
  }
})();
