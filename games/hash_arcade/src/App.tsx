import { AnimatePresence, LazyMotion, MotionConfig, domAnimation, m } from 'framer-motion';
import { useRoute } from './engine/router';
import { gameById } from './games/registry';
import Home from './screens/Home';
import Profile from './screens/Profile';
import Shell from './screens/Shell';

export default function App() {
  const [page, id] = useRoute();
  const def = id ? gameById(id) : undefined;
  const key = location.hash;
  let screen = <Home />;
  if (page === 'profile') screen = <Profile />;
  else if ((page === 'play' || page === 'daily') && def?.load) {
    screen = <Shell key={key} def={def} mode={page === 'daily' ? 'daily' : 'solo'} />;
  }
  return (
    // domAnimation only: keeps framer-motion's share of the bundle small
    <LazyMotion features={domAnimation} strict>
      <MotionConfig reducedMotion="user">
        <div className="bg-arcade h-full overflow-hidden">
          <AnimatePresence mode="wait">
            <m.div
              key={page === 'play' || page === 'daily' ? key : page ?? 'home'}
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              exit={{ opacity: 0 }}
              transition={{ duration: 0.15 }}
              className="h-full"
            >
              {screen}
            </m.div>
          </AnimatePresence>
        </div>
      </MotionConfig>
    </LazyMotion>
  );
}
