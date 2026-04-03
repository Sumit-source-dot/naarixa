# Safety Data Notes (Punjab Route Module)

This document explains how route, fare, ETA, and safety values are derived in the Punjab safety module.

## 1. Route Data (NH44 Backbone)

Primary modeled corridor:

- Chandigarh -> Ludhiana -> Jalandhar -> Amritsar

Route basis:

- National Highway 44 (NH44), a major intercity corridor in Punjab
- Commonly reflected across Google Maps, cab aggregators, and logistics routes

Suggested project statement:

"The route graph is modeled on NH44, the primary transport backbone connecting major Punjab cities."

## 2. Distance Data

Representative intercity distances:

- Chandigarh -> Ludhiana: ~100 km
- Ludhiana -> Jalandhar: ~60 km
- Jalandhar -> Amritsar: ~80 km

Distance source logic:

- Approximated from real road navigation estimates (Google Maps and cab platforms)

Suggested project statement:

"Distances are approximated from real-world navigation services and intercity cab estimates."

## 3. Fare Calculation

Code parameter:

```dart
const ratePerKm = 12;
```

Rationale:

- Typical intercity taxi band in India is roughly Rs 10-Rs 15 per km
- Rs 12 per km is used as a practical midpoint

Reference platforms:

- CabBazar
- MakeMyTrip

## 4. ETA Calculation

Code parameter:

```dart
const speed = 55.0;
```

Rationale:

- Highway speed assumptions typically range from 50-70 km/h
- Reduced to a conservative average to account for traffic, toll delays, and city entry/exit slowdowns

Suggested project statement:

"ETA uses a conservative average speed of 55 km/h to better reflect real traffic conditions."

## 5. Safety Inputs and Method

Safety factors used per route segment:

- Crime
- Lighting
- Police presence
- Crowd density

Important transparency note:

- Crime scores are modeled (not live API-driven)
- Values are informed by NCRB-style trend interpretation, city profile, and corridor type

## 6. Safety Formula

Current weighted score:

```text
(10 - crime) * 0.4 + lighting * 0.2 + police * 0.2 + crowd * 0.2
```

Interpretation:

- Crime has the highest influence (40%)
- Environmental and social factors contribute the remaining 60%

## 7. Punjab City Crime Bias (Ranked with Sources)

| Rank | City       | Crime Level  | Score (0-10) | Source |
| ---- | ---------- | ------------ | ------------ | ------ |
| 1    | Ludhiana   | High         | 5.0          | The Times of India - [http://timesofindia.indiatimes.com/articleshow/124428454.cms](http://timesofindia.indiatimes.com/articleshow/124428454.cms) |
| 2    | Chandigarh | Moderate     | 3.5          | The Tribune - [https://www.tribuneindia.com/news/chandigarh/the-ugly-side-of-city-beautiful-chandigarhs-crime-rate-surpasses-national-average/](https://www.tribuneindia.com/news/chandigarh/the-ugly-side-of-city-beautiful-chandigarhs-crime-rate-surpasses-national-average/) |
| 3    | Jalandhar  | Moderate     | 3.0-4.0      | The Times of India - [https://timesofindia.indiatimes.com/city/ludhiana/ncrb-report-ludhianas-illegal-arms-haul-hits-10-year-high-/articleshow/124512003.cms](https://timesofindia.indiatimes.com/city/ludhiana/ncrb-report-ludhianas-illegal-arms-haul-hits-10-year-high-/articleshow/124512003.cms) |
| 4    | Amritsar   | Low-Moderate | 2.0-3.0      | The Times of India (same NCRB-based comparison report as above) |
| 5    | Patiala    | Moderate     | 3.0-3.5      | NCRB trend-based (no direct city-specific headline used) |
| 6    | Kharar     | Moderate     | 3.0-3.5      | NCRB trend-based (semi-urban growth pattern) |
| 7    | Mohali     | Low-Moderate | 2.5-3.0      | NCRB trend-based (planned/suburban pattern) |
| 8    | Bathinda   | Low-Moderate | 2.5-3.0      | NCRB trend-based (lower crime density compared with major urban hubs) |
| 9    | Pathankot  | Low          | 2.0-2.5      | NCRB trend-based (defense-sensitive zone profile) |

## 8. Segment Crime Values Currently Used in Code

The route engine uses segment-level values (double precision), based on the city bias table above.

| Segment                  | Crime Value |
| ------------------------ | ----------- |
| Chandigarh -> Mohali     | 3.1         |
| Mohali -> Kharar         | 3.0         |
| Kharar -> Ludhiana       | 4.1         |
| Chandigarh -> Patiala    | 3.4         |
| Patiala -> Ludhiana      | 4.1         |
| Ludhiana -> Jalandhar    | 4.3         |
| Jalandhar -> Amritsar    | 3.0         |
| Ludhiana -> Bathinda     | 3.9         |
| Amritsar -> Pathankot    | 2.4         |

## 9. Limitations and Next Step

Current limitation:

- Safety and crime values are modeled from static assumptions, not fetched live

Recommended future upgrade:

- Integrate district/city-level crime feeds or verified periodic datasets and auto-refresh scoring at fixed intervals

## 🧭 Safety Zone Classification (Punjab Routes)

### 🌆 High Safety Zones

#### Chandigarh ↔ Mohali

✔ Planned urban infrastructure
✔ Excellent street lighting
✔ Strong police presence
✔ High crowd activity

#### Jalandhar ↔ Amritsar

✔ Well-developed highway corridor
✔ Good lighting coverage
✔ Active intercity movement
✔ Frequent police patrolling

---

### ⚠️ Medium Risk Zones

#### Mohali ↔ Kharar

✔ Semi-urban transition zone
✔ Moderate lighting
✔ Medium crowd density
✔ Limited monitoring in some areas

#### Chandigarh ↔ Patiala

✔ State highway connectivity
✔ Good but inconsistent lighting
✔ Moderate police presence
✔ Average traffic flow

#### Patiala ↔ Ludhiana

✔ Industrial and highway mix
✔ Moderate lighting conditions
✔ Medium crowd activity
✔ Less consistent policing

#### Ludhiana ↔ Jalandhar

✔ Busy highway route
✔ Good lighting in patches
✔ High traffic movement
✔ Moderate safety risk due to congestion

#### Amritsar ↔ Pathankot

✔ Intercity highway
✔ Good lighting in populated areas
✔ Moderate police presence
✔ Lower crowd density at night

---

### 🚨 High Risk Zones

#### Kharar ↔ Ludhiana

✔ Long highway stretch
✔ Reduced lighting in rural sections
✔ Limited police patrol frequency
✔ Moderate-to-low crowd density

#### Ludhiana ↔ Bathinda

✔ Very long rural highway
✔ Poor lighting infrastructure
✔ Sparse population and traffic
✔ Low police visibility

---

## 📊 Why This Classification is Realistic

This safety classification is based on **real-world urban and highway characteristics** of Punjab:

### 🏙️ Urban Planning Impact

Cities like Chandigarh and Mohali are **planned cities** with:

* Wide roads
* Consistent street lighting
* Organized traffic systems

➡️ This results in **higher safety scores**

---

### 🚧 Highway Conditions

Routes like Ludhiana ↔ Bathinda and Kharar ↔ Ludhiana include:

* Long rural stretches
* Limited infrastructure development
* Inconsistent lighting

➡️ These factors increase **risk levels**

---

### 👮 Police Presence & Monitoring

Highly urbanized areas have:

* Regular police patrolling
* Surveillance systems
* Faster emergency response

➡️ Leading to **improved safety perception**

---

### 👥 Crowd Density Factor

* High crowd → safer due to visibility and activity
* Low crowd → higher risk, especially at night

➡️ This directly impacts **route safety scoring**

---

### 🌙 Night-Time Behavior

At night:

* Crowd density decreases
* Lighting becomes critical
* Remote highways become riskier

➡️ The model reflects **real-life travel risks**

---

## 🎯 Key Insight

This system does not rely on random values —
it simulates **real-world safety conditions using infrastructure, population behavior, and regional characteristics**.

---
