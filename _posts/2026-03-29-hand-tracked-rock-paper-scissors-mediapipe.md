---
title: "Building a Hand-Tracked Rock Paper Scissors Game with MediaPipe"
date: 2026-03-29 12:00:00 -0400
categories: [Projects, AI]
tags: [javascript, mediapipe, computer-vision, ml, webcam, games]
description: A technical writeup of my hand-tracked Rock Paper Scissors project, including how MediaPipe Hands works, how the browser app uses landmarks, and how simple gesture logic turns hand positions into gameplay.
---

I built this project as a simple way to make computer vision interactive. The main experience is a webcam-based Rock Paper Scissors game where you play against a randomized AI opponent, but I also added a second demo where a one-finger pointing gesture controls a Snake game. Both experiences are built around the same idea: let a real-time hand tracking model do the hard perception work, then use lightweight application logic to turn landmarks into game decisions.

At a glance the stack is very small. The UI is plain HTML, CSS, and JavaScript. MediaPipe Hands runs in the browser and provides the 21 hand landmarks on each frame. A tiny Python server is only used to serve the files over `http://localhost`, because webcam APIs are restricted in insecure contexts and browsers will not reliably allow camera access from `file://`.

![Rock Paper Scissors running at Open House](/assets/img/posts/rps-vs-ai/open-house-1.jpg){: .shadow }
_The Rock Paper Scissors demo running live with the detected hand skeleton over the camera feed._

## Why I chose MediaPipe

MediaPipe Hands was the right fit for this project because it solves the hardest part of the problem already: robust real-time hand landmark detection. I did not want to train a custom image classifier, collect gesture data, or build a full tracking pipeline from scratch just to recognize three hand signs. What I actually needed was a fast stream of structured hand coordinates that I could reason about deterministically.

That is the key design choice in this project. The "ML algorithm" is not a custom model I trained for rock, paper, or scissors. Instead, the machine learning portion is MediaPipe's hand detector and landmark model, and my code sits on top of that as a rule-based classifier. Once the model gives me fingertip, knuckle, and wrist positions, classifying a handshape becomes a geometry problem instead of an image classification problem.

MediaPipe also fits the deployment story well. Because it runs client-side in the browser, there is no inference server, no GPU dependency, no backend API for frame uploads, and no privacy concern from shipping webcam frames to a remote service. The browser gets the camera stream, MediaPipe returns landmarks, and the game logic reacts immediately in the same page.

## How the app works end to end

The runtime loop is straightforward:

1. A local Python server serves the static files on `localhost`.
2. The browser asks for webcam permission with `getUserMedia`.
3. MediaPipe Hands processes each incoming video frame.
4. The app receives `multiHandLandmarks` for the detected hand.
5. JavaScript draws the landmark skeleton on a canvas overlay.
6. Gesture logic converts those landmarks into either a throw (`rock`, `paper`, `scissors`) or a pointing direction for Snake.

That Python step is intentionally minimal. The command is just:

```bash
python3 -m http.server 8000
```

There is no Python model server here and no request/response loop between Python and JavaScript. The Python process only hosts the files so the browser can access the webcam in a secure-enough local context. All of the hand tracking and game logic happens client-side.

## How MediaPipe landmarks become gestures

MediaPipe Hands returns 21 normalized landmarks for each detected hand. These landmarks include the wrist, finger MCP joints, PIP joints, DIP joints, and fingertips. In practice, that gives the app enough information to infer whether each finger is extended or folded.

The helper that everything depends on is `isFingerExtended(...)` in [`app.js`](/Users/tybennett/Developer/projects/rps-vs-ai/app.js:210). The function compares the distance from the fingertip to the wrist against the distances from the intermediate joints to the wrist:

```js
function isFingerExtended(landmarks, tipIdx, pipIdx, mcpIdx) {
  const wrist = landmarks[0];
  const tip = landmarks[tipIdx];
  const pip = landmarks[pipIdx];
  const mcp = landmarks[mcpIdx];
  const tipToWrist = distance(tip, wrist);
  const pipToWrist = distance(pip, wrist);
  const mcpToWrist = distance(mcp, wrist);
  return tipToWrist > pipToWrist * 1.08 && pipToWrist > mcpToWrist * 0.95;
}
```

The logic is simple but effective. If a finger is extended, the fingertip should be farther from the wrist than the PIP joint, and the PIP joint should be at least slightly farther than the MCP joint. The extra multipliers act as loose thresholds so the app is less sensitive to small landmark jitter.

Once each finger has been reduced to a boolean, gesture classification is just a few rules inside [`classifyGesture(...)`](/Users/tybennett/Developer/projects/rps-vs-ai/app.js:221):

- `scissors`: index and middle fingers extended, ring and pinky folded
- `paper`: at least four fingers extended, including index, middle, ring, and pinky
- `rock`: zero or one finger extended, with index and middle folded

This is a useful hybrid approach. The ML model handles the messy computer vision problem. The application logic handles the domain-specific interpretation.

## Why the gesture logic uses history instead of a single frame

Real-time landmarks are noisy. Even with a good model, hand position changes slightly from frame to frame because of motion blur, lighting, occlusion, and tracking jitter. If the game decided the user's throw from only one frame, it would misclassify handshapes too often.

To make the interaction more stable, the Rock Paper Scissors game stores a rolling history of recent gesture predictions and computes two things from it:

- a visible confidence score, based on the most common gesture in the recent window
- a stable throw, based on the most common gesture in the last ten samples with a minimum count threshold

That logic lives in [`getGestureConfidence()`](/Users/tybennett/Developer/projects/rps-vs-ai/app.js:72) and [`getStableUserChoice()`](/Users/tybennett/Developer/projects/rps-vs-ai/app.js:263). During a round, the game clears gesture history at "Shoot", captures a short post-shoot window, and then resolves the round using the dominant gesture from that period. That timing detail matters because it keeps the countdown animation separate from the actual throw capture window.

The result is that the user experience feels much less twitchy. The app is not asking, "What was the handshape on one exact frame?" It is asking, "What handshape was consistently visible during the short decision window after Shoot?"

![Gesture confidence and game state during a round](/assets/img/posts/rps-vs-ai/open-house-2.jpg){: .shadow }
_The confidence meter and recent-frame smoothing help the game wait for a stable throw instead of reacting to a single noisy frame._

## How the Rock Paper Scissors round logic works

The actual opponent is intentionally simple: the AI chooses randomly from `rock`, `paper`, or `scissors`. There is no adaptive strategy model here. That is deliberate, because the interesting technical work in this project is on the vision side, not on opponent optimization.

The round flow in [`app.js`](/Users/tybennett/Developer/projects/rps-vs-ai/app.js:324) looks like this:

1. Initialize the webcam and MediaPipe camera loop.
2. Start a countdown: Rock, Paper, Scissors, Shoot.
3. On "Shoot", clear old gesture history.
4. Collect gesture samples for a short window.
5. Pick the most stable user throw from the sample history.
6. Compare it against the AI's random choice.
7. Update the overlay, round result, and best-of-five scoreboard.

That separation between perception, stabilization, and game rules keeps the code manageable. MediaPipe handles perception. The history buffers handle stabilization. The game loop handles the actual match logic.

## How the same landmarks drive the Snake demo

The Snake game reuses the same core hand tracking setup, but instead of classifying three discrete gestures it extracts a direction vector from a one-finger pointing pose. The app first checks that only the index finger is extended. If the middle, ring, or pinky fingers are also extended, the pose is rejected so casual open-hand motion does not accidentally steer the snake.

From there, [`detectPointDirection(...)`](/Users/tybennett/Developer/projects/rps-vs-ai/snake.js:364) computes a vector from the index MCP joint to the index fingertip. If horizontal movement dominates, the game maps the vector to left or right. If vertical movement dominates, it maps to up or down. A small minimum magnitude threshold rejects tiny or ambiguous motions.

The Snake input loop then applies another smoothing layer:

- keep a short direction history
- require a minimum number of matching samples before accepting a turn
- add a cooldown between hand-driven turns
- prevent instant reversal into the snake's own body

This is a good example of how landmarks can power very different interfaces. In Rock Paper Scissors, landmarks become a handshape label. In Snake, the same landmarks become a direction controller.

## What I like about this architecture

The biggest advantage is that the system stays understandable. There is no opaque end-to-end gesture classifier deciding game outcomes from pixels. Instead, the pipeline is decomposed into clear steps:

- webcam frame in
- landmarks out
- geometric finger-state checks
- temporal smoothing
- game action

That makes the project easier to debug, easier to demo, and easier to teach. If tracking fails, I can inspect the hand skeleton. If classification fails, I can inspect the extension thresholds. If controls feel jittery, I can tune the history window or cooldown values. Each layer has a visible purpose.

It also scales well for small interaction experiments. Once you have reliable landmarks in the browser, you can keep adding new gesture-driven mechanics without changing the underlying ML model at all.

![Finger-controlled Snake using the same hand tracking pipeline](/assets/img/posts/rps-vs-ai/open-house-3.jpg){: .shadow }
_The Snake mode reuses the same MediaPipe pipeline, but interprets landmarks as pointing directions instead of rock-paper-scissors throws._

---

This project ended up being a good reminder that you do not always need a custom-trained model to build something that feels intelligent. In many cases, the right architecture is to let a strong real-time vision model extract structure from the scene, then build small, explicit logic on top of it. That is exactly what MediaPipe made possible here.
