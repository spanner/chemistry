import Chemistry from 'chemistry';
import settings from './chemistry_settings.json';

const el = document.querySelector('[data-cms-page]');
new Chemistry(el, settings).start();
