# Delivery - On The Go: Hub Staffing Analysis

A data analyst case study for a courier company with six delivery hubs in Metro City. Hub managers requested 8 additional delivery agents after order volume rose sharply in the second week of the period. This project tests whether hiring is justified in every hub and produces a costed recommendation within a BDT 70,000 budget.

**Analysis period:** 13 to 26 October 2026 (14 days)
**Forecast horizon:** 27 October to 23 November 2026 (4 weeks)

## Recommendation

Do not approve the request for 8 hires. Approve a targeted plan instead:

| Action | Hub | Cost (BDT) |
|---|---|---|
| Hire 2 Fixed agents | H04 Hillcrest | 43,800 |
| Transfer 2 Fixed agents | H02 Lakeview to H01 Greenfield | 4,000 |
| Launch a hold reduction programme (target -50% agent-side holds) | H03 Riverside | 15,000 |
| Optional transfer of 1 Fixed agent | H05 Brookside to H06 Westwood | 2,000 |
| **Total** | | **64,800** |

The plan costs BDT 110,400 less in Month 1 than hiring 8 Fixed agents (BDT 175,200) and leaves BDT 5,200 of the budget unspent.

## Key Findings

- **Three hubs exceeded the 85% utilisation target in Week 2:** H04 (95.9%), H03 (90.8%) and H01 (88.6%). H02 (56.2%) and H05 (71.5%) had spare capacity.
- **H03 holds are mostly avoidable.** H03 produced 874 of the 1,679 Week 2 holds (52.1%), and 64.4% of them were agent-side, led by Late Dispatch.
- **H03 has the highest cost per delivered order** in Week 2 (BDT 45.67 against BDT 26.56 to 37.33 elsewhere), driven by hold and return penalties.
- **Three Brookside agents** with more than 30 days of tenure have a return ratio above 15%.
- **Staffing gap for the forecast** (required minus current agents, stable across the four weeks):

| Hub | H01 | H02 | H03 | H04 | H05 | H06 |
|---|---|---|---|---|---|---|
| Gap | +2 | -3 | +1 | +2 | -1 | 0 |

A negative value is a surplus. Surpluses in H02 and H05 are used for redeployment within the same cluster before any new hire is made.

## Repository Structure

> Adjust this section to match the folders in your repository.

```
.
├── README.md
├── data/                      # Source tables (CSV), if permitted for publication
├── sql/                       # Task 1 queries, run in numeric order
├── dashboard/                 # Dashboard screenshots and source file
├── presentation/              # Executive deck (PPTX/PDF)
└── report/                    # Final assessment report (PDF/DOCX)
```

## Deliverables

| Deliverable | Link |
|---|---|
| Final report (PDF) | [add link] |
| Executive presentation (8 slides) | [add link] |
| Interactive dashboard (public) | [add link] |
| Dashboard source file | [add link] |

## Tools

- PostgreSQL for data modelling and analysis
- [Dashboard tool] for the operations dashboard
- [Presentation tool] for the executive deck

## Method

The work follows four tasks:

1. **SQL assessment (Q1 to Q7):** daily agent productivity, hub utilisation, hold reasons, outcomes of held orders, high-return agents, cost per delivered order, and agents required for the forecast.
2. **Strategic analysis (Q8 to Q10):** hub-by-hub hiring decision with costs, allocation of the BDT 70,000 budget, and risks with early-warning triggers for the first two weeks.
3. **Dashboard:** hub performance monitoring to show which hub needs action.
4. **Presentation:** an 8-slide recommendation for the Head of Operations.

### Key definitions

| Term | Definition |
|---|---|
| Attempt | One Assigned event and its outcome (Delivered, Hold or Returned) |
| Working day | A day on which an agent has at least one attempt |
| Utilisation | Attempts divided by (available agent-days x 40) |
| Return ratio | Returned attempts divided by total attempts |
| Attempts per order | Total attempts divided by distinct orders, by hub |
| Required agents | CEILING(forecast orders x attempts per order / (7 x 40 x 0.85)) |
| Staffing gap | Required agents minus current active agents |
| Agent-side hold reasons | Late Dispatch, Not Attempted, Agent Time Shortage |

### Cost rules used

- A Fixed agent costs BDT 650 per working day (monthly salary divided by 26).
- A Variable agent costs the daily allowance plus the allowance per delivery for each working day. Fixed agents are cheaper above 25 deliveries per day.
- Hold and return penalties come from the cost sheet and are included in the total cost per delivered order.

## How to Reproduce

1. Create a PostgreSQL database and import the CSV files: `hubs`, `agents`, `orders`, `order_logs`, `volume_forecast`, and the three cost sheet tabs (`agent_salary`, `costs`, `rules`).
2. Run the data validation checks in `sql/` (row counts, duplicate keys, orphan records, event logic).
3. Create the base `attempts` view (one row per Assigned event with its outcome).
4. Run the Q1 to Q7 queries in order. Q1 creates the `daily_agent` table that later queries reuse.
5. Use the results to build the hub analysis table behind Task 2 and the dashboard.

## Assumptions and Limitations

- The forecast is in orders, while capacity is measured in attempts. Orders are converted with each hub's historical attempts-per-order ratio.
- Inactive agents are counted as available until 19 October 2026, when they left.
- Every active agent is counted as available every day for forecast staffing.
- The hold reduction target of 50% and the 60% first-week productivity of new hires are planning assumptions, not observed values.
- Savings at H01 and H04 are treated as protected capacity, not as guaranteed financial savings.
- The analysis covers 14 days of data, so weekly patterns beyond this window are not observed.

## Author

Shahriar Parvez Shaon
[LinkedIn / Portfolio link]
