SEMI_UNIFORM    = c(97.3, 86.9, 86.3, 85.7, 86.7, 73.1, 90.6, 98.8, 98.7)
INFORMATIVENESS = c(97.3, 94.6, 46.3, 40.4, 40.1, 44.7, 38.4, 38.8, 92.7, 91.6, 91.5)
GREEDY          = c(52.9, 38.7, 47.9)
EPS_GREEDY      = c(96.8, 94.1, 98.9, 80.7)

round(mean(SEMI_UNIFORM),1);    round(median(SEMI_UNIFORM),1)
round(mean(INFORMATIVENESS),1); round(median(INFORMATIVENESS),1)
round(mean(GREEDY),1);          round(median(GREEDY),1)
round(mean(EPS_GREEDY),1);      round(median(EPS_GREEDY),1)
