#LINKEDIN PROFILE PHOTOS AND HIRING VISIBILITY BIAS SIMULATION
set.seed(42)

n <- 1500 #number of simulated profiles

# --- Basic candidate info ---
profile_id <- 1:n
years_experience <- sample(0:15, n, replace= TRUE)
has_profile_photo <- rbinom(n, 1, 0.75) # 75% have photos

photo_style <- sample(
  c("professional_headshot", "casual_selfie", "no_photo"),
  n,
  replace = TRUE,
  prob = c(0.6, 0.25, 0.15)
)

perceived_attractiveness_score <- pmin(
  pmax(rnorm(n, mean = 5.5, sd = 1.5),1),
  10
)

gender_presentation <- sample(
  c("feminine","masculine","androgynous"),
  n,
  replace = TRUE,
  prob = c(0.45, 0.45, 0.1)
)

# ---Extra controlled variables ---
education_level <- sample(
  c("HighSchool","NonTertiary","Bachelor","Master","PhD"),
  n,
  replace = TRUE,
  prob = c(0.18, 0.1, 0.45, 0.22, 0.05)
)

university_prestige <- sample(
  c("Tier1", "Tier2", "Tier3"),
  n,
  replace = TRUE,
  prob = c(0.2, 0.5, 0.3)
)

profile_completeness <- round(runif(n, 60, 100)) #60%-100%
industry <- sample(
  c("Tech", "Finance", "Marketing", "Other"),
  n,
  replace = TRUE,
  prob = c(0.3, 0.25, 0.25, 0.2)
)

connections_count <- sample(25:1000, n, replace = TRUE)
location_type <- sample(c("Metro", "Regional"), n, replace = TRUE, prob = c(0.7, 0.3) )

recruiter_profile_views <- rpois(n, lambda = 25)

# --- Bias logic for interview callback---
# Logistic model: experience + photo + attractiveness + education + prestige + profile compleness
bias_score_v2 <- -4.5 + # lower base rate
  0.015 * years_experience + # smaller exp effect
  0.15 * has_profile_photo + # moderate photo effect
  0.025 * perceived_attractiveness_score + # subtle attractiveness effect
  0.25 * (education_level == "Master") +
  0.35 * (education_level== "PhD") +
  0.20 * (university_prestige == "Tier1") +
  0.008 * profile_completeness +
  0.003 * connections_count

# add stochastic variation (real world randomness)
bias_score_v2 <- bias_score_v2 + rnorm(n, 0, 0.5)

prob_callback_v2 <- 1 / (1 + exp(-bias_score_v2))
interview_callback_v2 <- rbinom(n, 1, prob_callback_v2)

# --- Combine into dataframe ---
linkedin_data <- data.frame(
  profile_id,
  years_experience,
  has_profile_photo,
  photo_style,
  perceived_attractiveness_score,
  gender_presentation,
  education_level,
  university_prestige,
  profile_completeness,
  industry,
  connections_count,
  location_type,
  recruiter_profile_views,
  interview_callback
)

# --- Preview ---
head(linkedin_data)
summary(linkedin_data)

# Linear regression
lm_visibility <- lm(recruiter_profile_views ~ 
           has_profile_photo +
           years_experience +
           perceived_attractiveness_score +
           education_level +
           university_prestige +
           profile_completeness +
           connections_count, 
         data = linkedin_data)
summary(lm_visibility)

# Logistic regression
model <- glm(
  interview_callback_v2 ~ has_profile_photo + 
    years_experience + 
    perceived_attractiveness_score +
    gender_presentation + 
    education_level + 
    profile_completeness + 
    connections_count,
  family = binomial,
  data = linkedin_data
)
summary(model)

# LM predicted values
pred_views <- predict(lm_visibility)
range(pred_views)
mean(pred_views)

# GLM predicted probabilities
pred_prob <- predict(model, type = "response") # Calculate predicted callback probability
range(pred_prob)
mean(pred_prob)

# --- Visualisation ---
# Create a readable factor for profile completeness
linkedin_data$CompletenessGroup <- cut(
  linkedin_data$profile_completeness, 
  breaks = c(60, 70, 80, 90, 100),
  labels = c("60-70", "70-80", "80-90", "90-100"),
  include.lowest = TRUE
)

# Density plot
ggplot(linkedin_data, aes(x = recruiter_profile_views, 
                          fill = CompletenessGroup)) +
  geom_density(alpha = 0.6) +
  scale_fill_manual(values = c("#FFB6C1", "#FF69B4", 
                               "#FF1493", "#FF00FF")) +
  labs( title = "Profile Views by Completeness",
        x = "Recruiter Profile Views",
        y = "Density",
        fill = "Completeness") +
  theme_minimal()

# Jitter plot
ggplot(linkedin_data, aes(x = years_experience, y = pred_prob, 
                          colour = education_level)) +
  geom_jitter(position = position_jitter(width = 0.2, height = 0.01), 
              size = 3, alpha = 0.8) +
  scale_colour_manual(values = c(
    "HighSchool" = "#FF69B4",  # hotpink
    "NonTertiary" = "#FF1493", # deep pink
    "Bachelor" = "#FF00FF",    # magenta
    "Master" = "#FFD700",      # gold/yellow
    "PhD" = "#FF77FF"          # lighter neon pink
    )) +
  labs( title = "Callback Probability by Experience", 
        subtitle = "Predicted recruiter interest based on profile features",
        x = "Years of Experience", y = "Predicted Callback Probability", 
        colour = "Education Level") +
  theme_minimal() +
  theme( plot.title = element_text(face = "bold", hjust = 0.5), 
         legend.position = "right")

# Summary point
ggplot(linkedin_data, aes(x = factor(has_profile_photo), 
                          y = interview_callback_v2)) +
  stat_summary(
    fun = mean,
    geom = "point",
    size = 6,
    colour = "#FF00FF") +
  stat_summary(
    fun.data = mean_cl_normal,
    geom = "errorbar",
    width = 0.2,
    colour = "#FFD700") +
  labs( title = "Interview Callback Rate by Profile Photo",
    x = "Profile Photo",
    y = "Callback Rate") +
  scale_x_discrete(labels = c("No Photo", "Has Photo")) +
  theme_minimal()
