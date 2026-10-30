import { createRoot } from 'react-dom/client';
import App from './App';
import { go } from './engine/router';
import { activeRun, useSession } from './engine/run';
import './index.css';

// No StrictMode: games run timed sequences in effects, and a dev double-mount would play them twice.
createRoot(document.getElementById('root')!).render(<App />);

const inFlutter = 'flutter_inappwebview' in window;
if (inFlutter) document.documentElement.classList.add('in-app');

// The Hash app's back button asks the page first: a running game pauses, any
// other screen returns to the arcade, and only the arcade home lets the app leave.
(window as unknown as { hashBack: () => boolean }).hashBack = () => {
  if (activeRun.current && useSession.getState().status === 'playing') {
    activeRun.current.pause();
    return true;
  }
  if (location.hash.replace(/^#\/?/, '') === '') return false;
  go('');
  return true;
};
if (import.meta.env.PROD && !inFlutter && 'serviceWorker' in navigator && location.protocol.startsWith('http')) {
  navigator.serviceWorker.register('./sw.js').catch(() => {});
}
