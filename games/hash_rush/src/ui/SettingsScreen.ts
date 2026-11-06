import type { QualitySetting, Settings } from '../core/GameState';
import { button, h, type ScreenView } from './dom';

export class SettingsScreen implements ScreenView {
  readonly el: HTMLElement;
  private readonly body = h('div.settings');

  constructor(private readonly onChange: (settings: Settings) => void, onBack: () => void, private readonly info: () => string) {
    this.el = h('div.screen.panel-screen.dim', null, h('div.panel.narrow', null, h('div.panel-head', null, h('h2.title', null, 'Settings'), button('✕', 'close', onBack)), this.body));
  }

  refresh(settings: Settings): void {
    const toggle = (label: string, key: 'music' | 'sfx' | 'haptics') => {
      const sw = h(`button.switch${settings[key] ? '.on' : ''}` as 'button', { type: 'button', role: 'switch', ariaChecked: String(settings[key]) }, h('i'));
      sw.onclick = () => {
        settings[key] = !settings[key];
        this.onChange(settings);
        this.refresh(settings);
      };
      return h('div.setting', null, h('span', null, label), sw);
    };
    const qualities: QualitySetting[] = ['auto', 'low', 'medium', 'high'];
    const seg = h('div.segmented');
    for (const q of qualities) {
      const b = h(`button${settings.quality === q ? '.on' : ''}` as 'button', { type: 'button' }, q.toUpperCase());
      b.onclick = () => {
        settings.quality = q;
        this.onChange(settings);
        this.refresh(settings);
      };
      seg.append(b);
    }
    this.body.replaceChildren(
      toggle('Music', 'music'),
      toggle('Sound effects', 'sfx'),
      toggle('Vibration', 'haptics'),
      h('div.setting.col', null, h('span', null, 'Graphics'), seg),
      h('div.note', null, this.info()),
    );
  }
}
