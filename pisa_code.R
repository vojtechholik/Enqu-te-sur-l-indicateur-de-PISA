setwd("/home/vojtech/SciPo/Year 4/La vie sociale des données")

# Loading all required packages
library(dplyr)
library(tidyverse)
library(ggplot2)
library(modelsummary)
library(fixest)

#Introduction of the PISA datasets per subject (available at https://data.oecd.org/education.htm#profile-International%20student%20assessment%20(PISA))
pisa_r <- read.csv("pisa_read.csv")
pisa_r <- pisa_r %>%
  rename("read" = "Value",
         "year" = "TIME",
         "country" = "LOCATION",
         "gender" = "SUBJECT") %>%
  select(!c(INDICATOR, Flag.Codes, FREQUENCY, MEASURE))

pisa_m <- read.csv("pisa_math.csv")
pisa_m <- pisa_m %>%
  rename("maths" = "Value",
         "year" = "TIME",
         "country" = "LOCATION",
         "gender" = "SUBJECT") %>%
  select(!c(INDICATOR, Flag.Codes, FREQUENCY, MEASURE))

pisa_s <- read.csv("pisa_science.csv")
pisa_s <- pisa_s %>%
  rename("science" = "Value",
         "year" = "TIME",
         "country" = "LOCATION",
         "gender" = "SUBJECT") %>%
  select(!c(INDICATOR, Flag.Codes, FREQUENCY, MEASURE))

# Merging the datasets to one
pisa <- left_join(pisa_r, pisa_m)
pisa <- left_join(pisa, pisa_s)

# Plotting average reading scores by gender
(gender_read <- ggplot(pisa %>% filter(gender %in% c("BOY", "GIRL")) %>%
         group_by(year, gender) %>%
         summarise(read = mean(read))) + 
  aes(x = year,
      y = read,
      color = gender) + 
  geom_line() + 
  geom_point() + 
  labs(title = "Average reading scores by gender",
       y = "PISA reading score",
       x = "Year",
       color = "Gender"))
ggsave("gender_read.jpg", gender_read)

# Plotting average maths scores by gender
(gender_maths <- ggplot(pisa %>% filter(gender %in% c("BOY", "GIRL")) %>%
         group_by(year, gender) %>%
         summarise(maths = mean(maths))) + 
  aes(x = year,
      y = maths,
      color = gender) + 
  geom_line() + 
  geom_point()  + 
  labs(title = "Average maths scores by gender",
       y = "PISA maths score",
       x = "Year",
       color = "Gender"))

ggsave("gender_maths.jpg", gender_maths)

# Plotting average science scores by gender
(gender_science <- ggplot(pisa %>% filter(gender %in% c("BOY", "GIRL")) %>%
         group_by(year, gender) %>%
         summarise(science = mean(science))) + 
  aes(x = year,
      y = science,
      color = gender) + 
  geom_line() + 
  geom_point()  + 
  labs(title = "Average science scores by gender",
       y = "PISA science score",
       x = "Year",
       color = "Gender"))

ggsave("gender_sciences.jpg", gender_science)

# Creation of Pisa short: mean PISA score per year
# (equal to read score if maths and science scores are missing, equal to mean of read and maths if science is missing)
# (reading scores started being collected the earliest, that's why they're available when the others aren't)
pisa_short <- pisa %>%
  filter(gender == "TOT") %>%
  mutate(score = ifelse(is.na(science)&is.na(maths), read, 
                        ifelse(is.na(science)&!is.na(maths),
                               (read + maths)/2,
                               (read + maths + science)/3)))

# Pivoting the dataset longer (→pisa_long) to get this kind of data per subject
pisa_long <- pivot_longer(pisa_short,
                          cols = c("read", "maths", "science"),
                          names_to = "subject",
                          values_to = "value")

# Reorder by the mean score
pisa_long$country = with(pisa_long, reorder(country, score, mean))

pisa_long <- pisa_long %>%
  group_by(country) %>%
  mutate(meanscore = mean(score))

# Plotting the distribution of PISA scores per country and per subject (excluding countries that only participated once)
(score_distribution <- ggplot(pisa_long %>% filter(!country %in% c("SGP", "MAC", "HKG", "TWN", "LTU", "PER", "CRI"))) +
  geom_point(aes(x = country,
                 y = value,
                 color = subject)) +
  geom_point(aes(x = country,
                 y = meanscore),
             color = "black",
             size = 2) +
  labs(y = "PISA score",
       x = "Country",
       color = "Subject",
       title = "PISA score distribution (2000-2018)"))

ggsave("score_distribution.jpg", score_distribution)

# A graphic not used in the final analysis
ggplot(pisa_long %>% filter(country %in% c("FRA", "IDN", "FIN", "SVK"),
                       gender == "TOT")) +
  aes(x = year,
      y = value,
      color = country,
      shape = subject) + 
  geom_point(size = 3) +
  geom_line() + 
  labs(y = "PISA score",
       x = "Year",
       color = "Country",
       title = "PISA score evolution in Czech Republic, Finland and France (2000-2018)")

# Introduction of packages necessary to create maps
library(tmap)
library(sf)
library(rnaturalearth)

# Loading the world map dataset
world <- ne_countries(scale = "medium", returnclass = "sf")

world <- world %>%
  rename(country = adm0_a3)

# Joining the world dataset with the pisa_short one
pisa_map_world <- left_join(world, pisa_short)

tmap_mode("plot")

# Creation of a map plotting the mean PISA score per country in Europe in 2000
# The following maps were not used in the end, we kept only the gif in the end

(pisa_map_2000 <- tm_shape(pisa_map_world %>%
           filter(continent == "Europe",
                  year == 2000),
         bbox=tmaptools::bb(ylim = c(30, 80), xlim = c(-30, 79), relative = F)) +
  tm_borders(col="white", lwd = 0.3) +
  tm_fill(
    col = "score",
    title = "PISA average score in 2000",
    n = 4) +
  tm_layout(
    legend.title.size=1,
    legend.text.size = 0.6,
    legend.position = c("right","bottom"),
    legend.bg.alpha = 1))

tmap_save(pisa_map_2000, "pisa_map_2000.png")

# Creation of a map plotting the mean PISA score per country in Europe in 2003
(pisa_map_2003 <- tm_shape(pisa_map_world %>%
                            filter(continent == "Europe",
                                   year == 2003),
                          bbox=tmaptools::bb(ylim = c(30, 80), xlim = c(-30, 79), relative = F)) +
  tm_borders(col="white", lwd = 0.3) +
  tm_fill(
    col = "score",
    title = "PISA average score in 2003",
    n = 4) +
  tm_layout(
    legend.title.size=1,
    legend.text.size = 0.6,
    legend.position = c("right","bottom"),
    legend.bg.alpha = 1))

tmap_save(pisa_map_2003, "pisa_map_2003.png")

# Creation of a map plotting the mean PISA score per country in Europe in 2006
(pisa_map_2006 <- tm_shape(pisa_map_world %>%
                            filter(continent == "Europe",
                                   year == 2006),
                          bbox=tmaptools::bb(ylim = c(30, 80), xlim = c(-30, 79), relative = F)) +
  tm_borders(col="white", lwd = 0.3) +
  tm_fill(
    col = "score",
    title = "PISA average score in 2006",
    breaks = ) +
  tm_layout(
    legend.title.size=1,
    legend.text.size = 0.6,
    legend.position = c("right","bottom"),
    legend.bg.alpha = 1))

tmap_save(pisa_map_2006, "pisa_map_2006.png")

# Creation of a map plotting the mean PISA score per country in Europe in 2009
pisa_map_2009 <- tm_shape(pisa_map_world %>%
                            filter(continent == "Europe",
                                   year == 2009),
                          bbox=tmaptools::bb(ylim = c(30, 80), xlim = c(-30, 79), relative = F)) +
  tm_borders(col="white", lwd = 0.3) +
  tm_fill(
    col = "score",
    title = "PISA average score in 2009") +
  tm_layout(
    legend.title.size=1,
    legend.text.size = 0.6,
    legend.position = c("right","bottom"),
    legend.bg.alpha = 1)

tmap_save(pisa_map_2009, "pisa_map_2009.png")

# Creation of a map plotting the mean PISA score per country in Europe in 2012
pisa_map_2012 <- tm_shape(pisa_map_world %>%
                            filter(continent == "Europe",
                                   year == 2012),
                          bbox=tmaptools::bb(ylim = c(30, 80), xlim = c(-30, 79), relative = F)) +
  tm_borders(col="white", lwd = 0.3) +
  tm_fill(
    col = "score",
    title = "PISA average score in 2012") +
  tm_layout(
    legend.title.size=1,
    legend.text.size = 0.6,
    legend.position = c("right","bottom"),
    legend.bg.alpha = 1)

tmap_save(pisa_map_2012, "pisa_map_2012.png")

# Creation of a map plotting the mean PISA score per country in Europe in 2015
pisa_map_2015 <- tm_shape(pisa_map_world %>%
                            filter(continent == "Europe",
                                   year == 2015),
                          bbox=tmaptools::bb(ylim = c(30, 80), xlim = c(-30, 79), relative = F)) +
  tm_borders(col="white", lwd = 0.3) +
  tm_fill(
    col = "score",
    title = "PISA average score in 2015") +
  tm_layout(
    legend.title.size=1,
    legend.text.size = 0.6,
    legend.position = c("right","bottom"),
    legend.bg.alpha = 1)

tmap_save(pisa_map_2015, "pisa_map_2015.png")

# Creation of a map plotting the mean PISA score per country in Europe in 2018
(pisa_map_2018 <- tm_shape(pisa_map_world %>%
                            filter(continent == "Europe",
                                   year == 2018),
                          bbox=tmaptools::bb(ylim = c(30, 80), xlim = c(-30, 79), relative = F)) +
  tm_borders(col="white", lwd = 0.3) +
  tm_fill(
    col = "score",
    title = "PISA average score in 2018",
    n = 7) +
  tm_layout(
    legend.title.size=1,
    legend.text.size = 0.6,
    legend.position = c("right","bottom"),
    legend.bg.alpha = 1))

tmap_save(pisa_map_2018, "pisa_map_2018.png")

#Creation of a gif with the maps

pisa_map_gif <- tm_shape(pisa_map_world %>%
                            filter(continent == "Europe"),
                          bbox=tmaptools::bb(ylim = c(30, 80), xlim = c(-30, 79), relative = F)) +
  tm_borders(col="white", lwd = 0.3) +
  tm_fill(
    col = "score",
    title = "PISA average score") +
  tm_layout(
    legend.outside = TRUE,
    legend.title.size = 5,
    legend.text.size = 3,
    legend.bg.alpha = 1,
    panel.label.size = 10) + 
  tm_facets(along = "year",
            showNA = F,
            free.coords = F) 

library(gifski)
tmap_animation(
  pisa_map_gif, filename = "pisa.gif",
  delay = 150, width = 2200, height = 1200
)

# Regressions

# Loading OECD data on education spending (available at https://data.oecd.org/eduresource/education-spending.htm)
spending <- read.csv("spending.csv")

# Polishing data, selecting secondary education spending, creating two different variables measuring spending on education
spending <- spending %>%
  rename("year" = "TIME",
         "country" = "LOCATION") %>%
  filter(SUBJECT == "SRY") %>%
  pivot_wider(names_from = MEASURE,
              values_from = Value) %>%
  select(!c(FREQUENCY, INDICATOR, SUBJECT, Flag.Codes))

# Merging with PISA scores (by country and years)
pisa_short_spending <- left_join(pisa_short, spending)

#Graphics with PC_GDP measure not kept in the final analysis
ggplot(pisa_short_spending, aes(x = PC_GDP,
                                y = score)) + 
  geom_point() + 
  geom_smooth(se = F,
              method = lm)

ggplot(pisa_short_spending, aes(x = log(PC_GDP),
                                y = score)) + 
  geom_point() + 
  geom_smooth(se = F,
              method = lm)

pisa_short_spending <- pisa_short_spending %>%
  mutate(above10k = ifelse(USD_STUDENT > 10000, USD_STUDENT, NA),
         below10k = ifelse(USD_STUDENT < 10000, USD_STUDENT, NA))

# Graphic for the relation between education spending and PISA scores
ggplot(pisa_short_spending) + 
  geom_point(aes(x = USD_STUDENT,
                 y = score)) + 
  geom_smooth(aes(x = below10k,
                  y = score),
              method = lm,
              se = F,
              color = "red") +
  geom_smooth(aes(x = above10k,
                  y = score),
              method = lm,
              se = F,
              color = "blue") +
  labs(title = "Relation between education spending and average PISA score",
       y = "PISA mean score",
       x = "US Dollars spent per student")

# Regression coefficients, confidence levels and R2

summary(lm(score ~ USD_STUDENT, pisa_short_spending))
# coefficient: 0.003438, confidence ***, Adjusted R2: 0.2493

summary(lm(score ~ USD_STUDENT, pisa_short_spending %>%
             filter(USD_STUDENT < 10000)))
# coefficient: 0.00841, confidence ***, Adjusted R2: 0.3647

summary(lm(score ~ USD_STUDENT, pisa_short_spending %>%
             filter(USD_STUDENT > 10000)))
# coefficient: -0.002071, confidence **, Adjusted R2: 0.1404


# Secondary school graduation data
sec_grad <- read.csv("sec_graduation.csv")

# Polishing
sec_grad <- sec_grad  %>%
  rename("year" = "TIME",
         "country" = "LOCATION",
         "sec_grad" = "Value") %>%
  filter(SUBJECT %in% c("UPPSRY_MEN", "UPPSRY_WOMEN")) %>%
  mutate(gender = ifelse(SUBJECT == "UPPSRY_MEN", "BOY", "GIRL")) %>%
  select(!c(FREQUENCY, MEASURE, INDICATOR, SUBJECT, Flag.Codes))

# Merging
pisa_grad <- pisa %>%
  filter(gender %in% c("GIRL", "BOY")) %>%
  group_by(gender) %>%
  mutate(score = ifelse(is.na(science)&is.na(maths), read, 
                        ifelse(is.na(science)&!is.na(maths),
                               (read + maths)/2,
                               (read + maths + science)/3)))

grad <- left_join(pisa_grad, sec_grad)

# Graphic with the relation between the PISA scores and the secondary school graduation rate
ggplot(grad, aes(score, sec_grad, color = gender)) + 
  geom_point() + 
  geom_smooth(se = F,
              method = lm) +
  labs(title = "Relation between average PISA score and rate of secondary school graduation",
       y = "Secondary school graduation rate",
       x = "PISA mean score",
       color = "Gender")

summary(lm(sec_grad ~ score, grad))

## Overall PISA gender scores
(gender <- ggplot(pisa_grad %>%
                    group_by(year, gender) %>%
                    summarise(genderscore = mean(score))) + 
    aes(x = year,
        y = genderscore,
        color = gender) + 
    geom_line() + 
    geom_point() + 
    labs(title = "Overall average scores by gender",
         y = "PISA mean score",
         x = "Year",
         color = "Gender"))
ggsave("gender.jpg", gender)
