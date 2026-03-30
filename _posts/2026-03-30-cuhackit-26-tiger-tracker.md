---
title: "CUHackit '26: Building Tiger Tracker"
date: 2026-03-30 12:00:00 -0500
categories: [Projects, Hackathon]
tags: [aws, hackathon, cloud, raspberry pi, react, cuhackit]
description: A writeup of my first hackathon — CUHackit '26 — where my team built Tiger Tracker, a real-time campus occupancy dashboard for Clemson University using AWS, OpenCV, and a Raspberry Pi.
---

I know it is quite late, but a month ago I got the opportunity to attend CUHackit '26, and I had a great time!

This was the first hackathon I have ever been to, and I honestly didn't know what to expect. But I was thoroughly impressed with the event and had a great time competing, and I would love the chance to do it again!

My team, [George Atkinson](https://www.linkedin.com/in/georgeatkinson), [Isaac Rostron](https://www.linkedin.com/in/isaacrostron), and [Rayan Ahmed](https://www.linkedin.com/in/rayanahmed), built "Tiger Tracker." An app that lets you see how busy different locations are on the Clemson campus without ever having to actually be there.

The app used real-time streaming data from a Wi-Fi-enabled camera to detect when people walked in and out of a location, updated that on a dashboard with a map, and persisted the data inside a database. We also built an AI assistant with a curated toolset so you could ask natural language questions like which location is the busiest, get other location-specific data, and pull historical readings to help plan your trip around campus. It was inspired by our shared struggle of busy days on campus, previous experience with hardware, and my goal to win the AWS track.

My main role was to design the entire system using AWS cloud services and implement it. I was happy I finally got to put my certification to good use by picking out and combining several AWS services like Kinesis, DynamoDB, Lambda, API Gateway, Amplify, Cognito, and Bedrock to make the full application. I mean, you might as well try to use everything if they give you a free AWS account 😆

## Breaking it down

There was a Python program that ran on a Raspberry Pi with a webcam plugged into it, which got the latest location data from wherever the camera was assigned. Using OpenCV and some logic, we updated the count based on the direction of travel across a threshold line drawn in the middle of the camera's view. The ML models gave us bounding boxes on detected people, and that line was how we determined whether someone was actually crossing in or out versus just random movement in frame.

We then used Kinesis to stream records in real time generated from the camera. The records had metadata that we could extract and use Lambda functions to insert into DynamoDB. We tracked things like device information, location information, and sensor readings across three tables — locations, devices, and sensor readings.

Then using API Gateway, we exposed a few endpoints that our frontend could hit to get up-to-date information. At each endpoint lived a Lambda function that could retrieve the data without having long-running instances handling requests and responses — the power of serverless! We had endpoints handling things like getting location data, managing devices, polling metrics for locations, a quick one to get the "busyness" of a place, and a special `/chat` for our AI model.

That brings us to Bedrock. We used Claude 3.5 Haiku with a curated toolset to help easily find information from the data without having to sit there and click through different locations, since we figured some people would be using this on mobile. The tools also ensured that if the model couldn't get an answer with its given toolset, it would redirect users to [clemson.edu](https://clemson.edu) for more information. This was especially important to me because we wanted to set up proper guardrails to help mitigate anyone trying to prompt engineer the model.

We also wanted to make sure only certain people could access our app. Cognito is a great solution for something like this — we restricted sign-ups to `@clemson.edu` email addresses only using a pre-signup Lambda, and it issued JWT tokens whenever users logged in so they could access what they needed to. Admins could do things like add new cameras and register them to specific locations using lat/long coordinates.

Lastly, the frontend was written in React with TypeScript and we used Vite for the build system, since we were all pretty familiar with those technologies. We ended up going with the obvious choice, Amplify, to host our site. Since everything on the backend was handled by Lambda functions, we could host only our frontend on Amplify as a SPA and have data get updated with polling every 10 seconds.

---

Overall, a fantastic learning experience! I am looking forward to doing it again next year. A huge shoutout to all of the event organizers, professors, and speakers who attended — it was great hearing the support and insight from folks in the industry. And congrats to everyone who won! I know our team did not, but we had a great time hacking together a solution and making a solid attempt.

The full source is on GitHub if you want to dig into the code: [ty-bennett/tiger-tracker](https://github.com/ty-bennett/tiger-tracker)
