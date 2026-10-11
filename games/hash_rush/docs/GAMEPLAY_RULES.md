# Gameplay rules

## Loop
The cannon advances on its own (3.4 m/s), slides left/right under the player's control and fires on a timer.
It stops while enemies are within ~11 m, and parks 17 m short of the boss. **Win:** the boss dies.
**Lose:** the cannon's 100 HP reach zero (enemies that reach it, turret shells, boss projectiles).
Having zero units is *not* a loss — the cannon keeps firing.

## Pods vs units
- A **pod** is the cannon's projectile. It flies 6.5 m and lands, deploying exactly **one unit**.
- A pod that strikes an enemy, barrel or boss first deals *Cannon Power* damage and deploys nothing.
- A pod never flies through a gate: it lands just in front of it and the unit walks through.
- **Units** run ahead (9 m/s) but hold formation at most 24 m in front of the cannon. The formation is centred on the
  cannon, so steering the cannon steers the army — into the better gate, around traps, out of boss attacks.

## Gates
| Gate | Rule |
| --- | --- |
| ×k (2, 3, 5, 10, 100) | Every unit that walks through becomes k units. Applies to every unit, every time. |
| +n (1, 5, 10, 25) | Pays a flat n units when a unit walks through, then recharges for 2.5 s (the pane refills from the bottom). Paying +n *per unit* would make "+10" a ×11. |

| ÷k (bad) | Keeps exactly one unit in every k that walk through. |
| −n (bad) | Destroys a flat n units, then recharges for 2.5 s like a +n gate. |

**Funnel:** when the cannon is lined up with a gate, the whole army squeezes through that gate. Without this a wide
army would spill into the neighbouring gate however you steered, and a bad gate could not be avoided. Bad gates appear
from level 3, never move, and are never the only gate in their row. They earn no score.

Output is clipped by the **population cap of 5,000 units**. When that happens the HUD shows `ARMY MAX` and the count
badge turns gold; gate values are never altered. At most 24 new agents appear per activation (spawn budget).

## Logical units vs rendered units
The game counts *units*; it simulates and draws *agents*. An agent has a `strength` = how many units it stands for.

- Up to **600 agents** exist. Until that budget is spent, 1 agent = 1 unit.
- Beyond it, new units are added to existing agents' strength. A strength-s agent has s× the hit points and deals s×
  the damage, loses whole units as its pool drains, is drawn larger (`1 + 0.28·log2(s)`, max 2.6×) and brighter.
- The HUD count is always the exact sum of strengths (`CrowdSystem.count`) — it is the number combat uses.

So 5,000 units = 600 instances in one draw call, and nothing about the displayed number is cosmetic.

## Combat
Aggregate and continuous. In contact, an agent deals `strength × unitDamage` per second; the enemy deals
`dps / √attackers` per second to each agent on it. Nearest-enemy lookups go through a uniform grid rebuilt each tick.
At most 36 agents can be in melee with a boss at once; the rest queue.

| Enemy | HP | DPS | Notes |
| --- | --- | --- | --- |
| Grunt | 18 | 7 | fast |
| Brute | 80 | 16 | |
| Giant | 520 | 46 | slow, 2.7× size |
| Turret | 130 | 18/shot | static, shells units (1.1 m splash) or the cannon, every 1.5 s |

HP and damage scale with the level (`difficulty()` in `LevelGenerator.ts`).

## Traps
| Trap | Collision / damage | Warning |
| --- | --- | --- |
| Moving wall | Kills units it sweeps over | hazard stripes, red lane |
| Rotating blade | Kills units touching either arm | red ring = reach |
| Crusher | Kills units under the head when it slams | pad flashes amber before, red during |
| Laser | Kills units crossing while on | flickering beam + amber line before it fires |
| Narrow bridge | Units off the deck fall. The army files across only if the cannon is lined up with it | blue guide strip, beacons |
| Falling platform | Shakes for 1.3 s after the first unit steps on, then drops for good | hazard-striped slab |
| Explosive barrel | Set off by a pod, a unit or another barrel. 3.4 m vs enemies, 2 m vs your units | pulsing ring |
| Turret | see above | — |
| Moving gate | A gate that slides across the track | — |

## Bosses
All attacks are drawn on the ground before they land (the fill reaches the rim on impact). Below 30 % HP a boss
attacks 30 % faster. After 50 s of fighting it overloads and every cast also hits the cannon — fights always end.

- **Iron Titan** — slam (3 m circle on your units), boulder (aimed at the cannon: dodge), stomp (two half-track strips).
- **Inferno Guardian** — flame (burns one half of the track), twin fireballs at the cannon, summons grunts.
- **Void Commander** — three orbs walking across the cannon's position, a beam down its own column, blink (teleports and raises a shield worth 10 % HP), summons.

## Upgrades
Fire rate, starting army, unit damage, unit armor, cannon power, Overdrive cooldown (Overdrive = 3× fire rate for 4 s).
Every one feeds `computeStats()`, which is the only thing the simulation reads. Costs and values: `src/gameplay/Upgrades.ts`.

## Score and rewards
Kills + gate activations; on a win also boss bonus, surviving army, cannon HP and time under par. Capped at 20,000 per
level. Stars: 3 at ≥75 % cannon HP, 2 at ≥40 %, else 1. The leaderboard value is the **career score** (sum of
per-level bests, ≤ 600,000). Upgrades and skins are bought with the host's currency (HashCoins in the
app); the game has no currency of its own and playing does not earn any.

## Endless mode
Unlocks after level 5. Generated stages back to back (stage k = campaign difficulty 4 + 2k), each ending in a boss.
Between stages the cannon is repaired by 25 HP and up to 120 survivors carry over. The run ends when the cannon dies;
quitting banks the stages already cleared. Score is the sum of stage scores; the best run (capped at 200,000) is part
of the career score.

## Continue
On defeat (campaign or endless) the host may sell one continue per run. The cannon returns at 60 HP with a 3 s shield
and a shockwave destroys every enemy within 16 m; progress, army and score are kept. In the Hash app it costs
1,000 HashCoins (`MiniGameCoins.hashRushContinue`), charged by the app. **Try Again is always free.**

## Skins
Six colourways each for the army and the cannon, bought with HashCoins at the app's prices (currently 0 / 150 / 300 / 500 / 800 / 1,200) and equipped
separately. Purely cosmetic: a skin shifts the model's colours in HSL and recolours its lights. None is red.
