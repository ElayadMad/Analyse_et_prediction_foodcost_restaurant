library(dplyr)
library(fixest)
library(ggplot2)
library(readxl)
library(lubridate)
library(slider)
cout_restaurant <- read_excel("C:/Users/FMadi/OneDrive/Bureau/projet google/test R cout restaurant.xlsx", 
                              col_types = c("text", "date", "text", 
                                                   "text", "numeric", "text", "numeric"))
Ventes_ajustes <- read_excel("C:/Users/FMadi/OneDrive/Bureau/projet google/Food cost analyse.xlsx", 
                                 sheet = "Ventes ajustées", range = "A1:I52834")



#Repertorier les ventes et les couts par jour
Ventes_quotidiennes <- Ventes_ajustes %>% 
  group_by(Date) %>% 
  summarise(Ventes_jours= sum(Ventes))

Couts_qutidients <- cout_restaurant %>% 
  group_by(Date) %>% 
  summarise(Couts_jours = sum(Couts))

df_analyse <- Ventes_quotidiennes %>% 
  inner_join(Couts_qutidients,by="Date") #inner_join pour retirer les lignes ou il n'y as pas de correspondance
  


#Nuage de point pour visualiser
ggplot(df_analyse, aes(x=Ventes_jours,y=Couts_jours))+
  geom_point(alpha = 0.6, color = "steelblue") +
  geom_smooth(method = "lm", color = "darkred",) +
  labs(
    title = "Analyse de la Corrélation Ventes et Coûts",
    x = "Ventes du jour ($)",
    y = "Coût des ingredient ($)"
  ) +
  theme_minimal()

ggplot(df_analyse, aes(x = Ventes_jours, y = Couts_jours)) +
  geom_point(alpha = 0.5, color="steelblue") +
  geom_smooth(method = "lm", fullrange = TRUE, color="darkred") + 
  expand_limits(x = 0, y = 0) +               
  theme_minimal()


#Analyser les tendance de consommation
consommation_tendance <- Ventes_ajustes %>%
  group_by(Date) %>%
  count(`Produit standardisé`) %>% 
  rename(produits_vendu = n)

consommation_jour <- consommation_tendance %>% 
  group_by(Date) %>% 
  summarise(consommation_du_jour=sum(produits_vendu))

consommation_tendance <- consommation_tendance %>%
  left_join(consommation_jour, by="Date") %>% 
  mutate(Ratio=produits_vendu/consommation_du_jour)


#Grouper le nombre de produit vendu au 2 semaine pour étudier la tendance
df_2semaines <- consommation_tendance %>%
  group_by(Produit = `Produit standardisé`, 
           Periode = floor_date(Date, unit = "14 days")) %>%
  summarise(
    ventes_totales = sum(produits_vendu),
    conso_totale = sum(consommation_du_jour),
    Ratio=ventes_totales/conso_totale,
    .groups = "drop")

liste_produits <- split(df_2semaines, df_2semaines$Produit)
tab_margarita <- liste_produits$Margarita

ggplot(tab_margarita, aes(x=Periode, y=Ratio))+
  geom_point(color="darkred")+
  geom_smooth(method = "lm",color="steelblue")+
  labs(title = "Évolution du Ratio pour la Margarita",
       x = "Date",
       y = "Ratio de consommation") +
  theme_minimal()

#Expliquer les ventes des produit par la consommation total au 2 semaines
regconso_margarita <- lm(ventes_totales~conso_totale, data=liste_produits$Margarita)
regconso_burger <- lm(ventes_totales~conso_totale, data=liste_produits$Burger)
regconso_kebab <- lm(ventes_totales~conso_totale, data=liste_produits$Kebab)
regconso_7up <- lm(ventes_totales~conso_totale, data=liste_produits$`7up`)
regconso_coca <- lm(ventes_totales~conso_totale, data=liste_produits$Coca)

summary(regconso_burger)
summary(regconso_7up)
summary(regconso_margarita)
summary(regconso_kebab)
summary(regconso_coca)


#Analyse du ratio Couts/Ventes
df_hebdo <- df_analyse %>% 
  mutate(Semaine = floor_date(Date, unit = "week", week_start = 1)) %>%
  group_by(Semaine) %>% 
  summarise(
    Ventes_Hebdo = sum(Ventes_jours),
    Couts_Hebdo = sum(Couts_jours),
    Ratio_Hebdo = Couts_Hebdo / Ventes_Hebdo)

#Regression des couts de la semaine t sur les vente de la semaine t+2
df_preparation <- df_hebdo %>% 
  mutate(ventes_suivante=lead(Ventes_Hebdo,n=2))

ccf(df_hebdo$Couts_Hebdo,df_hebdo$Ventes_Hebdo)
modele_hebdo <- lm(Couts_Hebdo ~ ventes_suivante, data=df_preparation)
summary(modele_hebdo)

ggplot(df_preparation,aes(x=ventes_suivante, y=Couts_Hebdo))+
  geom_point(color="steelblue")+
  geom_smooth(method="lm",color="darkgreen",size=1.2)+
  labs(title = "Évolution du Ratio foodcost",
       x = "Semaines",
       y = "foodcost") +
  theme_minimal()

#Determiner la consommation futrur

consommation_saison <- consommation_jour %>%
  mutate(mois = month(Date),
         saison = case_when(
           mois %in% c(12, 1, 2) ~ "Hiver",
           mois %in% c(3, 4, 5) ~ "Printemps",
           mois %in% c(6, 7, 8) ~ "Été",
           mois %in% c(9, 10, 11) ~ "Automne"
         ),
         saison = factor(saison, levels = c("Hiver", "Printemps", "Été", "Automne")),
         X1_consommation_passe= slide_dbl(consommation_du_jour,mean,.before=13,.complete = TRUE),
         X2_weekend = ifelse(wday(consommation_jour$Date) %in% c(6, 7), 1, 0),
         Y_consommation_future=slide_dbl(lead(consommation_du_jour,1),sum,.before = 0,.after = 13,.complete = TRUE)
  ) %>%
  arrange(saison, Date)
options(scipen = 999)
reg_conso_futur <- lm(Y_consommation_future~X1_consommation_passe+saison,data = consommation_saison)
summary(reg_conso_futur)

conso_2semaine_prediction <- predict(reg_conso_futur,newdata = data.frame(X1_consommation_passe=135.0714,saison="Printemps"))
conso_2semaine_prediction


#la prediction de la vente des produit en fonction de la consommation totale sur 2 semaines
predict(regconso_margarita, newdata = data.frame(conso_totale=conso_2semaine_prediction),
        interval = "confidence")
predict(regconso_burger, newdata = data.frame(conso_totale=conso_2semaine_prediction),
        interval = "confidence")
predict(regconso_kebab, newdata = data.frame(conso_totale=conso_2semaine_prediction),
        interval = "confidence")
predict(regconso_coca, newdata = data.frame(conso_totale=conso_2semaine_prediction),
        interval = "confidence")
predict(regconso_7up, newdata = data.frame(conso_totale=conso_2semaine_prediction),
        interval = "confidence")

df_predictions_simple <- data.frame(
  conso_totale = conso_2semaine_prediction,
  margarita = predict(regconso_margarita, newdata = data.frame(conso_totale = conso_2semaine_prediction)),
  burger = predict(regconso_burger, newdata = data.frame(conso_totale = conso_2semaine_prediction)),
  kebab = predict(regconso_kebab, newdata = data.frame(conso_totale = conso_2semaine_prediction)),
  coca = predict(regconso_coca, newdata = data.frame(conso_totale = conso_2semaine_prediction)),
  '7up' = predict(regconso_7up, newdata = data.frame(conso_totale = conso_2semaine_prediction))
)