# Data Migration Plan
This document outlines the plan to migrate data from the existing Rails-based DMP Tool system to the
new Node.js-based DMP Tool system.

### TAGS (15 rows)
---
We will copy over all of the old system's existing themes as tags in the new system.
```sql
SELECT id, title, description, created_at, updated_at FROM themes ORDER BY id;
```

These records can be mapped to the `tags` table as:
```
- title ----> themes.name
- description ----> themes.description
- created_at ----> tags.created
- updated_at ----> tags.modified
- createdById ----> (we can set this to a super admin user id)
- modifiedById ----> (we can set this to a super admin user id)
```

### RESEARCH DOMAINS (48 rows)
---
Research domains are already in the new system. Here is a mapping between the ids in the old system (left side) and the ids in the new system (right side):
```
1 -> 1	natural-sciences
9 -> 2	engineering-and-technology
21 -> 3	medical-and-health-sciences
27 -> 4	agricultural-sciences
33 -> 5	social-sciences
43 -> 6	humanities
2 -> 7	mathematics
3 -> 8	computer-and-information-sciences
4 -> 9	physical-sciences
5 -> 10	chemical-sciences
6 -> 11	earth-and-environmental-sciences
7 -> 12	biological-sciences
8 -> 13	other-natural-sciences
10 -> 14	civil-engineering
11 -> 15	electrical-electronic-information-engineering
12 -> 16	mechanical-engineering
13 -> 17	chemical-engineering
14 -> 18	materials-engineering
15 -> 19	medical-engineering
16 -> 20	environmental-engineering
17 -> 21	environmental-biotechnology
18 -> 22	industrial-biotechnology
19 -> 23	nano-technology
20 -> 24	other-engineering-and-technologies
22 -> 25	basic-medicine
23 -> 26	clinical-medicine
24 -> 27	health-sciences
25 -> 28	health-biotechnology
26 -> 29	other-medical-sciences
28 -> 30	agriculture-forestry-fisheries
29 -> 31	animal-and-dairy-science
30 -> 32	veterinary-science
31 - > 33	agricultural-biotechnology
32 -> 34	other-agricultural-sciences
34 -> 35	psychology
35 -> 36	economics-and-business
36 -> 37	educational-sciences
37 -> 38	sociology
38 -> 39	law
39 -> 40	political-science
40 -> 41	geography	
41 -> 42	media-and-communications
42 -> 43	other-social-sciences
44 -> 44	history-and-archaeology
45 -> 45	languages-and-literature
46 -> 46	philosophy-ethics-religion
47 -> 47	art
48 -> 48	other-humanities
```

