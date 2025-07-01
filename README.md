# 📊 Cost and Utilization Patterns in a Synthetic Medicare Population

## Overview  
This project analyzes 2008 synthetic Medicare claims data (SynPUF) from the Centers for Medicare & Medicaid Services (CMS) to explore trends in healthcare utilization and cost. The focus is on inpatient and outpatient services, with industry-standard KPIs used to reveal high-cost segments and population-level insights.

## Objectives  
- Quantify cost and utilization with per-member metrics  
- Identify high-cost members and analyze cost concentration  
- Compare claim types (inpatient vs. outpatient)  
- Create a Tableau dashboard for exploratory analysis  

## Tools  
- **SQL** (PostgreSQL)  
- **Tableau Public**  
- **CMS DE-SynPUF 2008 Dataset**  

## Key Metrics  
- PMPM (Per Member Per Month)  
- Claims per 1,000 members  
- Top diagnosis codes by cost  
- % of total cost driven by top 5% of members  

## Key Findings  
- The top 5% of members drove a disproportionate share of total claims cost  
- Inpatient claims had higher per-claim cost but were less frequent  
- High-cost diagnoses were consistent with known chronic disease patterns in Medicare populations  

## Dashboard  
🔗 [View Tableau Public Dashboard](https://public.tableau.com/views/MedicareClaims_17509752302870/MedicareClaims?:language=en-US&:sid=&:redirect=auth&:display_count=n&:origin=viz_share_link)

## Project Structure  
```
📁 sql/                -- All SQL queries used for extraction and transformation  
📁 data/               -- Cleaned datasets (if shared)  
📁 images/             -- Screenshots of key visualizations  
📄 README.md           -- Project summary (this file)  
```

## Outcome  
This project demonstrates core healthcare analytics skills: data modeling, SQL-based KPI design, cost utilization analysis, and dashboard storytelling. It was designed to reflect tasks relevant to analyst roles at organizations like Centene, UnitedHealth, or healthtech startups.
