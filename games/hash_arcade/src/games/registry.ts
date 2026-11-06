import { hashString, todayKey } from '../engine/rng';
import type { Category, GameDef } from '../engine/types';

export const CATEGORIES: { id: Category; name: string }[] = [
  { id: 'observation', name: 'Observation' },
  { id: 'math', name: 'Mathematics' },
  { id: 'memory', name: 'Memory' },
  { id: 'reflex', name: 'Reflexes' },
  { id: 'logic', name: 'Logic' },
  { id: 'words', name: 'Words' },
];

// the app's GameColors palette, so tiles sit next to the Ludo art
const NEON = '#2fbf3a';
const VOLT = '#2e9bff';
const PINK = '#ff3e8e';
const GOLD = '#ffb81a';
const VIOLET = '#6a4df0';
const ORANGE = '#ff6f61';

// Built games first in each category; the rest are listed as coming soon.
export const GAMES: GameDef[] = [
  {
    id: 'odd_one_out', name: 'Odd One Out', category: 'observation', glyph: 'Ö', accent: NEON,
    blurb: 'One different. Find it fast.',
    howTo: ['Tap the one character that differs from the rest.', 'Right: +2s. Wrong: −3s.', 'Grids grow every two levels.'],
    duration: 30, combo: true, par: 6000,
    load: () => import('./odd_one_out'),
  },
  {
    id: 'color_clash', name: 'Color Clash', category: 'observation', glyph: 'Aa', accent: PINK,
    blurb: 'Name the ink, not the word.',
    howTo: ['Pick the colour the word is painted in, not what it says.', 'Right: +1s. Wrong: −2s.', 'Keys 1–6 pick buttons.'],
    duration: 30, combo: true, par: 5000,
    load: () => import('./color_clash'),
  },
  { id: 'spot_difference', name: 'Spot the Difference', category: 'observation', glyph: '≠', accent: VOLT, blurb: 'Find what changed.', howTo: ['Two pictures, a few changes. Tap a changed spot in either one.', 'Colour swaps, new shapes, things missing.', 'Wrong tap: −2s.'], duration: 60, combo: true, par: 5000, load: () => import('./spot_difference') },
  { id: 'find_number', name: 'Find the Number', category: 'observation', glyph: '#7', accent: GOLD, blurb: 'Locate the target number.', howTo: ['Find the target number in the grid.', 'Look-alikes (swapped digits, ±1) get more common.', 'Right: +1.5s. Wrong: −2s.'], duration: 30, combo: true, par: 4000, load: () => import('./find_number') },
  { id: 'symbol_hunt', name: 'Symbol Hunt', category: 'observation', glyph: '✦', accent: VIOLET, blurb: 'Hunt the symbol.', howTo: ['Tap every copy of the target symbol.', 'Its look-alike cousins fill the rest.', 'Wrong: −2s.'], duration: 45, combo: true, par: 5000, load: () => import('./symbol_hunt') },
  { id: 'shape_match', name: 'Shape Match', category: 'observation', glyph: '◆', accent: ORANGE, blurb: 'Match the shapes.', howTo: ['Exactly two shapes are identical: same shape, colour and turn.', 'Tap one, then its twin.', 'Wrong pair: −3s.'], duration: 45, combo: true, par: 3000, load: () => import('./shape_match') },
  { id: 'count_objects', name: 'Count the Objects', category: 'observation', glyph: '∴', accent: NEON, blurb: 'Count what flashed.', howTo: ['Shapes flash for a moment. Count the one asked for.', 'Fewer flashes, more shapes as you go.', '3 lives.'], lives: 3, combo: true, par: 3500, load: () => import('./count_objects') },
  { id: 'mirror_match', name: 'Mirror Match', category: 'observation', glyph: 'ᴙ', accent: VOLT, blurb: 'Spot the true mirror.', howTo: ['Pick the true mirror image (flipped left to right).', 'The others are just turned, not flipped.', 'Wrong: −3s.'], duration: 45, combo: true, par: 3500, load: () => import('./mirror_match') },
  { id: 'hidden_object', name: 'Hidden Object', category: 'observation', glyph: '⌕', accent: PINK, blurb: 'Find it in the crowd.', howTo: ['Find the one symbol in the crowd.', 'The crowd grows every round.', 'Wrong tap: −2s.'], duration: 45, combo: true, par: 3000, load: () => import('./hidden_object') },
  { id: 'visual_rush', name: 'Visual Search Rush', category: 'observation', glyph: '◎', accent: GOLD, blurb: 'Search after search.', howTo: ['Back-to-back searches: odd colour, odd character, target number.', 'Colours get closer as you go.', 'Right: +1.5s. Wrong: −2s.'], duration: 45, combo: true, par: 5000, load: () => import('./visual_rush') },

  {
    id: 'math_blitz', name: 'Math Blitz', category: 'math', glyph: '±', accent: VOLT,
    blurb: 'Rapid-fire arithmetic.',
    howTo: ['Type the answer; it checks itself once all digits are in.', 'Right: +1s. Wrong: −3s.', 'Sums turn into products, divisions and two-step problems.'],
    duration: 45, combo: true, par: 4000,
    load: () => import('./math_blitz'),
  },
  {
    id: 'greater_smaller', name: 'Greater or Smaller', category: 'math', glyph: '<>', accent: GOLD,
    blurb: 'Which side wins?',
    howTo: ['Tap the side the prompt asks for: greater or smaller.', 'Numbers become decimals, fractions and products.', 'Keys ← and →.'],
    duration: 30, combo: true, par: 4000,
    load: () => import('./greater_smaller'),
  },
  {
    id: 'number_sequence', name: 'Number Sequence', category: 'math', glyph: '…', accent: VIOLET,
    blurb: 'Find the missing term.',
    howTo: ['Work out the rule and type the missing number.', 'Rules: steps, doubling, squares, Fibonacci, interleaved runs.', 'Right: +2s. Wrong: −5s.'],
    duration: 60, combo: true, par: 2500,
    load: () => import('./number_sequence'),
  },
  { id: 'cross_math', name: 'Cross Math', category: 'math', glyph: '✚', accent: NEON, blurb: 'Interlocking equations.', howTo: ['Fill the blanks so every row and column adds up.', 'Tap a blank, type, then OK.', 'More blanks and × later. Wrong: −3s.'], duration: 90, combo: true, par: 3500, load: () => import('./cross_math') },
  { id: 'kenken', name: 'KenKen', category: 'math', glyph: '⊞', accent: PINK, blurb: 'Arithmetic cages.', howTo: ['Each row and column holds every number once.', 'Each cage must hit its number using its sign.', 'Solve: +60s.'], duration: 180, par: 2000, load: () => import('./kenken') },
  { id: 'math_maze', name: 'Math Maze', category: 'math', glyph: '⌗', accent: ORANGE, blurb: 'Path to the target.', howTo: ['Move right or down from the top-left corner.', 'Each cell changes your total. End on the target.', 'Undo freely. Wrong finish: −3s.'], duration: 90, combo: true, par: 2500, load: () => import('./math_maze') },
  { id: 'missing_operator', name: 'Missing Operator', category: 'math', glyph: '?', accent: VOLT, blurb: 'Fill in the signs.', howTo: ['Fill in + − × ÷ to make the equation true.', '× and ÷ are worked out before + and −.', 'Wrong: −3s.'], duration: 60, combo: true, par: 3500, load: () => import('./missing_operator') },
  { id: 'make_24', name: 'Make 24', category: 'math', glyph: '24', accent: GOLD, blurb: 'Four numbers, one 24.', howTo: ['Combine all four numbers to make exactly 24.', 'Pick a number, a sign, another number. Fractions allowed.', 'Solve: +20s. Skip: −10s.'], duration: 120, combo: true, par: 2500, load: () => import('./make_24') },
  { id: 'arithmetic_chain', name: 'Arithmetic Chain', category: 'math', glyph: '→', accent: VIOLET, blurb: 'Keep the running total.', howTo: ['A start number, then steps one at a time.', 'Keep the running total in your head.', 'Longer and faster chains. 3 lives.'], lives: 3, combo: true, par: 2500, load: () => import('./arithmetic_chain') },
  { id: 'number_target', name: 'Number Target', category: 'math', glyph: '◉', accent: NEON, blurb: 'Hit the target number.', howTo: ['Combine numbers to hit the target exactly.', 'Whole numbers only; you needn\'t use them all.', 'Fewer steps score more.'], duration: 120, combo: true, par: 2500, load: () => import('./number_target') },

  {
    id: 'memory_flash', name: 'Memory Flash', category: 'memory', glyph: '▦', accent: NEON,
    blurb: 'Remember the lit cells.',
    howTo: ['Cells light up, then go dark. Tap every one that lit.', 'A wrong tap costs a life; 3 lives.', 'More cells and bigger grids each round.'],
    lives: 3, combo: true, par: 3000,
    load: () => import('./memory_flash'),
  },
  {
    id: 'simon_says', name: 'Simon Says', category: 'memory', glyph: '◕', accent: PINK,
    blurb: 'Repeat the pattern.',
    howTo: ['Watch the pads light up, then repeat the order.', 'One more step every round, played faster.', 'One mistake ends the run. Keys 1–4.'],
    lives: 1, par: 1500,
    load: () => import('./simon_says'),
  },
  { id: 'card_pairs', name: 'Card Pair Match', category: 'memory', glyph: '❐', accent: VOLT, blurb: 'Match hidden pairs.', howTo: ['Flip two cards at a time to find matching pairs.', 'Clear the board for bonus time and a bigger board.', 'Fewer misses, bigger combo.'], duration: 90, combo: true, par: 3500, load: () => import('./card_pairs') },
  { id: 'number_recall', name: 'Number Recall', category: 'memory', glyph: '123', accent: GOLD, blurb: 'Hold the digits.', howTo: ['Memorise the digits, then type them back.', 'One more digit each time you get it right.', '3 lives.'], lives: 3, par: 1500, load: () => import('./number_recall') },
  { id: 'sequence_recall', name: 'Sequence Recall', category: 'memory', glyph: '⋯', accent: VIOLET, blurb: 'Repeat the symbols.', howTo: ['Symbols flash one by one. Tap them in the same order.', 'The pad reshuffles every round.', '3 lives.'], lives: 3, par: 1500, load: () => import('./sequence_recall') },
  { id: 'flash_anzan', name: 'Flash Anzan', category: 'memory', glyph: 'Σ', accent: ORANGE, blurb: 'Add the flashes.', howTo: ['Numbers flash one at a time. Add them in your head.', 'More numbers, more digits, faster flashes.', '3 lives.'], lives: 3, par: 2500, load: () => import('./flash_anzan') },
  { id: 'position_memory', name: 'Position Memory', category: 'memory', glyph: '⊡', accent: NEON, blurb: 'Where was it?', howTo: ['Remember where each symbol sits.', 'Then tap where each one asked for was.', '3 lives.'], lives: 3, par: 2500, load: () => import('./position_memory') },
  { id: 'word_recall', name: 'Word Recall', category: 'memory', glyph: 'Ww', accent: PINK, blurb: 'Remember the words.', howTo: ['Memorise the list of words.', 'Then say SEEN or NEW for each word shown.', 'Lists grow. 3 lives. Keys ← and →.'], lives: 3, combo: true, par: 2500, load: () => import('./word_recall') },
  { id: 'n_back', name: 'N-Back', category: 'memory', glyph: 'N', accent: VOLT, blurb: 'Did that match before?', howTo: ['Tap MATCH when the letter equals the one N steps back.', 'Three blocks: 1-back, 2-back, 3-back.', 'Space bar works too.'], combo: true, par: 2500, load: () => import('./n_back') },
  { id: 'pattern_replay', name: 'Pattern Replay', category: 'memory', glyph: '◫', accent: GOLD, blurb: 'Rebuild the pattern.', howTo: ['Remember the pattern, then rebuild it.', 'Later patterns use two or three colours: tap to cycle.', '3 lives.'], lives: 3, combo: true, par: 2500, load: () => import('./pattern_replay') },

  {
    id: 'reaction_timer', name: 'Reaction Timer', category: 'reflex', glyph: 'GO', accent: GOLD,
    blurb: 'Wait for green.',
    howTo: ['Wait for the screen to turn green, then tap as fast as you can.', 'Tapping early is a foul and the try is redone.', 'Five tries; faster taps score more.'],
    par: 3500,
    load: () => import('./reaction_timer'),
  },
  {
    id: 'precision_stop', name: 'Precision Stop', category: 'reflex', glyph: '[ ]', accent: VOLT,
    blurb: 'Stop it in the zone.',
    howTo: ['Tap (or Space) to stop the marker inside the zone.', 'Closer to the centre scores more.', 'Zones shrink and speed rises. 3 lives.'],
    lives: 3, combo: true, par: 4000,
    load: () => import('./precision_stop'),
  },
  { id: 'reflex_rush', name: 'Reflex Rush', category: 'reflex', glyph: '●', accent: NEON, blurb: 'Tap before it vanishes.', howTo: ['Tap each target before it shrinks away.', 'Every hit makes the next one smaller and faster.', 'A target that escapes costs a life; 3 lives.'], lives: 3, combo: true, par: 4000, load: () => import('./reflex_rush') },
  { id: 'aim_trainer', name: 'Aim Trainer', category: 'reflex', glyph: '⌖', accent: PINK, blurb: 'Small targets, fast.', howTo: ['Hit 25 targets as fast and cleanly as you can.', 'Faster hits score more; a missed tap breaks your combo.', 'Targets shrink as you go.'], combo: true, par: 6000, load: () => import('./aim_trainer') },
  { id: 'tap_frenzy', name: 'Tap Frenzy', category: 'reflex', glyph: '✺', accent: ORANGE, blurb: 'Tap them all.', howTo: ['Pop as many bubbles as you can in 20 seconds.', 'Gold bubbles are worth triple.'], duration: 20, combo: true, par: 2500, load: () => import('./tap_frenzy') },
  { id: 'whack_mole', name: 'Whack-a-Mole', category: 'reflex', glyph: '⊕', accent: VIOLET, blurb: 'Hit, avoid decoys.', howTo: ['Whack the moles before they duck.', 'Red bombs appear later: hitting one costs 3s.', 'An escaped mole breaks your combo.'], duration: 45, combo: true, par: 4500, load: () => import('./whack_mole') },
  { id: 'dodge_rush', name: 'Dodge Rush', category: 'reflex', glyph: '⇄', accent: VOLT, blurb: 'Dodge everything.', howTo: ['Tap the left or right half (or ← →) to switch lanes.', 'Dodge the falling blocks; it speeds up.', '3 lives.'], lives: 3, par: 1500, load: () => import('./dodge_rush') },
  { id: 'quick_draw', name: 'Quick Draw', category: 'reflex', glyph: '!', accent: GOLD, blurb: 'Draw on the signal.', howTo: ['Tap only when the screen says DRAW!', 'Fake words try to trick you: tapping on them is a foul.', '8 rounds; faster draws score more.'], par: 5000, load: () => import('./quick_draw') },
  { id: 'moving_target', name: 'Moving Target', category: 'reflex', glyph: '➶', accent: NEON, blurb: 'Track and hit.', howTo: ['Tap the targets as they bounce around.', 'More targets, moving faster, as you score.', 'A missed tap breaks your combo.'], duration: 30, combo: true, par: 4000, load: () => import('./moving_target') },
  { id: 'rhythm_tap', name: 'Rhythm Tap', category: 'reflex', glyph: '♪', accent: PINK, blurb: 'Tap on the beat.', howTo: ['Tap as each note crosses the line.', 'Perfect timing: 100. Good: 50.', 'One 32-beat track; off-beat notes join later.'], combo: true, par: 6000, load: () => import('./rhythm_tap') },

  {
    id: 'lights_out', name: 'Lights Out', category: 'logic', glyph: '◐', accent: GOLD,
    blurb: 'Switch the whole grid off.',
    howTo: ['Tapping a light flips it and its four neighbours.', 'Turn every light off. Fewer moves score more.', 'Each solve adds 15s; grids grow from 3×3 to 5×5.'],
    duration: 90, par: 2500,
    load: () => import('./lights_out'),
  },
  { id: 'mini_sudoku', name: 'Mini Sudoku', category: 'logic', glyph: '6', accent: NEON, blurb: 'Small grid Sudoku.', howTo: ['Fill the grid so every row, column and box has each number once.', '4×4 grids first, then 6×6.', 'Every puzzle has exactly one answer.'], duration: 240, par: 2500, load: () => import('./mini_sudoku') },
  { id: 'twenty48', name: '2048', category: 'logic', glyph: '2K', accent: ORANGE, blurb: 'Merge the tiles.', howTo: ['Swipe (or arrow keys) to slide every tile.', 'Matching tiles merge; merges score their value.', 'Ends when no move is left.'], par: 6000, load: () => import('./twenty48') },
  { id: 'minesweeper', name: 'Minesweeper', category: 'logic', glyph: '✱', accent: PINK, blurb: 'Clear without a boom.', howTo: ['Tap to open a square; numbers count the mines touching it.', 'Use flag mode to mark mines. The first tap is always safe.', '3 lives.'], lives: 3, par: 2000, load: () => import('./minesweeper') },
  { id: 'nonogram', name: 'Nonogram', category: 'logic', glyph: '▤', accent: VOLT, blurb: 'Picture from clues.', howTo: ['Numbers are the runs of filled squares in each row and column.', 'Tap squares to fill them until every clue matches.'], duration: 240, par: 3000, load: () => import('./nonogram') },
  { id: 'sliding_puzzle', name: 'Sliding Puzzle', category: 'logic', glyph: '⇅', accent: VIOLET, blurb: 'Slide into order.', howTo: ['Slide tiles into the gap to put them in order.', '3×3 first, then 4×4. Fewer moves score more.'], duration: 240, par: 1500, load: () => import('./sliding_puzzle') },
  { id: 'mastermind', name: 'Mastermind', category: 'logic', glyph: '●○', accent: GOLD, blurb: 'Crack the code.', howTo: ['Guess the 4-colour code in 10 tries.', '● = right colour, right place. ○ = right colour, wrong place.', 'Colours can repeat. 3 lives.'], lives: 3, par: 2000, load: () => import('./mastermind') },
  { id: 'hanoi', name: 'Tower of Hanoi', category: 'logic', glyph: '≡', accent: NEON, blurb: 'Move the tower.', howTo: ['Move the whole tower to the right-hand peg.', 'One disk at a time, never a bigger disk on a smaller one.', 'Fewer moves score more.'], duration: 240, par: 2000, load: () => import('./hanoi') },
  { id: 'connect_dots', name: 'Connect the Dots', category: 'logic', glyph: '⟿', accent: PINK, blurb: 'Link without crossing.', howTo: ['Drag from a dot to its matching colour.', 'Paths can\'t cross or share a square.', 'More pairs on bigger boards.'], duration: 180, combo: true, par: 2500, load: () => import('./connect_dots') },
  { id: 'logic_grid', name: 'Logic Grid', category: 'logic', glyph: '∵', accent: VOLT, blurb: 'Deduce who did what.', howTo: ['Use the clues to work out who plays what and eats what.', 'Tap a box to cycle the options, then CHECK.', 'Wrong answer: −10s.'], duration: 240, par: 2500, load: () => import('./logic_grid') },

  { id: 'word_scramble', name: 'Word Scramble', category: 'words', glyph: 'Ab', accent: NEON, blurb: 'Unscramble it.', howTo: ['Tap the letters in order to unscramble the word.', 'Any real word using all the letters counts.', 'Skip: −5s.'], duration: 60, combo: true, par: 3000, load: () => import('./word_scramble') },
  { id: 'word_search', name: 'Word Search', category: 'words', glyph: 'W', accent: VOLT, blurb: 'Find the words.', howTo: ['Drag across a word in the grid to find it.', 'Later grids hide words backwards and diagonally.'], duration: 120, par: 3000, load: () => import('./word_search') },
  { id: 'word_ladder', name: 'Word Ladder', category: 'words', glyph: '↑', accent: GOLD, blurb: 'One letter at a time.', howTo: ['Change one letter at a time to reach the target word.', 'Every step must be a real word.', 'Match the best number of steps for full points.'], duration: 150, par: 1500, load: () => import('./word_ladder') },
  { id: 'typing_sprint', name: 'Typing Sprint', category: 'words', glyph: '⌨', accent: PINK, blurb: 'Type it right, fast.', howTo: ['Type each word as fast as you can.', 'Wrong letters are refused and break your combo.', 'Words get longer.'], duration: 60, combo: true, par: 3500, load: () => import('./typing_sprint') },
  { id: 'missing_letter', name: 'Missing Letter', category: 'words', glyph: '_', accent: VIOLET, blurb: 'Fill the gap.', howTo: ['Type the missing letter(s) to make a word.', 'Any real word that fits counts.', 'Two and three gaps later. Wrong: −3s.'], duration: 60, combo: true, par: 3500, load: () => import('./missing_letter') },
  { id: 'anagram_rush', name: 'Anagram Rush', category: 'words', glyph: '⟲', accent: ORANGE, blurb: 'Same letters, new word.', howTo: ['Make as many words as you can from the letters.', '3+ letters; longer words score much more.'], duration: 90, par: 2500, load: () => import('./anagram_rush') },
  { id: 'five_letter', name: 'Five-Letter Guess', category: 'words', glyph: '5', accent: NEON, blurb: 'Guess the word.', howTo: ['Guess the 5-letter word in 6 tries.', 'Green: right spot. Yellow: in the word, wrong spot.', 'Solve as many as you can. 3 lives.'], lives: 3, par: 1500, load: () => import('./five_letter') },
  { id: 'category_rush', name: 'Category Rush', category: 'words', glyph: '⊂', accent: VOLT, blurb: 'Does it belong?', howTo: ['Does the word belong to the category?', 'The category changes every 6 words.', 'Keys ← and →. Wrong: −3s.'], duration: 45, combo: true, par: 4500, load: () => import('./category_rush') },
  { id: 'spelling_blitz', name: 'Spelling Blitz', category: 'words', glyph: '✓', accent: GOLD, blurb: 'Pick the right spelling.', howTo: ['Tap the correctly spelled word.', 'The traps are real-looking typos.', 'Wrong: −3s.'], duration: 45, combo: true, par: 4000, load: () => import('./spelling_blitz') },
  { id: 'word_chain', name: 'Word Chain', category: 'words', glyph: '∞', accent: PINK, blurb: 'Chain the words.', howTo: ['Each word must start with the last letter of the one before.', 'No repeats. Longer words score more and add time.'], duration: 60, combo: true, par: 2500, load: () => import('./word_chain') },
];

export const PLAYABLE = GAMES.filter((g) => g.load);
export const gameById = (id: string) => GAMES.find((g) => g.id === id);

/** Today's three daily games, the same for everyone. */
export function dailyGames(date = todayKey()): GameDef[] {
  const start = hashString(date) % PLAYABLE.length;
  return [0, 1, 2].map((i) => PLAYABLE[(start + i * 3) % PLAYABLE.length]);
}

export const dailySeed = (gameId: string, date = todayKey()) => hashString(`${date}:${gameId}`);
